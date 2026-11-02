local _,P=...
local bits={WARRIOR=1,PALADIN=2,HUNTER=4,ROGUE=8,PRIEST=16,SHAMAN=64,MAGE=128,WARLOCK=256,DRUID=1024}
local sorts={WARRIOR=-81,PALADIN=-141,HUNTER=-261,ROGUE=-162,PRIEST=-262,SHAMAN=-82,MAGE=-161,WARLOCK=-61,DRUID=-263}
local function has(mask,bit) return type(mask)=='number' and type(bit)=='number' and math.floor(mask/bit)%2==1 end
function P.IsClassQuest(q)
    if not q or not P.actualClass then return false end
    if q.zoneOrSort==sorts[P.actualClass] then return true end
    if not has(q.requiredClasses,bits[P.actualClass]) then return false end
    for _,bit in pairs(bits) do if not has(q.requiredClasses,bit) then return true end end
    return false -- An all-class mask is not a class quest.
end
function P.ClassQuestPlan()
    local level=P.Safe(UnitLevel,'player') or 1
    local r={rows={},level=level,lastLevel=math.min(60,level+10),examined=0}
    if not P.char or P.char.class~=P.actualClass then r.message='Select your actual class to plan class quests.';return r end
    if not P.baselineProvider then r.message='Enable a compatible QuestieDB for class-quest planning. No class chain is invented from the gear sample.';return r end
    if P.Safe(InCombatLockdown) then r.message='Class quest checks deferred until combat ends.';return r end
    local observations={}
    local function state(id) if not observations[id] then observations[id]=P.QuestObservation(id) end;return observations[id] end
    local function resolve(id,path,depth)
        if depth>40 or path[id] then return nil,'Prerequisite cycle or depth limit; inspect the chain.' end
        path[id]=true
        local q=P.GetBaselineQuest(id)
        if not q then return nil,'Prerequisite missing from QuestieDB.' end
        if state(id).completed==true then return nil,'Completed' end
        if not P.BaselineQuestMatches(id) then return nil,'Race/class/faction restriction.' end
        local blocked=P.KnownQuestBlock(id);if blocked then return nil,blocked end
        if state(id).active==true then return q,'In quest log' end
        if state(id).error then return q,'Quest state unknown; check log/giver.' end
        for _,pre in ipairs(type(q.preQuestGroup)=='table' and q.preQuestGroup or {}) do
            if type(pre)~='number' or pre<=0 then return nil,'Unresolved prerequisite encoding.' end
            if state(pre).completed~=true then return resolve(pre,path,depth+1) end
        end
        local alternatives=type(q.preQuestSingle)=='table' and q.preQuestSingle or {}
        if #alternatives>0 then
            local fulfilled=false
            for _,pre in ipairs(alternatives) do if type(pre)=='number' and pre>0 and state(pre).completed==true then fulfilled=true end end
            if not fulfilled then
                local candidates={};local notes={}
                for _,pre in ipairs(alternatives) do
                    if type(pre)=='number' and pre>0 then
                        local copy={};for key in pairs(path) do copy[key]=true end
                        local nextQuest,note=resolve(pre,copy,depth+1)
                        if nextQuest then candidates[#candidates+1]={q=nextQuest,note=note} else notes[#notes+1]=note end
                    end
                end
                table.sort(candidates,function(a,b)
                    if state(a.q.id).active~=state(b.q.id).active then return state(a.q.id).active==true end
                    local la,lb=a.q.requiredLevel or 999,b.q.requiredLevel or 999
                    if la~=lb then return la<lb end;return a.q.id<b.q.id
                end)
                if candidates[1] then return candidates[1].q,candidates[1].note..' | alternative prerequisite; verify branch.' end
                return nil,notes[1] or 'No resolved alternative prerequisite.'
            end
        end
        return q,'Check quest giver; availability not confirmed.'
    end
    local grouped={}
    for id,q in pairs(P.baselineQuests) do
        if P.IsClassQuest(q) and P.BaselineQuestMatches(id) and type(q.requiredLevel)=='number' and q.requiredLevel<=r.lastLevel and state(id).completed~=true then
            r.examined=r.examined+1
            local nextQuest,note=resolve(id,{},0)
            if nextQuest then
                local min=nextQuest.requiredLevel
                if type(min)=='number' and min<=r.lastLevel then
                    local row=grouped[nextQuest.id]
                    if not row then
                        row={quest=nextQuest,status=note,min=min,active=state(nextQuest.id).active==true,goals=0,kind=min>level and 'UPCOMING' or state(nextQuest.id).active==true and 'CONTINUE CLASS QUEST' or 'CHECK CLASS QUEST'}
                        grouped[nextQuest.id]=row;r.rows[#r.rows+1]=row
                    end
                    row.goals=row.goals+1
                end
            else r.unresolved=(r.unresolved or 0)+1 end
        end
    end
    table.sort(r.rows,function(a,b)
        if (a.min>level)~=(b.min>level) then return a.min<=level end
        if a.active~=b.active then return a.active end
        if a.min~=b.min then return a.min<b.min end
        return a.quest.id<b.quest.id
    end)
    if (P.baselineIndex or 0)<#(P.baselineIDs or {}) then r.message='QuestieDB is still indexing; class-quest coverage is partial.' end
    return r
end
function P.ClassQuestLines(brief)
    local r=P.ClassQuestPlan();local lines={'CLASS PROGRESSION | '..(P.actualClass or 'Unknown')..' | through level '..r.lastLevel}
    if r.message then lines[#lines+1]=r.message end
    for i,row in ipairs(r.rows) do if i<=(brief and 3 or 20) then
        lines[#lines+1]=row.kind..': '..row.quest.name..' ['..row.quest.id..'] | minimum level '..row.min
        if not brief then
            lines[#lines+1]=row.status..' | '..row.goals..' class-chain record(s) lead here.'
            local objectives=row.quest.objectivesText
            if type(objectives)=='table' and type(objectives[1])=='string' then lines[#lines+1]=objectives[1]:gsub('|','||') end
            if row.quest.chainIncomplete then lines[#lines+1]='Additional spell, skill, reputation or access requirements need inspection.' end
        end
    end end
    if #r.rows==0 and not r.message then lines[#lines+1]='No unresolved class-chain step resolved in this window. This does not certify every class unlock as complete.' end
    lines[#lines+1]='Class-restricted/category chains are reviewed before optional gear detours. Questie does not expose reward-spell guarantees here: inspect the reward for forms, pets, totems, abilities or mounts.'
    if not brief then
        lines[#lines+1]='Solo/Group difficulty is not supplied by this contract. A class quest is not automatically safe solo; check objectives and arrange help for elites or dungeons.'
        lines[#lines+1]='Completed steps and known exclusions are removed. Prerequisite branches are checked, not assumed offered. Unknown races, gates and source changes can still affect eligibility.'
        lines[#lines+1]='Unresolved chains: '..(r.unresolved or 0)..'. Source: installed QuestieDB contract 4. Class/spec previews do not replace the actual player class.'
        lines[#lines+1]='Track top upgrade on this page pins the first class quest. More quests can be pinned by ID with /rfp classquest ID.'
    end
    return lines
end
function P.PinClassQuest(id)
    if not P.profile then return false end
    for _,row in ipairs(P.ClassQuestPlan().rows) do if row.quest.id==id then
        P.profile.trackedQuests[tostring(id)]=true;P.UIOptions().tracker=true;P.UpdateControls();return true
    end end
    return false
end
