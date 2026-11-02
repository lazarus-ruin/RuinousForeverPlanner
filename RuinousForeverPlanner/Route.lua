local _,P=...
local classes={[1]='WARRIOR',[2]='PALADIN',[3]='HUNTER',[4]='ROGUE',[5]='PRIEST',[7]='SHAMAN',[8]='MAGE',[9]='WARLOCK',[11]='DRUID'}
local function int(v,lo,hi) local n=tonumber(v);if n and n==math.floor(n) and n>=lo and n<=hi then return n end end
local function split(s,sep) local t={};for value in (s..sep):gmatch('(.-)'..sep) do t[#t+1]=value end;return t end
local function decode(s,max)
    if #s>max*3 or s:gsub('%%[%x][%x]',''):find('%',1,true) then error('Invalid escaped text') end
    s=s:gsub('%%(%x%x)',function(v)return string.char(tonumber(v,16))end)
    if #s>max or s:find('[%z\1-\8\11\12\14-\31]') then error('Invalid text length/control character') end
    return s
end
local function ids(s)
    local t={};if s=='' then return t end
    for _,v in ipairs(split(s,',')) do local n=int(v,1,10000000);if not n or #t>=50 then error('Invalid prerequisite list') end;t[#t+1]=n end
    return t
end
function P.ParseRoute(text)
    if type(text)~='string' or #text>1000000 then return nil,'Route exceeds the 1 MB import limit.' end
    local ok,result=pcall(function()
        local lines=split(text:gsub('\r',''):gsub('\n+$',''),'\n');local h=split(lines[1] or '','\t')
        if #h~=8 or h[1]~='RFP1' or not P.Data.profiles[h[3]] or not int(h[4],1,200) or (h[5]~='Alliance' and h[5]~='Horde') then error('Invalid route header; use the bundled Factoruide converter.') end
        local first,last=int(h[6],1,60),int(h[7],1,60)
        if not first or not last or last<first then error('Invalid route level range') end
        local r={name=decode(h[2],160),class=h[3],race=tonumber(h[4]),faction=h[5],from=first,to=last,source=decode(h[8],180),steps={},index=1,marks={},history={},auto=true}
        if #lines<2 or #lines>5001 then error('Routes must contain 1-5000 steps') end
        for i=2,#lines do
            local f=split(lines[i],'\t');if #f~=14 then error('Invalid fields at step '..(i-1)) end
            if not f[1]:match('^[a-z_]+$') or #f[1]>30 then error('Invalid step kind') end
            local s={kind=f[1],quest=int(f[2],0,10000000),objective=int(f[3],0,100),map=int(f[4],0,100000),x=tonumber(f[5]),y=tonumber(f[6]),min=int(f[7],0,60),level=int(f[8],1,60),background=f[9]=='1',text=decode(f[10],1200),pre=ids(f[11]),any=ids(f[12]),need=int(f[13],0,50),alt=ids(f[14])}
            if not s.quest or not s.objective or not s.map or not s.x or not s.y or s.x<0 or s.x>100 or s.y<0 or s.y>100 or not s.min or not s.level or not s.need or (f[9]~='0' and f[9]~='1') then error('Invalid numeric fields at step '..(i-1)) end
            if s.need>#s.any then error('Impossible OR prerequisite count') end
            if (s.kind=='accept' or s.kind=='objective' or s.kind=='turnin') and s.quest==0 then error('Quest step missing ID') end
            r.steps[#r.steps+1]=s
        end
        return r
    end)
    if not ok then return nil,tostring(result):sub(1,240) end
    return result
end
function P.RouteCompatibility(r)
    if not r or not P.char then return false,'No route loaded.' end
    if P.char.class~=P.actualClass or r.class~=P.actualClass then return false,'Route class does not match the actual character. Import that character\'s route.' end
    local ok,race
    if type(UnitRace)=='function' then local name,token;ok,name,token,race=pcall(UnitRace,'player') end
    if not ok or type(race)~='number' or (type(issecretvalue)=='function' and issecretvalue(race)) then return false,'Race identity unavailable; route paused until it can be verified.' end
    if race~=r.race or P.Safe(UnitFactionGroup,'player')~=r.faction then return false,'Route race/faction does not match this character.' end
    if (P.Safe(UnitLevel,'player') or 0)<r.from then return false,'Level into the route starting range first.' end
    return true
end
function P.ImportRoute(text)
    if not P.char then return false,'Log into a character first.' end
    local r,err=P.ParseRoute(text);if not r then return false,err end
    local matches,reason=P.RouteCompatibility(r);if not matches then return false,reason end
    P.char.route=r;return true,'Imported '..#r.steps..' ordered steps. Travel/training and unsupported conditions require manual confirmation.'
end
function P.RouteStepState(s)
    if P.Safe(InCombatLockdown) then return 'unknown','Progress checks deferred in combat.' end
    if s.quest>0 then
        local q=P.QuestObservation(s.quest)
        if q.error then return 'unknown','Quest flags unavailable.' end
        if q.completed==true then return 'done','Quest completion observed.' end
        if s.kind=='accept' and q.active==true then return 'done','Quest accepted.' end
        for _,id in ipairs(s.alt) do if P.QuestObservation(id).completed==true then return 'done','Recorded exclusive alternative completed.' end end
        if s.kind=='objective' and q.active==true then
            local list=P.Safe(C_QuestLog and C_QuestLog.GetQuestObjectives,s.quest)
            if type(list)=='table' and s.objective>0 then
                local item=list[s.objective]
                if type(item)=='table' then
                    local ok,done,a,b=pcall(function()
                        if type(issecretvalue)=='function' and (issecretvalue(item.finished) or issecretvalue(item.numFulfilled) or issecretvalue(item.numRequired)) then return end
                        return item.finished,item.numFulfilled,item.numRequired
                    end)
                    if ok and done==true then return 'done','Quest objective completed.' end
                    if ok and type(a)=='number' and type(b)=='number' then return 'pending',a..' / '..b end
                end
            end
        end
    end
    if (P.Safe(UnitLevel,'player') or 0)<s.min then return 'blocked','Requires level '..s.min end
    if s.kind=='accept' then
        if P.baselineProvider and not P.BaselineQuestMatches(s.quest) then return 'blocked','QuestieDB class/race restriction.' end
        local block=P.KnownQuestBlock(s.quest);if block then return 'blocked',block end
        for _,id in ipairs(s.pre) do if P.QuestObservation(id).completed~=true then return 'blocked','Complete prerequisite quest '..id end end
        local count=0;for _,id in ipairs(s.any) do if P.QuestObservation(id).completed==true then count=count+1 end end
        if #s.any>0 and count<math.max(1,s.need) then return 'blocked','Alternative prerequisites unresolved.' end
    end
    return 'pending',s.kind=='turnin' and 'Turn in manually; objective completion alone does not advance this step.' or 'Verify the action in game; unsupported conditions are not auto-completed.'
end
function P.AdvanceRoute()
    P.routeCatchup=false
    local r=P.char and P.char.route;if not r or not r.auto or not P.RouteCompatibility(r) then return end
    r.marks=r.marks or {};r.index=r.index or 1
    for _=1,40 do -- Bounded per refresh; never runs thousands of client reads in one frame.
        local s=r.steps[r.index];if not s then return end
        local state=P.RouteStepState(s)
        if r.marks[r.index] or state=='done' then r.index=r.index+1 else return end
    end
    P.routeCatchup=true
end
function P.RouteManualNext()
    local r=P.char and P.char.route;if not r or not r.steps[r.index] or not P.RouteCompatibility(r) then return false end
    r.history=r.history or {};r.history[#r.history+1]=r.index;if #r.history>100 then table.remove(r.history,1) end
    r.marks[r.index]=true;r.index=r.index+1;P.AdvanceRoute();return true
end
function P.RouteUndo()
    local r=P.char and P.char.route;if not r or not r.history or #r.history==0 then return false end
    r.index=table.remove(r.history);r.marks[r.index]=nil;r.auto=false;return true
end
function P.RouteWaypoint()
    local r=P.char and P.char.route;if not r or not P.RouteCompatibility(r) then return false,'No compatible route.' end
    local s=r.steps[r.index];if not s or s.map==0 then return false,'This step has no imported map coordinates.' end
    if P.Safe(InCombatLockdown) then return false,'Set the waypoint outside combat.' end
    if not C_Map or type(C_Map.SetUserWaypoint)~='function' or not P.Safe(C_Map.CanSetUserWaypointOnMap,s.map) then return false,'Native waypoints unavailable for this map/client.' end
    if not UiMapPoint or type(UiMapPoint.CreateFromCoordinates)~='function' then return false,'Client map-point helper unavailable. Coordinates: map '..s.map..', '..s.x..', '..s.y end
    local ok,point=pcall(UiMapPoint.CreateFromCoordinates,s.map,s.x/100,s.y/100)
    if not ok or not point then return false,'Map point creation failed.' end
    local set=P.Safe(C_Map.SetUserWaypoint,point)
    if set~=true then return false,'Client did not confirm the waypoint.' end
    if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint)=='function' then pcall(C_SuperTrack.SetSuperTrackedUserWaypoint,true) end
    return true,'Map waypoint requested. Follow terrain and transport instructions; no terrain-aware pathfinder is bundled.'
end
function P.RouteLines(brief)
    local r=P.char and P.char.route
    if not r then return {'No imported route. Use Import route with the bundled offline Factoruide converter. The adaptive next-action plan works without a route.'} end
    local matches,reason=P.RouteCompatibility(r);if not matches then return {'ROUTE PAUSED: '..reason} end
    P.AdvanceRoute()
    local lines={'ROUTE: '..r.name..' | '..math.min(r.index,#r.steps)..' / '..#r.steps..' | '..(r.auto and 'automatic quest progress' or 'paused / undo review')}
    for i=r.index,math.min(#r.steps,r.index+(brief and 1 or 4)) do
        local s=r.steps[i];local state,note=P.RouteStepState(s)
        lines[#lines+1]=(i==r.index and 'NOW: ' or 'NEXT: ')..s.text:gsub('|','||')
        if not brief then
            lines[#lines+1]=s.kind:upper()..' | '..state..' | '..note
            if s.map>0 then lines[#lines+1]='Map '..s.map..' | '..s.x..', '..s.y..' (destination only)' end
            if s.background then lines[#lines+1]='Upstream background objective: retained in order; manually pass it if you intend to continue in parallel.' end
        end
    end
    if r.index>#r.steps then lines[#lines+1]='Route finished. Review remaining goals or import the next route.' end
    if not brief then lines[#lines+1]='Import preserves step order and readable instructions, not upstream simulation or automation. Manual next acknowledges an action; Undo pauses automatic progress for inspection. Travel, training, buying, abandonment and dungeon entry are never automated.' end
    return lines
end
