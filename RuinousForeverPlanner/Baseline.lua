local _,P=...
P.baselineQuests={}
local classBits={WARRIOR=1,PALADIN=2,HUNTER=4,ROGUE=8,PRIEST=16,SHAMAN=64,MAGE=128,WARLOCK=256,DRUID=1024}
local raceBits={Human=1,Orc=2,Dwarf=4,NightElf=8,Scourge=16,Undead=16,Tauren=32,Gnome=64,Troll=128}
local function overlap(a,b)
    if type(a)~='number' or a==0 then return true end
    if type(b)~='number' then return nil end
    a=math.floor(a);b=math.floor(b)
    while a>0 and b>0 do if a%2==1 and b%2==1 then return true end; a=math.floor(a/2);b=math.floor(b/2) end
    return false
end
local keys={'name','requiredLevel','questLevel','requiredClasses','requiredRaces','preQuestGroup','preQuestSingle','exclusiveTo','requiredSkill','requiredMinRep','requiredMaxRep','requiredSpell','requiredSpecialization','requiredMaxLevel','disabledByQuest','zoneOrSort','objectivesText','parentQuest','availableUntilCompleted','availableStartingWith','requiredRanks'}
function P.GetBaselineQuest(id)
    if P.baselineQuests[id] then return P.baselineQuests[id] end
    local provider=P.baselineProvider
    if not provider then return end
    local ok,values=pcall(provider.Quest.GetAll,id,keys)
    if not ok or type(values)~='table' or type(values[1])~='string' then return end
    local q={id=id,name=values[1],summary=values[1],previous=0,baseline=true,source='QuestieDB installed Forever catalogue; live eligibility not established'}
    for i,key in ipairs(keys) do q[key]=values[i] end
    q.minLevel=q.requiredLevel
    q.chainIncomplete=type(q.requiredSkill)=='table' or type(q.requiredMinRep)=='table' or type(q.requiredMaxRep)=='table' or (type(q.requiredSpell)=='number' and q.requiredSpell>0) or (type(q.requiredSpecialization)=='number' and q.requiredSpecialization>0) or type(q.requiredRanks)=='table'
    local masks=provider.Enum and provider.Enum.factionRaceMasks or {}
    local a,h=overlap(q.requiredRaces,masks.Alliance or 77),overlap(q.requiredRaces,masks.Horde or 178)
    if a and not h then q.faction='Alliance' elseif h and not a then q.faction='Horde' end
    P.baselineQuests[id]=q; return q
end
function P.BaselineQuestMatches(id)
    local q=P.GetBaselineQuest(id)
    if not q then return true end -- Preserve source-linked candidates with explicit unknown eligibility.
    if overlap(q.requiredClasses,classBits[P.char and P.char.class])==false then return false end
    local race
    if type(UnitRace)=='function' then local ok,_,token,id=pcall(UnitRace,'player'); if ok then local enums=P.baselineProvider and P.baselineProvider.Enum;race=enums and enums.raceMaskById and enums.raceMaskById[id] or raceBits[token] end end
    if race and overlap(q.requiredRaces,race)==false then return false end
    if q.faction and q.faction~=P.Safe(UnitFactionGroup,'player') then return false end
    return true
end
function P.QuestObservation(id)
    if P.questDeferred or P.Safe(InCombatLockdown) then return {error='deferred'} end
    local done,de=P.Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,id)
    local active,ae=P.Safe(C_QuestLog and C_QuestLog.IsOnQuest,id)
    local observation={error=de or ae}
    if type(done)=='boolean' then observation.completed=done end
    if type(active)=='boolean' then observation.active=active end
    return observation
end
function P.KnownQuestBlock(id)
    local q=P.GetBaselineQuest(id);if not q then return end
    if type(q.exclusiveTo)=='table' then for _,other in ipairs(q.exclusiveTo) do
        if P.QuestObservation(other).completed==true then return 'An exclusive alternative is already completed.' end
    end end
    if type(q.availableUntilCompleted)=='number' and q.availableUntilCompleted>0 and P.QuestObservation(q.availableUntilCompleted).completed==true then return 'Availability-ending quest is already completed.' end
    if type(q.parentQuest)=='number' and q.parentQuest>0 and P.QuestObservation(q.parentQuest).active~=true then return 'Parent quest must be active; verify its state.' end
    if type(q.availableStartingWith)=='number' and q.availableStartingWith>0 then local s=P.QuestObservation(q.availableStartingWith);if s.active~=true and s.completed~=true then return 'Availability-starting quest not known active or complete.' end end
    if type(q.requiredMaxLevel)=='number' and q.requiredMaxLevel>0 and (P.Safe(UnitLevel,'player') or 0)>q.requiredMaxLevel then return 'Above the baseline maximum level.' end
    if type(q.disabledByQuest)=='number' and q.disabledByQuest>0 and P.QuestObservation(q.disabledByQuest).active==true then return 'Another active quest blocks this quest.' end
