local _,P=...
P.questSnapshot={}
function P.RefreshQuests()
    if P.Safe(InCombatLockdown) then P.questDeferred=true; return end
    local nextSnapshot={}
    for _,q in ipairs(P.Data.quests or {}) do
        if not q.faction or q.faction==P.Safe(UnitFactionGroup,'player') then
            local completed,ce=P.Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,q.id)
            local active,ae=P.Safe(C_QuestLog and C_QuestLog.IsOnQuest,q.id)
            -- Missing or restricted flags must remain unknown, never boolean-coerced.
            nextSnapshot[q.id]={error=ce or ae}
            -- Assign boolean false explicitly; it differs from an unavailable flag.
            if type(completed)=='boolean' then nextSnapshot[q.id].completed=completed end
            if type(active)=='boolean' then nextSnapshot[q.id].active=active end
        end
    end
    P.questSnapshot=nextSnapshot; P.questDeferred=false
end
function P.QuestRecord(id)
    for _,q in ipairs(P.Data.quests or {}) do if q.id==id then return q end end
    return P.GetBaselineQuest and P.GetBaselineQuest(id) or P.SourceData and P.SourceData.quests[tostring(id)] or P.EfficiencyQuestRecord and P.EfficiencyQuestRecord(id)
end
function P.QuestStatus(id)
    local s=P.questSnapshot[id] or P.QuestObservation(id)
    if not s then return 'Unknown: no current quest observation' end
    if P.questDeferred then return 'Unknown: quest refresh deferred until out of combat' end
    if s.completed==true then return 'Completed (client completion flag)' end
    if s.active==true then return 'In quest log; turn-in readiness unknown' end
    if s.completed==false and s.active==false then return 'Not in log / not recorded complete; availability unknown' end
    return 'Unknown: quest API flags unavailable'
end
function P.QuestNext(id)
    local curated=false; for _,q in ipairs(P.Data.quests) do if q.id==id then curated=true end end
    if not curated and P.baselineProvider then return P.NextBaselineQuest(id) end
    if P.questDeferred then return nil,'unknown' end
    local final=P.questSnapshot[id] or P.QuestObservation(id)
    if final and final.completed then return nil,'completed' end
    local chain,seen={},{}
    local q=P.QuestRecord(id)
    while q and not seen[q.id] do
        seen[q.id]=true; table.insert(chain,1,q)
        q=q.previous~=0 and P.QuestRecord(q.previous) or nil
    end
    -- An accepted later step takes precedence over absent earlier flags.
    for i=#chain,1,-1 do local s=P.questSnapshot[chain[i].id] or P.QuestObservation(chain[i].id)
        if s and s.active and not s.completed then return chain[i],'active' end
    end
    local start=1
    for i=#chain,1,-1 do local s=P.questSnapshot[chain[i].id] or P.QuestObservation(chain[i].id)
        if s and s.completed==true then start=i+1; break end
    end
    for i=start,#chain do local node=chain[i]; local s=P.questSnapshot[node.id] or P.QuestObservation(node.id)
        if not s or s.completed~=true then return node,'check' end
    end
    return nil,'unknown'
end

function P.TrackableGear() return P.ProfileCandidates() end
function P.RewardQuestID(g)
    if g.questID then return g.questID end
    if g.questByFaction then return g.questByFaction[P.Safe(UnitFactionGroup,'player')] end
    for _,id in ipairs(g.questIDs or {}) do
        local q=P.QuestRecord(id)
        if q and (not q.faction or q.faction==P.Safe(UnitFactionGroup,'player')) and (not P.BaselineQuestMatches or P.BaselineQuestMatches(id)) then return id end
    end
end
function P.QuestChain(id)
    local chain,seen={},{}
    local q=P.QuestRecord(id)
    while q and not seen[q.id] do
        seen[q.id]=true; table.insert(chain,1,q)
        q=q.previous~=0 and P.QuestRecord(q.previous) or nil
    end
    return chain
end
function P.QuestRecommendations()
    local rows={}
    if not P.ProfileSupported() or P.char.class~=P.actualClass then return rows end
    local level=P.Safe(UnitLevel,'player') or 0
    for _,g in ipairs(P.TrackableGear()) do
        local id=P.RewardQuestID(g)
        if id and level>=g.min and level<=g.max and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) and not P.profile.skipped[tostring(g.id)] then
            local state=P.CandidateOwned(g)
            local q,status=P.QuestNext(id)
            if status~='completed' and status~='restricted' and not (P.KnownQuestBlock and P.KnownQuestBlock(id)) and state~='Equipped' and state~='In bags (not equipped)' then
                local est=P.UpgradeEstimate(g)
                -- Nonpositive measurable rewards do not displace better-equipped goals.
                if not est.percent or est.percent>0 then
                    local old=P.snapshot and P.snapshot.equipped[g.slot]
                    local reason='Compare against '..(old and (old.name or ('equipped item '..old.id)) or 'an empty / unknown equipped slot')..'. '..est.text
                    if state:find('Unknown',1,true) then reason=reason..'. Inventory incomplete: scan before acquiring.' end
                    if not est.percent then reason=reason..'. Candidate to inspect, not a proven upgrade.' end
                    if P.char.mode=='solo' and g.mode=='group' then reason=reason..'. Prepare solo; dungeon objective requires a party.' end
                    if q and q.chainIncomplete then reason=reason..'. Predecessor map incomplete; verify live quest text.' end
                    rows[#rows+1]={item=g,quest=q,questID=id,status=status,estimate=est,reason=reason,
                        nextText=q and (q.name..': '..q.summary..' | '..P.QuestStatus(q.id)) or 'Quest progress unknown; refresh quest observations'}
                end
            end
        end
    end
    table.sort(rows,function(a,b)
        local x,y=a.estimate.percent,b.estimate.percent
        if x~=nil and y~=nil and x~=y then return x>y end
        if (x~=nil)~=(y~=nil) then return x~=nil end
        if (a.status=='active')~=(b.status=='active') then return a.status=='active' end
        return a.item.id<b.item.id
    end)
    return rows
end
