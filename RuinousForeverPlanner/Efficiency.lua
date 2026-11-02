local _,P=...
local function number(v) return type(v)=='number' and v==v and v>=0 and v<100000000 end
function P.StartGrindSample()
    local level=P.Safe(UnitLevel,'player');local xp=P.Safe(UnitXP,'player');local maximum=P.Safe(UnitXPMax,'player');local now=P.Safe(GetTime)
    if not number(level) or level>=60 or not number(xp) or not number(maximum) or maximum<=0 or not number(now) then return false,'XP / time APIs unavailable, or already level 60.' end
    P.grindSample={level=level,xp=xp,maximum=maximum,start=now,gained=0}
    return true,'Sample started. Grind normally; include recovery time. Avoid quest turn-ins and dungeon XP.'
end
function P.RecordGrindSample()
    local s=P.grindSample;if not s or s.error then return end
    local level=P.Safe(UnitLevel,'player');local xp=P.Safe(UnitXP,'player');local maximum=P.Safe(UnitXPMax,'player')
    if not number(level) or not number(xp) or not number(maximum) then s.error='XP observation unavailable; restart sample.';return end
    local gain
    if level==s.level and xp>=s.xp then gain=xp-s.xp
    elseif level==s.level+1 then gain=s.maximum-s.xp+xp
    else s.error='XP transition could not be resolved; restart sample.';return end
    s.gained=s.gained+gain;s.level=level;s.xp=xp;s.maximum=maximum
end
function P.FinishGrindSample()
    local s=P.grindSample;if not s then return false,'Start a grinding sample first.' end
    P.RecordGrindSample()
    if s.error then return false,s.error end
    local now=P.Safe(GetTime);local elapsed=number(now) and now-s.start
    if not elapsed or elapsed<60 then return false,'Sample for at least 60 seconds before finishing.' end
    if s.gained<=0 then return false,'No XP recorded yet. Continue grinding or restart the sample.' end
    local rate=s.gained*3600/elapsed
    if not number(rate) then return false,'Sample rate unavailable.' end
    local o=P.EfficiencyOptions();o.grindRate=rate;o.sample={xp=s.gained,seconds=elapsed,level=s.level}
    P.grindSample=nil
    return true,string.format('Measured %.0f XP/hour over %.1f minutes (all XP during sample counted).',rate,elapsed/60)
