local _,P=...
function P.ViewLevel()
    return P.char and P.char.previewLevel or P.Safe(UnitLevel,'player') or 1
end
-- Qualitative policy: integer priorities order actions, not combat value or time estimates.
function P.Milestone()
    local current=P.Safe(UnitLevel,'player') or 1
    return math.max(current,P.char and P.char.targetLevel or current)
end
function P.AllTargets(level)
    if not P.ProfileSupported() then return {} end
    local list={}
    for _,g in ipairs(P.GearCandidates()) do if level>=g.min and level<=g.max and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) then list[#list+1]=g end end
    return list
end
function P.Coverage(level)
    local c={total=0,equipped=0,bagged=0,unknown=0,slots=0}
    local slots={}
    for _,g in ipairs(P.AllTargets(level)) do
        c.total=c.total+1; slots[g.slot]=true
        local state=P.CandidateOwned(g)
        if P.char.class~=P.actualClass then c.unknown=c.unknown+1
        elseif state=='Equipped' then c.equipped=c.equipped+1
        elseif state=='In bags (not equipped)' then c.bagged=c.bagged+1
        elseif state:find('Unknown',1,true) then c.unknown=c.unknown+1 end
    end
    for _ in pairs(slots) do c.slots=c.slots+1 end
    return c
end
function P.Gate(id,state)
    if not P.profile or (state~='ready' and state~='blocked' and state~='unknown') then return false end
    for _,g in ipairs(P.TrackableGear()) do if g.id==id then P.profile.gates[tostring(id)]=state; return true end end
    return false
end
function P.Skip(id)
    if P.profile then P.profile.skipped[tostring(id)]=not P.profile.skipped[tostring(id)] end
end
function P.Plan()
    local list={}
    if not P.char or not P.profile then return list end
    local level=P.Safe(UnitLevel,'player') or 1
    local seen={}
    local function add(id,title,why,priority,kind,g)
        list[#list+1]={id=id,title=title,why=why,priority=priority,kind=kind,item=g}
    end
    if P.actualClass~=P.char.class then
        add('mismatch','Choose your character class to personalize owned-gear planning.','Another-class preview cannot infer item usability or readiness.',1,'unknown')
        return list
    end
    local function consider(g,future)
        if seen[g.id] then return end
        seen[g.id]=true
        if g.confirmed==false then add('verify-'..g.id,'Verify '..g.name..' before planning acquisition.','The source does not confirm this item in beta.',85,'unknown',g); return end
        local state=P.CandidateOwned(g)
        if state=='Equipped' then return end
        if state=='In bags (not equipped)' then
            add('owned-'..g.id,'Inspect your carried '..g.name..' before acquiring another.',
                'Already owned; compare with equipped gear and check wear/crafting restrictions. No automatic equip.',10,'owned',g)
            return
        end
        if state:find('Unknown',1,true) then
            add('unknown-'..g.id,'Refresh incomplete inventory before planning '..g.name..'.',state,5,'unknown',g); return
        end
        if P.profile.skipped[tostring(g.id)] then return end
        local replacement=P.ShortTermReplacement and P.ShortTermReplacement(g)
        if replacement and not future then
            add('level-first-'..g.id,replacement.text,replacement.why,22,'levelFirst',g); return
        end
        local clientInfo=P.ItemDetails and P.ItemDetails(g.id)
        if clientInfo and clientInfo.minLevel and clientInfo.minLevel>g.max then
            add('conflict-'..g.id,'Verify conflicting requirements for '..g.name..'.',
                'Cached client required level '..clientInfo.minLevel..' exceeds the local source window ending at '..g.max..'. This record cannot support a current or future upgrade recommendation; verify the source and client tooltip.',5,'unknown',g)
            return
        end
        if g.questID and P.QuestNext then
            local nextQuest,status=P.QuestNext(g.questID)
            if status=='completed' then
                add('completed-'..g.id,'Quest reward already resolved: '..g.name..'.',
                    'Client marks quest '..g.questID..' completed, but this item is not in carried gear. Check reward choice or storage; do not repeat-farm the one-time quest.',75,'completed',g)
                return
            elseif nextQuest and nextQuest.id~=g.questID then
                add('quest-'..g.id,'Prepare '..g.name..': '..nextQuest.summary..'.',
                    P.QuestStatus(nextQuest.id)..'. Source-linked prerequisite step '..nextQuest.id..'; check the live quest giver before travel. Eligibility and difficulty remain unknown.',40,'preparation',g)
                return
            end
        end
        local gate=P.profile.gates[tostring(g.id)] or 'unknown'
        if gate=='blocked' then
            add('blocked-'..g.id,'Resolve prerequisites for '..g.name..'.',g.acquire..' Readiness is manually marked blocked.',80,'blocked',g); return
        end
        local nearEnd=level>=29 and g.min<27
        local reason='Exact target not in carried gear. '..g.acquire
        if clientInfo and clientInfo.minLevel and clientInfo.minLevel>level then
            future=true
            reason='Cached client required level '..clientInfo.minLevel..' is above your live level. '..reason
        end
        if future then reason='Future-level preparation; not a current wearable recommendation. '..reason end
        if gate=='unknown' then reason=reason..' Eligibility/readiness unknown: confirm live prerequisites first.' end
        local priority=future and 55 or 35
        if nearEnd then priority=priority+25; reason=reason..' Sample ends at 30: defer expensive short-lived farming.' end
        if P.snapshot and #P.snapshot.errors==0 and not P.snapshot.equipped[g.slot] and not future then
            priority=25; reason=reason..' The comparison slot is empty; a suitable item deserves inspection.'
        else reason=reason..' Relative upgrade value and acquisition time are unknown.' end
        if g.mode=='group' and P.char.mode=='solo' then
            add('prepare-'..g.id,'Prepare for a future group: '..g.name..'.',reason,priority+5,'preparation',g)
        else
            add('target-'..g.id,(future and 'Prepare: ' or 'Compare candidate: ')..g.name..'.',reason,priority,g.mode,g)
        end
    end
    for _,g in ipairs(P.AllTargets(level)) do consider(g,false) end
    for _,g in ipairs(P.AllTargets(P.Milestone())) do consider(g,g.min>level) end
    if #list==0 and P.SourceData then
        local stage=P.Stage(level)
        add('leveling','Continue leveling with nearby quests.',stage and stage.tasks[1].text or 'Review your quest log and unlocked activities.',90,'leveling')
    end
    table.sort(list,function(a,b) if a.priority==b.priority then return a.id<b.id end return a.priority<b.priority end)
    return list
end
function P.GroupGoals()
    local goals={}
    for _,a in ipairs(P.Plan()) do
        if a.item and a.item.mode=='group' and a.kind~='owned' and a.kind~='unknown' and a.kind~='completed' and a.kind~='levelFirst' then goals[#goals+1]=a end
    end
    return goals
end
function P.RecordCoverage()
    if not P.profile or not P.snapshot then return end
    local level=P.Safe(UnitLevel,'player') or 0
    local c=P.Coverage(level)
    local record={level=level,equipped=c.equipped,bagged=c.bagged,total=c.total,unknown=c.unknown,version=P.Data.version}
    local h=P.profile.history; local prev=h[#h]
    if prev and prev.level==record.level and prev.equipped==record.equipped and prev.bagged==record.bagged and prev.total==record.total and prev.unknown==record.unknown and prev.version==record.version then return end
    h[#h+1]=record
    while #h>60 do table.remove(h,1) end
end
