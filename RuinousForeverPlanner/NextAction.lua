local _,P=...
local function label(item) return (item.name or ('Item '..item.id)):gsub('|','||') end
function P.BagUpgradeActions()
    local result={};local snap=P.snapshot
    if not P.char or P.char.class~=P.actualClass or not snap or P.scanStale or P.deferred or #(snap.errors or {})>0 then return result end
    local level=P.Safe(UnitLevel,'player') or 1
    for _,item in ipairs(snap.bags) do
        local d=item.details
        if d and d.stats and d.minLevel and d.minLevel<=level then
            local best
            for _,slot in ipairs(P.slotOrder) do if P.SlotMatches(slot,d) then
                local cmp=P.CompareEquipment(slot,d,P.WeightedStatScore)
                if cmp and cmp.after>cmp.before and cmp.before>0 then
                    local pct=100*(cmp.after-cmp.before)/cmp.before
                    if not best or pct>best.percent then best={kind='bag',item=item,slot=slot,percent=pct,title='Inspect carried upgrade: '..label(item),why=string.format('%+.1f%% weighted stats; already in your bags. Verify training, unique restrictions and special effects before equipping.',pct),priority=20} end
                end
            end end
            if best then result[#result+1]=best end
        end
    end
    table.sort(result,function(a,b)if a.percent~=b.percent then return a.percent>b.percent end;if a.item.bag~=b.item.bag then return a.item.bag<b.item.bag end;return a.item.slot<b.item.slot end)
    return result
end
function P.ClassUnlockNotes()
    if not P.char or P.actualClass~='DRUID' then return {} end
    local level=P.Safe(UnitLevel,'player') or 1;if level<20 then return {} end
    local known=P.Safe(IsPlayerSpell,768)
    if known==true then return {} end
    return {'CLASS UNLOCK CHECK: Cat Form is a level-20 quest chain in Forever, not an automatic Classic trainer assumption.',
      'Review The Great Cat Spirit chain and your faction trainer. '..(known==false and 'Cat Form is not reported known.' or 'Spell knowledge could not be read.'),
      'Source-backed beta guidance: foreverchanges.pro/druid-cat-form (reviewed October 30). Other class unlock-to-spell mappings remain incomplete.'}
end
function P.NextActions()
    local rows={}
    if not P.char or P.char.class~=P.actualClass then return {{title='Return to your actual class',why='Use /rfp current before personalizing your next action.',priority=0}} end
    if P.Safe(InCombatLockdown) then return {{title='Finish the current fight',why='Planning reads resume outside combat.',priority=0}} end
    if not P.snapshot or P.scanStale or P.deferred or #(P.snapshot.errors or {})>0 then return {{title='Refresh gear and bags',why='Use Scan gear. Missing or stale reads cannot establish upgrades.',priority=0}} end
    local class=P.ClassQuestPlan()
    for _,row in ipairs(class.rows) do if row.min<=class.level then
        rows[#rows+1]={kind='quest',quest=row.quest,title=row.kind..': '..row.quest.name:gsub('|','||'),why=row.status..' Inspect the class reward; no unlock or solo-safety guarantee.',priority=row.active and 10 or 30}
        break
    end end
    for i,row in ipairs(P.BagUpgradeActions()) do if i<=2 then rows[#rows+1]=row end end
    local plan=P.EfficiencyPlan()
    for i,row in ipairs(plan.actions or {}) do if i<=2 then rows[#rows+1]={kind='gear',goal=row,title=row.action..': '..row.item.name,why=row.why,priority=40} end end
    local localQuests=P.LocalLevelingQuests()
    if localQuests[1] then local q=localQuests[1];rows[#rows+1]={kind='quest',quest=q,title=(q.active and 'Continue nearby quest: ' or 'Check nearby quest: ')..q.name,why='Same-zone level check; verify objectives and availability.',priority=q.active and 25 or 60} end
    table.sort(rows,function(a,b)if a.priority~=b.priority then return a.priority<b.priority end;return a.title<b.title end)
    if #rows==0 then rows[1]={title='Continue nearby leveling quests',why='No better supported detour resolved. Use Guide for hubs, Class Qs for chains or import an ordered route.',priority=100} end
    return rows
end
function P.NextActionLines(brief)
    local lines={'NEXT ACTION | current character, current gear'}
    if P.sessionSample then lines[#lines+1]='XP session sample running: all XP sources are counted.'
    elseif P.char and P.char.sessionSamples and P.char.sessionSamples[1] then local s=P.char.sessionSamples[1];lines[#lines+1]=string.format('Last observed session: %.0f XP/hour over %.1f min (all XP).',s.rate,s.seconds/60) end
    local route=P.char and P.char.route
    if route then for _,line in ipairs(P.RouteLines(brief)) do lines[#lines+1]=line end end
    for _,line in ipairs(P.ClassUnlockNotes()) do lines[#lines+1]=line end
    for i,row in ipairs(P.NextActions()) do if i<=(brief and 1 or 3) then
        lines[#lines+1]=(i==1 and 'SUGGESTED: ' or 'ALSO: ')..row.title
        if not brief then lines[#lines+1]=row.why end
    end end
    if not brief then
        lines[#lines+1]='Carried gear is checked at every level without requiring a BiS list. The published external benchmarks remain level-30 references; no 31-60 BiS is invented.'
        lines[#lines+1]='Use the action buttons to pin a suggestion, import a route, set its map waypoint or confirm a manual step. Quest completion advances supported imported steps automatically.'
    end
    return lines
end
function P.PinNextAction()
    local row=P.NextActions()[1];if not row then return false end
    if row.kind=='quest' then P.profile.trackedQuests[tostring(row.quest.id)]=true
    elseif row.kind=='gear' then return P.PinEfficiencyGoal(row.goal)
    elseif row.kind=='bag' then
        local ok,msg=P.ItemTooltip({mode='bag',bag=row.item.bag,slot=row.item.slot},P.primaryButton)
        if not ok then print(msg) end
        return ok
    else return false end
    P.UIOptions().tracker=true;P.UpdateControls();return true
end