end
local loadKey,loadQueue,loadIndex,loadElapsed=nil,{},0,0
function P.StartEfficiencyLoad(force)
    if not P.char or P.char.class~=P.actualClass or P.Safe(InCombatLockdown) then return end
    local level=P.Safe(UnitLevel,'player') or 1
    local key=(P.characterKey or '')..':'..level..':'..P.char.activeProfile
    if key==loadKey and not force then return end
    loadKey=key;loadQueue={};loadIndex=0
    local seen={}
    for _,g in ipairs(P.EfficiencyCandidates()) do
        if not seen[g.id] and not P.requested[g.id] then loadQueue[#loadQueue+1]=g.id;seen[g.id]=true end
    end
end
function P.EfficiencyLoadStep(elapsed)
    if not P.char or P.Safe(InCombatLockdown) then return end
    loadElapsed=loadElapsed+(type(elapsed)=='number' and elapsed or 0)
    if loadElapsed<.2 then return end
    loadElapsed=0
    for i=1,5 do
        if loadIndex>=#loadQueue then break end
        loadIndex=loadIndex+1;P.Item(loadQueue[loadIndex])
    end
end
function P.EfficiencyOptions()
    if not P.char then return end
    if type(P.char.efficiency)~='table' then P.char.efficiency={} end
    local o=P.char.efficiency
    if type(o.runs)~='table' then o.runs={} end
    if type(o.onRoute)~='table' then o.onRoute={} end
    return o
end
function P.EfficiencyWindow()
    local level=P.Safe(UnitLevel,'player') or 1
    return level,math.min(60,level+10)
end
function P.WindowDungeons()
    local lo,hi=P.EfficiencyWindow();local rows={}
    for _,d in ipairs(P.EfficiencyData.dungeons) do if d.min<=hi and d.max>=lo then rows[#rows+1]=d end end
    table.sort(rows,function(a,b) if a.min~=b.min then return a.min<b.min end return a.id<b.id end)
    return rows
end
function P.DungeonQuestRows(d)
    local rows={};local level=P.Safe(UnitLevel,'player') or 1
    for _,q in ipairs(d.quests) do
        if (not q.faction or q.faction==P.Safe(UnitFactionGroup,'player')) and P.BaselineQuestMatches(q.id) then
            local s=P.QuestObservation(q.id);local nextQuest,status=P.QuestNext(q.id)
            local reason=P.KnownQuestBlock(q.id)
            local eligible=number(q.minLevel) and q.minLevel<=level
            local state=s.completed==true and 'completed' or reason and 'blocked' or not eligible and 'future / minimum unknown'
                or s.active==true and 'in log' or status=='restricted' and 'blocked' or 'check prerequisites'
            -- Only accepted, non-completed, level-appropriate quests enter the nominal XP subtotal.
            local counted=s.completed==false and state=='in log' and number(q.xp) and number(q.level) and level<=q.level+5
            rows[#rows+1]={quest=q,state=state,counted=counted,reason=reason,nextQuest=nextQuest}
        end
    end
    table.sort(rows,function(a,b)if (a.state=='in log')~=(b.state=='in log') then return a.state=='in log' end return a.quest.id<b.quest.id end)
    return rows
end
function P.DungeonComparison(d,override)
    local o=P.EfficiencyOptions();local input=override or o and o.runs[d.id] or {}
    if type(input)~='table' then input={} end
    local r={dungeon=d,quests=P.DungeonQuestRows(d),questXP=0,accepted=0,unpriced=0}
    for _,q in ipairs(r.quests) do
        if q.counted then r.questXP=r.questXP+q.quest.xp;r.accepted=r.accepted+1
        elseif q.state=='in log' then r.unpriced=r.unpriced+1 end
    end
    local level=P.Safe(UnitLevel,'player') or 1
    if P.Safe(InCombatLockdown) or P.questDeferred then r.message='Refresh quest progress outside combat before comparing this run.';return r end
    if P.char and P.char.class~=P.actualClass then r.message='Choose your actual class for quest and gear comparisons.';return r end
    if level>=60 then r.message='Level 60: XP leveling comparison does not apply.';return r end
    if level<d.min or level>d.max then r.message='Future/reference dungeon: level into its planning band first.';return r end
    local rate=override and override.grindRate or o and o.grindRate
    if not number(rate) or rate<=0 then r.message='Set your measured grinding XP/hour in Dungeon comparison.';return r end
    if input.level~=level then r.message='Enter or reconfirm this run estimate at your current level.';return r end
    for _,key in ipairs({'killXP','clear','travel','wait','prep','extraQuestXP'}) do
        if not number(input[key]) then r.message='Missing run estimate: '..key;return r end
    end
    if input.clear<=0 then r.message='Clear time must be greater than zero.';return r end
    local minutes=input.clear+input.travel+input.wait+input.prep
    r.totalXP=r.questXP+input.extraQuestXP+input.killXP
    r.minutes=minutes;r.rate=60*r.totalXP/minutes;r.grindRate=rate
    r.deltaMinutes=r.totalXP/rate*60-minutes
    r.breakEvenXP=rate*minutes/60
    r.maxWait=60*r.totalXP/rate-input.clear-input.travel-input.prep
    r.repeatRate=60*input.killXP/input.clear
    local xp,max=P.Safe(UnitXP,'player'),P.Safe(UnitXPMax,'player')
    if number(xp) and number(max) and max>xp then
        r.grindToLevel=60*(max-xp)/rate
        r.nextLevelWarning=r.grindToLevel<minutes and 'Grinding is projected to reach your next level before this full run finishes; the dungeon comparison credits all run XP.' or nil
    end
    r.verdict=r.deltaMinutes>2 and 'ONE RUN: faster XP in this scenario' or r.deltaMinutes< -2 and 'GRIND / QUEST: faster XP in this scenario' or 'CLOSE CALL: choose by useful guaranteed rewards'
    r.message=string.format('%s | %s%.1f minutes versus equal XP grinding',r.verdict,r.deltaMinutes>=0 and 'saves ' or 'costs ',math.abs(r.deltaMinutes))
    return r
end
-- Numeric source values and live values are kept separate. No item-level scoring.
local function statScore(stats)
    if type(stats)~='table' then return end
    local weights=P.UpgradeWeights();if not weights then return end
    local total=0;local soloHealer=P.char.mode=='solo' and P.ProfileRole()=='healer'
    for _,field in ipairs(P.UpgradeStats) do
        local value=stats[field[1]] or 0;local weight=weights[field[1]]
        if not number(value) or not number(weight) then return end
        if soloHealer then
            if field[1]=='ITEM_MOD_SPELL_HEALING_DONE_SHORT' then weight=0 end
            if field[1]=='ITEM_MOD_SPELL_DAMAGE_DONE_SHORT' then weight=1.5 end
        end
        total=total+value*weight
    end
    return total
end
local function plain(v)return not (type(issecretvalue)=='function' and issecretvalue(v))end
local function weaponDPS(link)
    if not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink)~='function' then return end
    local locale=P.Safe(GetLocale)
    if locale~='enUS' and locale~='enGB' then return end
    local data=P.Safe(C_TooltipInfo.GetHyperlink,link)
    if type(data)~='table' or type(data.lines)~='table' then return end
    for _,line in ipairs(data.lines) do
        if type(line)=='table' and plain(line.leftText) and type(line.leftText)=='string' then
            local v=tonumber(line.leftText:match('%((%d+%.?%d*) damage per second%)'))
            if number(v) and v>0 then return v end
        end
    end
end
local function compatible(a,b)
    return a and b and a.equipLoc and (a.equipLoc==b.equipLoc or
        ((a.equipLoc=='INVTYPE_CHEST' or a.equipLoc=='INVTYPE_ROBE') and (b.equipLoc=='INVTYPE_CHEST' or b.equipLoc=='INVTYPE_ROBE')))
end
function P.LevelingEstimate(g,details)
    if not P.char or P.char.class~=P.actualClass then return {reason='Choose your actual class before comparing equipped gear'} end
    local level,hi=P.EfficiencyWindow();local snap=P.snapshot
    if not snap or #snap.errors>0 or P.scanStale or P.deferred or P.Safe(InCombatLockdown) then return {reason='Scan gear outside combat'} end
    local d=details or P.ItemDetails(g.id)
    if not d or not number(d.minLevel) or d.minLevel>hi then return {reason='Wear level / client data unavailable in this window'} end
    local old=snap.equipped[g.slot];local comparisonSlot=g.slot
    if g.slot==11 or g.slot==13 then
        local second=snap.equipped[g.slot+1]
        local a=old and old.details and statScore(old.details.stats)
        local b=second and second.details and statScore(second.details.stats)
        if compatible(d,second and second.details) and a and b and b<a then old=second;comparisonSlot=g.slot+1 end
    end
    if g.slot==16 or g.slot==17 then
        local combined,reason=P.CompareEquipment(g.slot,d,statScore)
        if combined and combined.before>0 then return {percent=100*(combined.after-combined.before)/combined.before,before=combined.before,after=combined.after,metric='combined weapon-set stats (resolved enchants included)',slot=g.slot,wearLevel=d.minLevel,details=d} end
        if g.slot==17 then return {reason=reason or 'Weapon-set baseline has zero weighted stats'} end
    end
    if not old or not compatible(d,old.details) then return {reason='Empty slot or equipment combination: inspect manually'} end
    local before,after,metric
    if g.slot==16 or g.slot==18 then
        local cls=P.char.class
        local weaponMatters=(g.slot==18 and (cls=='HUNTER' or P.char.mode=='solo' and (cls=='PRIEST' or cls=='MAGE' or cls=='WARLOCK')))
            or (g.slot==16 and (P.ProfileRole()~='healer' or P.char.mode=='solo') and (cls=='WARRIOR' or cls=='ROGUE' or cls=='PALADIN' or cls=='SHAMAN'))
        if not weaponMatters or not d.subclassID or d.subclassID~=old.details.subclassID or d.classID~=2
            or (g.slot==16 and snap.equipped[17]) then return {reason='Weapon type / off-hand / form effects require manual comparison'} end
        before=weaponDPS(old.link);after=weaponDPS(d.link);metric='base weapon DPS (not character DPS)'
    else
        -- Do not infer an armor proficiency upgrade from the selected role.
        if d.classID==4 and number(d.subclassID) and d.subclassID>=2 and d.subclassID<=4
            and (not old.details.subclassID or d.subclassID>old.details.subclassID) then return {reason='Armor training not established: inspect manually'} end
        before=statScore(old.details.stats);after=statScore(d.stats);metric='weighted leveling stats'
    end
    if not number(before) or before<=0 or not number(after) then return {reason='Comparable stats / weapon DPS unavailable'} end
    return {percent=100*(after-before)/before,before=before,after=after,metric=metric,slot=comparisonSlot,wearLevel=d.minLevel,details=d}
end
function P.EfficiencyCandidates()
    local list,seen={},{};local lo,hi=P.EfficiencyWindow()
    for _,g in ipairs(P.TrackableGear()) do
        if g.min<=hi and g.max>=lo and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) then
            local copy={};for k,v in pairs(g) do copy[k]=v end
            if g.mode=='group' then for _,d in ipairs(P.EfficiencyData.dungeons) do
                for _,fact in ipairs(d.items) do if fact.id==g.id and (not g.activity or g.activity==d.name or g.activity:find(d.name:gsub('^The ',''),1,true)) then
                    copy.dungeonID=d.id;copy.dungeonMin=d.min;copy.dungeonMax=d.max;break
                end end
                if copy.dungeonID then break end
            end end
            list[#list+1]=copy;seen[g.id]=true
        end
    end
    for _,d in ipairs(P.WindowDungeons()) do
        local quests={};for _,q in ipairs(d.quests) do quests[q.id]=q end
        for _,fact in ipairs(d.items) do
            local q=fact.questID and quests[fact.questID]
            if not seen[fact.id] and (not q or ((not q.faction or q.faction==P.Safe(UnitFactionGroup,'player')) and P.BaselineQuestMatches(q.id))) then
                local g={};for k,v in pairs(fact) do g[k]=v end
                g.min=g.sourceMinLevel or d.min;g.max=60;g.mode='group';g.effort=q and 'quest' or 'dungeon';g.activity=d.name
                g.dungeonMin=d.min;g.dungeonMax=d.max;g.dungeonID=d.id;g.questMin=q and q.minLevel
                g.clientComparisonOnly=true;g.acquire=q and ('Quest: '..q.name) or ('Possible drop: '..(g.boss or d.name))
                list[#list+1]=g;seen[g.id]=true
            end
        end
    end
    return list
end
function P.LocalLevelingQuests()
    local zone=P.Safe(GetRealZoneText) or P.Safe(GetZoneText)
    local rows={};local lo=P.EfficiencyWindow()
    if type(zone)~='string' or zone=='' or not C_Map or type(C_Map.GetAreaInfo)~='function' then return rows end
    for id,q in pairs(P.baselineQuests) do
        if number(q.zoneOrSort) and q.zoneOrSort>0 and number(q.requiredLevel) and q.requiredLevel<=lo
            and number(q.questLevel) and q.questLevel>=lo-2 and q.questLevel<=lo+1
            and P.Safe(C_Map.GetAreaInfo,q.zoneOrSort)==zone and P.BaselineQuestMatches(id) then
            local s=P.QuestObservation(id)
            if s.completed==false and not P.KnownQuestBlock(id) then
                local nextQuest,status=P.QuestNext(id)
                if status~='restricted' and nextQuest and nextQuest.id==id then rows[#rows+1]={id=id,name=q.name,active=s.active==true} end
            end
        end
    end
    table.sort(rows,function(a,b)if a.active~=b.active then return a.active end return a.id<b.id end)
    return rows
end
function P.EfficiencyPlan()
    local lo,hi=P.EfficiencyWindow();local r={level=lo,lastLevel=hi,actions={},stages={},dungeons=P.WindowDungeons(),unknown=0}
    if not P.char or P.char.class~=P.actualClass or not P.ProfileSupported() then r.unavailable='Select your actual class and spec.';return r end
    if P.Safe(InCombatLockdown) or not P.snapshot or #P.snapshot.errors>0 or P.scanStale or P.deferred then r.unavailable='Scan gear outside combat before personalizing detours.';return r end
    if lo>=60 then r.unavailable='Level 60 reached: use Rating and Gear for endgame goals.';return r end
    for _,s in ipairs(P.Data.stages) do if s.min<=hi and s.max>=lo then r.stages[#r.stages+1]=s end end
    local o=P.EfficiencyOptions();local evaluations={};local comparisons={};local candidates=P.EfficiencyCandidates()
    for _,d in ipairs(r.dungeons) do comparisons[d.id]=P.DungeonComparison(d) end
    for _,g in ipairs(candidates) do
        if not P.profile.skipped[tostring(g.id)] and g.confirmed~=false and not g.randomSuffix then
            local state=P.CandidateOwned(g);local questID=P.RewardQuestID(g)
            local q,status;if questID then q,status=P.QuestNext(questID) end
            if state~='Equipped' and not state:find('Unknown',1,true) and status~='restricted'
                and (not questID or not P.KnownQuestBlock(questID)) and (status~='completed' or state=='In bags (not equipped)') then
                local estimate=P.LevelingEstimate(g)
                if estimate.percent then evaluations[#evaluations+1]={item=g,estimate=estimate,state=state,quest=q,status=status}
                else r.unknown=r.unknown+1 end
            end
        end
    end
    for _,row in ipairs(evaluations) do
        local g,e=row.item,row.estimate
        if e.percent>0 then
            local future=math.max(e.wearLevel,g.dungeonMin or 0,g.questMin or 0,g.min or 0)
            local replacement
            for _,other in ipairs(evaluations) do
                local od=other.estimate
                local available=math.max(od.wearLevel,other.item.dungeonMin or 0,other.item.questMin or 0,other.item.min or 0)
                if (other.item.mode~='group' or other.state=='In bags (not equipped)') and other.item.slot==g.slot and other.item.id~=g.id and od.metric==e.metric and od.after>e.after
                    and available>lo and available<=lo+3 and (not replacement or available<replacement) then replacement=available end
            end
            local action,why,priority
            if row.state=='In bags (not equipped)' then action='INSPECT CARRIED';why='Already owned: no acquisition detour. Required level '..e.wearLevel..'.';priority=1
            elseif replacement and (g.mode=='group' or g.effort=='craft') and lo<55 then action='LEVEL FIRST';why='A better comparable candidate enters its planning window at '..replacement..'; prerequisites still need checking.';priority=35
            elseif future>lo then action='PREPARE AT '..future;why='Future candidate within ten levels; do not farm before wear and dungeon readiness.';priority=45
            elseif g.mode=='group' then
                action='ONE PREPARED RUN';why=g.questID and 'Quest reward: resolve prerequisites and choose the reward; no repeat-farm advice.' or 'Random drop: no guaranteed acquisition or farming time.';priority=25
                if P.char.mode=='solo' then action='OPTIONAL GROUP';why='Keep solo leveling while finding a party. '..why;priority=40 end
                if g.dungeonID then
                    for _,d in ipairs(r.dungeons) do if d.id==g.dungeonID then
                        local comparison=comparisons[d.id]
                        why=why..' '..comparison.message
                        if comparison.deltaMinutes and comparison.deltaMinutes< -2 then action='SKIP FOR XP';priority=55 end
                    end end
                end
            elseif g.effort=='craft' or g.effort=='purchase' then action='LOW-COST ONLY';why='Use an existing crafter or affordable purchase; price, materials and payback are unmeasured.';priority=30
            elseif row.status=='active' or o.onRoute[tostring(g.id)] then action='ON-ROUTE QUEST';why='Quest accepted or marked on your route; batch it with local objectives. Travel savings are not measured.';priority=10
            else action='CHECK QUEST CHAIN';why='Confirm prerequisites and travel before making a detour.';priority=20 end
            local lifespan=math.max(0,hi-math.max(lo,future))
            r.actions[#r.actions+1]={item=g,estimate=e,action=action,why=why,priority=priority,quest=row.quest,expectedWindow=lifespan}
        end
    end
    local main=P.snapshot.equipped[16]
    if main and main.details and main.details.equipLoc=='INVTYPE_2HWEAPON' then
        local allowed={}
        for _,g in ipairs(candidates) do if (g.slot==16 or g.slot==17) and not P.profile.skipped[tostring(g.id)] then
            local id=P.RewardQuestID(g);local nextQuest,status;if id then nextQuest,status=P.QuestNext(id) end
            local owned=P.CandidateOwned(g)
            if status~='restricted' and (status~='completed' or owned=='Equipped' or owned=='In bags (not equipped)') and (not id or not P.KnownQuestBlock(id)) then allowed[#allowed+1]=g end
        end end
        local set=P.HandBenchmark(allowed,statScore,function(g)return P.ItemDetails(g.id)end,hi,false,lo)
        if set and set.off then
            local comparison=P.CompareEquipment(16,set.main.details,statScore,set.off)
            local available=math.max(set.main.details.minLevel,set.off.details.minLevel,set.main.item.min,set.off.item.min,set.main.item.dungeonMin or 0,set.off.item.dungeonMin or 0,set.main.item.questMin or 0,set.off.item.questMin or 0)
            if comparison and comparison.before>0 and comparison.after>comparison.before and available<=hi then
                local pct=100*(comparison.after-comparison.before)/comparison.before
                r.actions[#r.actions+1]={item=set.main.item,partner=set.off.item,estimate={percent=pct,before=comparison.before,after=comparison.after,metric='complete one-hand + off-hand stat set',slot=16},action=available>lo and ('PREPARE SET AT '..available) or 'COMPARE ONE-HAND + OFF-HAND',why='Inspect BOTH '..set.main.item.name..' and '..set.off.item.name..' together. This stat comparison includes resolved equipped enchants; damage/procs/training are not simulated.',priority=25,expectedWindow=hi-math.max(lo,available)}
            end
        end
    end
    table.sort(r.actions,function(a,b) if a.priority~=b.priority then return a.priority<b.priority end if a.estimate.percent~=b.estimate.percent then return a.estimate.percent>b.estimate.percent end return a.item.id<b.item.id end)
    r.quests=P.LocalLevelingQuests()
    return r
end
function P.EfficiencyLines(report,brief)
    local r=report or P.EfficiencyPlan();local lines={'TIME EFFICIENCY | Level '..r.level..' -> '..r.lastLevel..' (10-level horizon)'}
    if r.unavailable then lines[#lines+1]=r.unavailable;return lines end
    for _,line in ipairs(P.ClassQuestLines(brief)) do lines[#lines+1]=line end
    lines[#lines+1]='Main route: batch nearby quests; avoid isolated gear farms. Gear percentages do not predict time saved.'
    if loadIndex<#loadQueue then lines[#lines+1]='Loading client item data: '..loadIndex..' / '..#loadQueue..' checked. Reopen Guide after loading.' end
    if #r.actions==0 then lines[#lines+1]='No measurable positive detour found in cached data. Continue questing / grinding; inspect unscored gear.' end
    for i,a in ipairs(r.actions) do if i<=(brief and 2 or 8) then
        lines[#lines+1]=a.action..': '..a.item.name
        lines[#lines+1]=P.UpgradeDisplay({percent=a.estimate.percent,text=string.format('%+.1f%% %s',a.estimate.percent,a.estimate.metric)..' vs '..(P.slotNames[a.estimate.slot] or 'equipped')})
        if not brief then lines[#lines+1]=a.why;lines[#lines+1]='Remaining planning window after availability: '..a.expectedWindow..' levels (replacement date unknown).';if a.quest then lines[#lines+1]='Next quest: '..a.quest.name..' ['..a.quest.id..']' end end
    end end
    if not brief then
        for _,line in ipairs(P.EnchantLines(false)) do lines[#lines+1]=line end
        lines[#lines+1]='LOCAL QUEST CHECKS (same zone / similar level; not a fastest-route certification)'
        for i,q in ipairs(r.quests) do if i<=6 then lines[#lines+1]=(q.active and '[In log] ' or '[Check giver] ')..q.name..' ['..q.id..']' end end
        if #r.quests==0 then lines[#lines+1]='No resolved local quests: use the stage hubs below and Quest catalogue. QuestieDB indexing / zone data may be incomplete.' end
        lines[#lines+1]='DUNGEONS: open Dungeon comparison for quest progress, XP break-even and gear.'
        for _,d in ipairs(r.dungeons) do lines[#lines+1]=d.name..' '..d.min..'-'..d.max..' | '..P.DungeonComparison(d).message end
        lines[#lines+1]='NEXT STAGE HUBS (Classic-derived; Forever route verification incomplete)'
        for _,s in ipairs(r.stages) do lines[#lines+1]=s.min..'-'..s.max..': '..(P.Safe(UnitFactionGroup,'player')=='Horde' and s.horde or s.alliance) end
        lines[#lines+1]='Unscored candidates: '..r.unknown..'. Gear effects, armor training, risk and prerequisites need inspection. Solo healer leveling ignores healing-only stats; weapon estimates require same-type live English tooltips and exclude off-hand/form changes.'
    end
    return lines
end

function P.EfficiencyQuestRecord(id)
    for _,d in ipairs(P.EfficiencyData.dungeons) do for _,q in ipairs(d.quests) do if q.id==id then
        return {id=q.id,name=q.name,summary='Check '..q.name..' in the live quest log.',previous=0,minLevel=q.minLevel,faction=q.faction,chainIncomplete=true,source=q.source}
    end end end
end
function P.PinEfficiencyGoal(row)
    if not row or not P.profile then return false end
    if type(P.profile.efficiencyGoals)~='table' then P.profile.efficiencyGoals={} end
    P.profile.efficiencyGoals[tostring(row.item.id)]=true
    if row.partner then P.profile.efficiencyGoals[tostring(row.partner.id)]=true end
    if row.quest then P.profile.trackedQuests[tostring(row.quest.id)]=true end
    P.UIOptions().efficiencyTracker=true;P.UpdateControls();return true
end