end
function P.NextBaselineQuest(id,seen)
    seen=seen or {}; if seen[id] then return nil,'unknown' end; seen[id]=true
    local q=P.GetBaselineQuest(id)
    if not q then return nil,'unknown' end
    local s=P.QuestObservation(id)
    if s.completed==true then return nil,'completed' end
    if s.active==true then return q,'active' end
    if not P.BaselineQuestMatches(id) or P.KnownQuestBlock(id) then return nil,'restricted' end
    local group=q.preQuestGroup
    if type(group)=='table' then for _,pre in ipairs(group) do
        if P.QuestObservation(pre).completed~=true then
            local nextQuest,status=P.NextBaselineQuest(pre,seen); return nextQuest or q,status=='completed' and 'check' or status
        end
    end end
    local single=q.preQuestSingle
    if type(single)=='table' and #single>0 then
        local fulfilled=false
        for _,pre in ipairs(single) do if P.QuestObservation(pre).completed==true then fulfilled=true end end
        if not fulfilled then for _,pre in ipairs(single) do if P.BaselineQuestMatches(pre) then
            local nextQuest,status=P.NextBaselineQuest(pre,seen); return nextQuest or q,status=='completed' and 'check' or status
        end end end
    end
    return q,'check'
end
function P.StartBaseline()
    P.baselineProvider=nil;P.baselineQuests={};P.baselineIndex=0;P.baselineIDs={}
    local lib=LibQuestieDB
    if type(lib)~='table' or type(lib.RequireContract)~='function' or type(lib.Quest)~='table' or type(lib.Quest.GetAllIds)~='function' or type(lib.Quest.GetAll)~='function' then
        if P.SourceData then for id,q in pairs(P.SourceData.quests) do P.baselineQuests[tonumber(id)]=q end end
        P.baselineMessage='QuestieDB not available: source-linked quests only. Enable QuestieDB for the complete installed quest baseline.';return
    end
    local ok,compatible=pcall(lib.RequireContract,4)
    if not ok or not compatible then P.baselineMessage='QuestieDB contract incompatible; update QuestieDB. Source-linked quests remain available.';return end
    local ids;ok,ids=pcall(lib.Quest.GetAllIds)
    if not ok or type(ids)~='table' then P.baselineMessage='QuestieDB quest index unavailable.';return end
    P.baselineProvider=lib
    for _,id in ipairs(ids) do if type(id)=='number' then P.baselineIDs[#P.baselineIDs+1]=id end end
    table.sort(P.baselineIDs);P.baselineMessage='QuestieDB baseline indexing'
end
function P.BaselineStep()
    if not P.baselineProvider or P.Safe(InCombatLockdown) then return end
    local previous=P.baselineIndex
    local finish=math.min(#P.baselineIDs,P.baselineIndex+20)
    for i=P.baselineIndex+1,finish do P.GetBaselineQuest(P.baselineIDs[i]) end
    P.baselineIndex=finish
    P.baselineMessage='QuestieDB: '..finish..' / '..#P.baselineIDs..' quests indexed. Availability still needs live checks.'
    if previous~=finish and finish==#P.baselineIDs and P.Refresh then P.Refresh() end
end
function P.BrowseBaseline(query,allLevels)
    local result={};query=(query or ''):lower();local level=P.Safe(UnitLevel,'player') or 1
    for id,q in pairs(P.baselineQuests) do
        local nearby=(q.questLevel or q.minLevel or 0)>=level-5 and (q.requiredLevel or 0)<=level+3
        if P.BaselineQuestMatches(id) and (allLevels or nearby) and (query=='' or tostring(id)==query or q.name:lower():find(query,1,true)) then result[#result+1]=q end
    end
    table.sort(result,function(a,b)
        local la,lb=a.questLevel or a.minLevel or 0,b.questLevel or b.minLevel or 0
        if la~=lb then return la<lb end;return a.id<b.id
    end)
    return result
end
