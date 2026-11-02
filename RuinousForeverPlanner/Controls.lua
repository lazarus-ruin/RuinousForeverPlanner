local _, P = ...
local launcher, tracker, options, catalogue, trackerText
local function opts()
    local c=P.char
    if not c then return end
    if type(c.ui)~='table' then c.ui={} end
    for k,v in pairs({nextActionTracker=true,professions=true,minimap=true,efficiencyTracker=false,itemTooltips=true,optimization=true,tracker=true,leveling=true,gear=true,autoScan=true,questSuggestions=true,locked=false,compact=false}) do
        if type(c.ui[k])~='boolean' then c.ui[k]=v end
    end
    if type(P.profile.tracked)~='table' then P.profile.tracked={} end
    return c.ui
end
P.UIOptions=opts
local function safe(fn)
    return function(...) local ok,err=pcall(fn,...); if not ok then print('Ruinous Forever Planner controls: '..tostring(err)) end end
end
local function btn(parent,text,x,y,w,fn)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetSize(w,24); b:SetPoint('TOPLEFT',x,y); b:SetText(text); b:SetScript('OnClick',safe(fn)); return b
end
local function label(parent,text,x,y,w)
    local f=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    f:SetPoint('TOPLEFT',x,y); f:SetWidth(w); f:SetJustifyH('LEFT'); f:SetText(text); return f
end
local returnToPlanner=false
local function beginDialog(frame)
    if not P.activeDialog then returnToPlanner=P.IsPlannerShown() end
    local previous=P.activeDialog
    P.activeDialog=frame
    if previous then previous:Hide() end
    P.HidePlanner()
    if tracker then tracker:Hide() end
    frame:SetScript('OnHide',function(self)
        if P.activeDialog~=self then return end
        P.activeDialog=nil
        if returnToPlanner then returnToPlanner=false; P.Show() else P.UpdateControls() end
    end)
end
local function panel(name,w,h,noClose)
    local f=CreateFrame('Frame',name,UIParent)
    f:SetSize(w,h); f:SetPoint('CENTER'); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart',function(self) self:StartMoving() end)
    f:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
    f:SetFrameStrata(noClose and 'MEDIUM' or 'DIALOG'); f:SetFrameLevel(noClose and 5 or 200)
    local bg=f:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(.025,.035,.055,1)
    if not noClose then beginDialog(f) end
    if not noClose then btn(f,'Close',w-80,-8,70,function() f:Hide() end) end; return f
end
function P.ToggleTracked(id)
    if not opts() then return false end
    local valid=false
    for _,g in ipairs(P.TrackableGear()) do if g.id==id then valid=true end end
    if not valid then return false end
    local key=tostring(id)
    P.profile.tracked[key]=not P.profile.tracked[key]
    P.UpdateControls(); return true
end
function P.TrackerLines()
    if not opts() then return {} end
    local lines={}; local count=0
    local sorted={}
    for _,g in ipairs(P.TrackableGear()) do if P.profile.tracked[tostring(g.id)] then sorted[#sorted+1]={item=g,estimate=P.UpgradeEstimate(g)} end end
    table.sort(sorted,function(a,b)
        local x,y=a.estimate.percent,b.estimate.percent
        if x~=nil and y~=nil and x~=y then return x>y end
        if (x~=nil)~=(y~=nil) then return x~=nil end
        return a.item.id<b.item.id
    end)
    for _,entry in ipairs(sorted) do
        local g=entry.item
        count=count+1
        local state=P.CandidateOwned(g)
        lines[#lines+1]=(state=='Equipped' and '[Equipped] ' or state=='In bags (not equipped)' and '[Carried] ' or '[ ] ')..g.name
        lines[#lines+1]=entry.estimate.percent and P.UpgradeDisplay(entry.estimate) or 'Upgrade: compare item details'
        local questID=P.RewardQuestID(g)
        local replacement=P.ShortTermReplacement(g)
        if replacement and state~='Equipped' and state~='In bags (not equipped)' then lines[#lines+1]=replacement.text
        elseif state=='Equipped' or state=='In bags (not equipped)' then
            lines[#lines+1]=state=='Equipped' and 'Goal equipped.' or 'In bags - inspect before equipping.'
        elseif questID then
            local nextQuest,status=P.QuestNext(questID)
            if status=='completed' then lines[#lines+1]='Quest complete - check reward choice or storage.'
            elseif nextQuest then lines[#lines+1]=nextQuest.summary
                if status~='active' then lines[#lines+1]='Check availability at the quest giver.' end
            else lines[#lines+1]='Refresh quest progress in the planner.' end
        elseif not P.char.ui.compact then lines[#lines+1]=g.acquire end
        local gate=P.profile.gates[tostring(g.id)]
        if gate=='blocked' then lines[#lines+1]='Preparation blocked - review Targets.' end
        if not P.char.ui.compact then
            local level=P.Safe(UnitLevel,'player') or 0
            if level<g.min or level>g.max or (g.faction and g.faction~=P.Safe(UnitFactionGroup,'player')) then lines[#lines+1]='Outside supported level / faction - reference only.' end
            if not P.ProfileSupported() then lines[#lines+1]='No source list for this profile.' end
        end
        lines[#lines+1]=' '
    end
    for _,g in ipairs(P.profile.efficiencyGoals and P.EfficiencyCandidates() or {}) do if P.profile.efficiencyGoals and P.profile.efficiencyGoals[tostring(g.id)] then
        count=count+1;local state=P.CandidateOwned(g);lines[#lines+1]='[Leveling goal] '..g.name..' | '..state
        local e=P.LevelingEstimate(g);lines[#lines+1]=e.percent and P.UpgradeDisplay({percent=e.percent,text=string.format('%+.1f%% %s',e.percent,e.metric)}) or e.reason
        if g.questID then local q,status=P.QuestNext(g.questID);lines[#lines+1]=status=='completed' and 'Quest resolved; check reward choice / storage.' or q and ('Next: '..q.name) or 'Check quest prerequisites.' end
        lines[#lines+1]=' '
    end end
    local suggested=0
    if P.char.ui.questSuggestions then
        for _,r in ipairs(P.QuestRecommendations()) do
            if not P.profile.tracked[tostring(r.item.id)] and suggested<2 then
                if suggested==0 then lines[#lines+1]='Suggested quests' end
                suggested=suggested+1
                lines[#lines+1]=r.item.name
                if r.estimate.percent then lines[#lines+1]=P.UpgradeDisplay(r.estimate) end
                lines[#lines+1]=r.quest and r.quest.summary or 'Check live quest availability.'
                if r.quest and r.quest.chainIncomplete then lines[#lines+1]='Check live prerequisites.' end
                lines[#lines+1]=' '
            end
        end
    end
    for id,enabled in pairs(P.profile.trackedQuests or {}) do if enabled then
        local q=P.GetBaselineQuest(tonumber(id)) or P.QuestRecord(tonumber(id))
        if q and P.QuestObservation(tonumber(id)).completed~=true then
            count=count+1;lines[#lines+1]='[Quest] '..q.name;lines[#lines+1]=P.QuestStatus(tonumber(id));lines[#lines+1]=' '
        end
    end end
    if count==0 and suggested==0 then
        lines={'No active gear goals.','Choose Targets to track an item.'}
    end
    local enchantLines=P.EnchantGoalLines();if #enchantLines>0 then for i=#enchantLines,1,-1 do table.insert(lines,1,enchantLines[i]) end end
    if P.char.ui.efficiencyTracker and P.char.ui.leveling then
        local summary=P.EfficiencyLines(nil,true);for i=#summary,1,-1 do table.insert(lines,1,summary[i]) end
    end
    if P.char.ui.nextActionTracker and P.NextActionLines then local nextLines=P.NextActionLines(true);for i=#nextLines,1,-1 do table.insert(lines,1,nextLines[i]) end end
    if P.scanStale then lines[#lines+1]='Gear changed: use Scan gear to refresh.' end
    if P.char.ui.optimization then
        local report=P.OptimizationReport()
        table.insert(lines,1,P.OptimizationSummary(report))
        if report.easterEgg then table.insert(lines,2,report.easterEgg) end
    end
    return lines
end
local targetPage=1
function P.ShowTargets()
    if not opts() then return end
    local list=P.TrackableGear(); local pageCount=math.max(1,math.ceil(#list/6));targetPage=math.min(targetPage,pageCount)
    catalogue=panel(nil,760,515)
    label(catalogue,'Gear targets - '..P.char.class..' / '..P.char.spec..' / '..P.char.context,16,-16,630)
    label(catalogue,P.CoverageMessage(),16,-48,720)
    for row=1,6 do
        local g=list[(targetPage-1)*6+row]
        if g then
            local y=-85-(row-1)*55
            label(catalogue,g.name..' | '..g.mode..' | level '..g.min..'-'..g.max..'\n'..P.CandidateOwned(g)..' | '..P.UpgradeDisplay(P.UpgradeEstimate(g)),16,y,400)
            local b
            b=btn(catalogue,P.profile.tracked[tostring(g.id)] and 'Untrack' or 'Track',430,y,90,function()
                P.ToggleTracked(g.id);b:SetText(P.profile.tracked[tostring(g.id)] and 'Untrack' or 'Track')
            end)
            local gate
            gate=btn(catalogue,'Prep: '..(P.profile.gates[tostring(g.id)] or 'unknown'),530,y,180,function()
                local values={unknown='ready',ready='blocked',blocked='unknown'}
                P.Gate(g.id,values[P.profile.gates[tostring(g.id)] or 'unknown'] or 'unknown')
                gate:SetText('Prep: '..(P.profile.gates[tostring(g.id)] or 'unknown'));P.UpdateControls()
            end)
        end
    end
    label(catalogue,'Page '..targetPage..' / '..pageCount..' | '..#list..' source candidates. Prep is your manual assessment.',16,-430,710)
    btn(catalogue,'Previous',16,-470,120,function() targetPage=math.max(1,targetPage-1);P.ShowTargets() end)
    btn(catalogue,'Next',145,-470,120,function() targetPage=math.min(pageCount,targetPage+1);P.ShowTargets() end)
    catalogue:Show()
end
local questPage=1
local questSearch=''
local questAllLevels=false
function P.ShowQuestBrowser()
    if not opts() then return end
    local f=panel(nil,760,590)
    label(f,'Quest catalogue - '..P.char.class..' / '..P.char.spec,16,-16,620)
    label(f,P.baselineMessage or 'QuestieDB baseline not initialized.',16,-48,710)
    local search=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
    search:SetSize(350,26);search:SetPoint('TOPLEFT',20,-82);search:SetAutoFocus(false);search:SetMaxLetters(100);search:SetText(questSearch)
    search:SetScript('OnEnterPressed',safe(function(self) questSearch=self:GetText() or '';questPage=1;P.ShowQuestBrowser() end))
    btn(f,'Search',385,-82,85,function() questSearch=search:GetText() or '';questPage=1;P.ShowQuestBrowser() end)
    btn(f,questAllLevels and 'All levels' or 'Nearby levels',480,-82,150,function() questAllLevels=not questAllLevels;questPage=1;P.ShowQuestBrowser() end)
    local list=P.BrowseBaseline(questSearch,questAllLevels);local pageCount=math.max(1,math.ceil(#list/8));questPage=math.min(questPage,pageCount)
    for row=1,8 do local q=list[(questPage-1)*8+row]
        if q then
            local y=-125-(row-1)*45
            label(f,q.id..': '..q.name..' | level '..tostring(q.questLevel or q.minLevel or '?')..'\n'..P.QuestStatus(q.id),16,y,550)
            local b
            b=btn(f,P.profile.trackedQuests[tostring(q.id)] and 'Untrack' or 'Track',600,y,120,function()
                local key=tostring(q.id);P.profile.trackedQuests[key]=not P.profile.trackedQuests[key]
                b:SetText(P.profile.trackedQuests[key] and 'Untrack' or 'Track');P.UpdateControls()
            end)
        end
    end
    label(f,#list..' matching quests | page '..questPage..' / '..pageCount..'. Search name or ID. Baseline availability and rewards may differ in Forever.',16,-500,720)
    btn(f,'Previous',16,-545,110,function() questPage=math.max(1,questPage-1);P.ShowQuestBrowser() end)
    btn(f,'Next',136,-545,110,function() questPage=math.min(pageCount,questPage+1);P.ShowQuestBrowser() end)
    btn(f,'Refresh index',256,-545,140,P.ShowQuestBrowser)
    f:Show()
end
function P.ShowUpgradeWeights()
    if not opts() then return end
    local f=panel(nil,520,560)
    label(f,'Upgrade estimate weights - '..P.ProfileRole()..' heuristic',16,-16,420)
    label(f,'Percent = (target score / equipped score - 1) x 100. Not a simulated performance gain. Unweighted stats and special effects are omitted.',16,-48,480)
    local w=P.UpgradeWeights()
    for i,s in ipairs(P.UpgradeStats) do
        local key,name=s[1],s[2]
        local t=label(f,name..': '..w[key],16,-82-i*26,280)
        local function change(delta) w[key]=math.max(0,math.min(20,math.floor((w[key]+delta)*10+.5)/10)); t:SetText(name..': '..w[key]); P.UpdateControls() end
        btn(f,'-',320,-82-i*26,60,function() change(-.1) end)
        btn(f,'+',390,-82-i*26,60,function() change(.1) end)
    end
    label(f,'Weights save per class/spec/context profile. Source item values come from the client; these default weights are subjective starting values.',16,-500,480)
    f:Show()
end
function P.ShowOptions()
    if not opts() then return end
    options=panel(nil,440,560)
    label(options,'Ruinous Forever Planner settings (saved per character)',16,-18,340)
    local settings={{'minimap','Minimap button'},{'tracker','Objective tracker'},{'leveling','Leveling recommendations'},{'gear','Gear recommendations'},{'autoScan','Automatic gear scans'},{'locked','Lock tracker position'},{'compact','Compact tracker'},{'questSuggestions','Quest reward suggestions'},{'optimization','Gear optimization rating'},{'itemTooltips','Item tooltip ratings'},{'efficiencyTracker','Ten-level plan in tracker'},{'professions','Profession recommendations'},{'nextActionTracker','Next action in tracker'}}
    for i,s in ipairs(settings) do
        local b
        b=btn(options,s[2]..': '..(P.char.ui[s[1]] and 'ON' or 'OFF'),16,-46-i*28,400,function()
            P.char.ui[s[1]]=not P.char.ui[s[1]]
            b:SetText(s[2]..': '..(P.char.ui[s[1]] and 'ON' or 'OFF')); P.UpdateControls(); P.Render()
        end)
    end
    btn(options,'Reset tracker position',16,-445,240,function() P.char.ui.position=nil; if tracker then tracker:ClearAllPoints(); tracker:SetPoint('RIGHT',UIParent,'RIGHT',-40,40) end end)
    btn(options,'Clear leveling goals',264,-445,160,function() P.profile.efficiencyGoals={};P.profile.enchantGoals={};P.UpdateControls() end)
    btn(options,'Upgrade estimate weights',16,-480,400,P.ShowUpgradeWeights)
    btn(options,'Dungeon XP / grinding comparison',16,-515,400,P.ShowDungeonAdvisor)
    options:Show()
end
function P.UpdateControls()
    local o=opts(); if not o then return end
    if not launcher then
        launcher=CreateFrame('Button','RuinousForeverPlannerMinimapButton',Minimap or UIParent,'UIPanelButtonTemplate')
        launcher:SetNormalTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Up'); launcher:SetPushedTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Down'); launcher:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
        launcher:SetSize(32,32); launcher:SetPoint('TOPRIGHT',Minimap or UIParent,'TOPRIGHT',0,0); launcher:SetText('RFP')
        launcher:RegisterForClicks('LeftButtonUp','RightButtonUp')
        launcher:SetScript('OnClick',safe(function(_,which) if which=='RightButton' then P.ShowOptions() else P.Show() end end))
        launcher:SetScript('OnEnter',safe(function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_LEFT'); GameTooltip:SetText('Ruinous Forever Planner'); GameTooltip:AddLine('Left-click: planner. Right-click: settings.'); GameTooltip:Show() end end))
        launcher:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    end
    if o.minimap then launcher:Show() else launcher:Hide() end
    if not tracker then
        tracker=panel('RuinousForeverPlannerTracker',310,390,true); tracker:ClearAllPoints()
        local pos=o.position
        if type(pos)=='table' and type(pos.x)=='number' and type(pos.y)=='number' then tracker:SetPoint('CENTER',UIParent,'BOTTOMLEFT',pos.x,pos.y)
        else tracker:SetPoint('RIGHT',UIParent,'RIGHT',-40,40) end
        label(tracker,'Forever objectives',10,-12,210)
        btn(tracker,'Targets',10,-40,90,P.ShowTargets); btn(tracker,'Settings',105,-40,90,P.ShowOptions)
        tracker:SetScript('OnDragStart',function(self) if not P.char.ui.locked then self:StartMoving() end end)
        tracker:SetScript('OnDragStop',function(self)
            self:StopMovingOrSizing(); local x,y=self:GetCenter()
            if type(x)=='number' and type(y)=='number' then P.char.ui.position={x=x,y=y} end
        end)
        -- Closing is persistent; Settings can restore it.
        btn(tracker,'Hide',235,-8,65,function() P.char.ui.tracker=false; tracker:Hide() end)
        local sc=CreateFrame('ScrollFrame',nil,tracker,'UIPanelScrollFrameTemplate')
        sc:SetPoint('TOPLEFT',10,-72); sc:SetPoint('BOTTOMRIGHT',-30,12)
        local child=CreateFrame('Frame',nil,sc); child:SetSize(265,400); sc:SetScrollChild(child)
        trackerText=label(child,'',0,0,260)
        P.trackerChild=child
    end
    trackerText:SetText(table.concat(P.TrackerLines(),'\n'))
    local h=math.max(300,trackerText:GetStringHeight()+20); trackerText:SetHeight(h); P.trackerChild:SetHeight(h)
    if o.tracker and not P.activeDialog then tracker:Show() else tracker:Hide() end
    P.launcher=launcher; P.tracker=tracker
end
local oldRender=P.Render
function P.Render()
    oldRender()
    P.UpdateControls()
end
local oldRefresh=P.Refresh
function P.Refresh()
    oldRefresh()
    local ok,err=pcall(P.UpdateControls)
    if not ok then print('Ruinous Forever Planner controls unavailable: '..tostring(err)) end
end
SLASH_RUINOUSFOREVERPLANNERSETTINGS1='/rfpsettings'
SlashCmdList.RUINOUSFOREVERPLANNERSETTINGS=safe(P.ShowOptions)
SLASH_RUINOUSFOREVERPLANNERTARGETS1='/rfptargets'
SlashCmdList.RUINOUSFOREVERPLANNERTARGETS=safe(P.ShowTargets)
function P.ShowSellEstimates()
    if not opts() then return end
    local item=P.SelectedSellItem();if not item then print('Scan bags and select a carried item on Sell.');return end
    local e=P.EconomyDB();local prior=e.estimates[tostring(item.id)] or {}
    local f=panel(nil,580,340)
    label(f,'Net sell estimates - '..(item.name or tostring(item.id)),16,-18,520)
    label(f,'Per item, in COPPER (100 copper = 1 silver; 10,000 = 1 gold). Blank means unknown. Include auction cut, lost deposits and sale risk in net estimates.',16,-52,540)
    local fields={{'auction','Auction net per item',prior.auction},{'de','Disenchant materials net per item',prior.de},{'minimumGain','Extra-effort gain threshold',e.minimumGain}}
    local boxes={}
    for i,row in ipairs(fields) do
        local y=-106-(i-1)*38
        label(f,row[2],16,y,330)
        local edit=CreateFrame('EditBox',nil,f,'InputBoxTemplate');edit:SetSize(150,24);edit:SetPoint('TOPLEFT',380,y+4);edit:SetAutoFocus(false);edit:SetMaxLetters(12);edit:SetText(row[3]~=nil and tostring(row[3]) or '');boxes[row[1]]=edit
    end
    local message=label(f,'Values expire after 24 hours. Disenchant yield and eligibility require manual confirmation.',16,-225,540)
    btn(f,'Save estimates',16,-278,180,function()
        local values={}
        for key,box in pairs(boxes) do
            local raw=box:GetText()
            if raw~='' then local value=tonumber(raw);if not value or value<0 or value>=1e12 or value~=math.floor(value) then message:SetText('Enter whole nonnegative copper amounts, or leave a price blank.');return end;values[key]=value end
        end
        if P.SetSellEstimate(item.id,values.auction,values.de,values.minimumGain) then f:Hide();P.Refresh() end
    end)
    btn(f,'Forget vendor history',210,-278,180,function()e.vendors={};e.sell={};P.vendorMessage='Vendor history cleared.';message:SetText('Vendor history cleared. Manual estimates are retained.')end)
    f:Show()
end
function P.ShowRouteImport()
    if not opts() then return end
    local f=panel(nil,740,550)
    label(f,'Import an ordered route',16,-18,600)
    label(f,'Open ROUTE-CONVERTER.html from the addon folder. Select a Factoruide .fgguide file, copy its converted text, then paste below. Import replaces only this character\'s route; other goals remain.',16,-55,700)
    local sc=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');sc:SetPoint('TOPLEFT',20,-110);sc:SetSize(680,300)
    local edit=CreateFrame('EditBox',nil,sc);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject('ChatFontNormal');edit:SetSize(650,300);edit:SetMaxLetters(1000000);sc:SetScrollChild(edit)
    local message=label(f,'Only data is imported. No pasted Lua is executed. Single-character Forever routes only.',16,-430,700)
    btn(f,'Import / replace route',16,-490,210,function()
        local ok,text=P.ImportRoute(edit:GetText() or '');message:SetText(text)
        if ok then edit:SetText('');P.Refresh() end
    end)
    btn(f,'Clear current route',240,-490,180,function()P.char.route=nil;message:SetText('Current character route cleared.');P.Refresh()end)
    P.routeImportBox=edit;f:Show()
end
function P.ShowLaunchChecks()
    if not opts() then return end
    local f=panel(nil,700,440)
    label(f,'November 4 launch checks - offline build, live acceptance pending',16,-18,610)
    local r=P.char.route
    local lines={
      '1. Verify actual class/spec and race. Scan gear and check bag/equipment IDs.',
      '2. Import your single-character route. Confirm its first quest, destination and race/faction.',
      '3. Accept a quest, finish one objective, then turn it in. Confirm each step advances at the correct event.',
      '4. Set a map waypoint. If unsupported, read the imported map/coordinates; do not assume a safe path.',
      '5. Use Manual next for training/travel and Undo to review. Undo pauses auto progress; resume deliberately.',
      '6. Check a carried upgrade and a class quest, then reload normally to verify saved progress.',
      '7. Compare dungeon/grinding estimates using a measured XP sample. Review professions and vendor values.',
      '8. Use /rfp doctor and preserve any first error. No automatic restart/reload or gameplay action is performed.',
      ' ',
      'Current route: '..(r and r.name or 'none')..' | progress '..(r and r.index or 0),
      'Quest objective API: '..(C_QuestLog and type(C_QuestLog.GetQuestObjectives)=='function' and 'present' or 'missing'),
      'Map-point helper: '..(UiMapPoint and type(UiMapPoint.CreateFromCoordinates)=='function' and 'present' or 'missing; coordinates remain readable'),
      'Data coverage: external BiS references are level 30. Other levels use observed gear and labeled route references.',
      'Offline test results and release notes are included in the download. Presence checks do not certify client behavior.'}
    label(f,table.concat(lines,'\n\n'),16,-60,660);f:Show()
end
local dungeonIndex=1
function P.ShowDungeonAdvisor()
    if not opts() then return end
    local list=P.WindowDungeons()
    if #list==0 then print('No five-player dungeon references in your ten-level window.');return end
    dungeonIndex=math.min(math.max(1,dungeonIndex),#list)
    local d=list[dungeonIndex];local o=P.EfficiencyOptions();local input=o.runs[d.id] or {};if type(input)~='table' then input={} end
    local f=panel(nil,800,650)
    label(f,'Ten-level dungeon advisor - ONE run vs grinding',16,-16,660)
    btn(f,'Previous dungeon',16,-46,140,function() dungeonIndex=dungeonIndex-1;if dungeonIndex<1 then dungeonIndex=#list end;P.ShowDungeonAdvisor() end)
    btn(f,'Next dungeon',165,-46,140,function() dungeonIndex=dungeonIndex%#list+1;P.ShowDungeonAdvisor() end)
    label(f,d.name..' | '..d.min..'-'..d.max..' | '..(d.new and 'Forever range' or 'Classic range; Forever unconfirmed'),320,-48,450)
    label(f,'Enter estimates for your character at this level. Include wipes, quest pickups and turn-ins in overhead.',16,-82,760)
    local fields={{'grindRate','Measured grinding XP / hour',o.grindRate},{'killXP','Expected kill XP (your share)',input.killXP},{'clear','Clear time (minutes)',input.clear},{'travel','Travel time (minutes)',input.travel},{'wait','Group wait (minutes)',input.wait},{'prep','Quest / wipe overhead (minutes)',input.prep},{'extraQuestXP','Other verified quest XP (exclude subtotal)',input.extraQuestXP}}
    local boxes={}
    for i,field in ipairs(fields) do
        local x=(i%2==1) and 16 or 408;local y=-115-math.floor((i-1)/2)*35
        label(f,field[2],x,y,240)
        local edit=CreateFrame('EditBox',nil,f,'InputBoxTemplate');edit:SetSize(110,24);edit:SetPoint('TOPLEFT',x+254,y+4);edit:SetAutoFocus(false);edit:SetMaxLetters(10);edit:SetText(field[3]~=nil and tostring(field[3]) or '');boxes[field[1]]=edit
    end
    local message=label(f,'',16,-286,760)
    btn(f,'Start grinding sample',16,-255,220,function() local ok,text=P.StartGrindSample();message:SetText(text) end)
    btn(f,'Finish grinding sample',248,-255,220,function() local ok,text=P.FinishGrindSample();if ok then P.ShowDungeonAdvisor() else message:SetText(text) end end)
    btn(f,'Save / compare',410,-220,150,function()
        local value={level=P.Safe(UnitLevel,'player') or 1}
        for _,field in ipairs(fields) do
            local text=boxes[field[1]]:GetText() or '';local v=tonumber(text)
            if not v or v~=v or v<0 or v>=100000000 then message:SetText('Enter a nonnegative number for '..field[2]..'. Zero is allowed for no overhead.');return end
            value[field[1]]=v
        end
        if value.grindRate<=0 or value.clear<=0 then message:SetText('Grinding XP/hour and clear time must be greater than zero.');return end
        o.grindRate=value.grindRate;o.runs[d.id]=value;P.ShowDungeonAdvisor()
    end)
    btn(f,'Show guide',570,-220,190,function()f:Hide();P.OpenEfficiencyGuide()end)
    local report=P.DungeonComparison(d)
    local lines={d.zone,(P.grindSample and 'Grinding sample is running. All XP sources are included; finish before doing quests/dungeons.' or 'Use a measured grinding sample or enter your own XP/hour.'),report.message,string.format('Accepted quest beta-XP subtotal: %d (%d counted; %d accepted with unknown/reduced XP)',report.questXP,report.accepted,report.unpriced)}
    if report.rate then
        lines[#lines+1]=string.format('First run: %.0f XP in %.1f min = %.0f XP/hour. Grinding: %.0f XP/hour.',report.totalXP,report.minutes,report.rate,report.grindRate)
        lines[#lines+1]=string.format('Break-even: %.0f XP total; maximum wait %.1f min. Kill-only repeat clear: %.0f XP/hour before travel/wait.',report.breakEvenXP,report.maxWait,report.repeatRate)
        if report.grindToLevel then lines[#lines+1]=string.format('Grinding to next level: %.1f min (current XP and entered rate).',report.grindToLevel) end
        if report.nextLevelWarning then lines[#lines+1]=report.nextLevelWarning end
    end
    lines[#lines+1]='Quest XP is a beta reference, not a guaranteed payout. Only accepted, uncompleted quests within 5 levels of quest level are subtotaled. Add only OTHER verified XP. A repeat run does not repeat one-time quest XP.'
    lines[#lines+1]='QUEST PREPARATION / COMPLETION'
    for _,row in ipairs(report.quests) do
        local q=row.quest
        lines[#lines+1]=string.format('[%s] %s [%d] | beta XP %s',row.state,q.name,q.id,q.xp and tostring(q.xp) or 'unknown')
        if row.nextQuest and row.nextQuest.id~=q.id then lines[#lines+1]='Next prerequisite: '..row.nextQuest.name..' ['..row.nextQuest.id..']' end
    end
    if #report.quests==0 then lines[#lines+1]='No matching source quest records; this does not mean there are no quests.' end
    lines[#lines+1]='GEAR TO WEIGH AGAINST THE XP DETOUR (drop chances and future time savings unknown)'
    local plan=P.EfficiencyPlan();local goals={}
    for _,row in ipairs(plan.actions) do if row.item.dungeonID==d.id or row.item.activity==d.name then goals[#goals+1]=row end end
    for i,row in ipairs(goals) do if i<=8 then lines[#lines+1]=row.item.name..' | '..row.action..' | '..P.UpgradeDisplay({percent=row.estimate.percent,text=string.format('%+.1f%% %s',row.estimate.percent,row.estimate.metric)})..' | '..(row.item.questID and 'quest choice' or 'random drop') end end
    if #goals==0 then lines[#lines+1]='No measurable positive gear match in cached data. Missing data does not establish that all drops are bad.' end
    lines[#lines+1]='No drop odds, competition, weapon procs or future minutes saved are invented. Inspect restrictions before traveling. XP estimates expire on level-up.'
    local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',16,-322);scroll:SetPoint('BOTTOMRIGHT',-34,44)
    local child=CreateFrame('Frame',nil,scroll);child:SetSize(735,600);scroll:SetScrollChild(child)
    local text=label(child,table.concat(lines,'\n\n'),0,0,728);text:SetSpacing(4);child:SetHeight(math.max(285,text:GetStringHeight()+16))
    btn(f,'Track first unfinished quest',16,-610,235,function()
        for _,row in ipairs(report.quests) do if row.state~='completed' and row.state~='blocked' then P.profile.trackedQuests[tostring(row.quest.id)]=true;message:SetText('Tracking '..row.quest.name..'. Open the objective tracker to follow progress.');P.UpdateControls();return end end
        message:SetText('No unfinished matching quest to track.')
    end)
    btn(f,'Track first gear candidate',265,-610,235,function(self)
        if goals[1] then P.PinEfficiencyGoal(goals[1]);P.ItemTooltip({mode='target',id=goals[1].item.id},self) else message:SetText('No measurable candidate yet. Open Guide to load client item data.') end
    end)
    btn(f,'Refresh progress',515,-610,235,function()P.RefreshQuests();P.ShowDungeonAdvisor()end)
    f:Show()
end
