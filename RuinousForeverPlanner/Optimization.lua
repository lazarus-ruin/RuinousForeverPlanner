local _,P=...
local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
function P.WeightedStatScore(stats)
    if type(stats)~='table' then return end
    local weights=P.UpgradeWeights(); if not weights then return end
    local total=0
    for _,field in ipairs(P.UpgradeStats) do
        local v=stats[field[1]] or 0
        if not finite(v) or not finite(weights[field[1]]) then return end
        total=total+v*weights[field[1]]
    end
    return finite(total) and total or nil
end
local function payload(link) return type(link)=='string' and (link:match('|H(item:[^|]+)|h') or link:match('^(item:[^|]+)$')) end
-- Full BiS is a separate, strict item+enchant certification, not a rounded stat score.
function P.CertifiedBiSSet(level)
    if not P.char or not P.snapshot or #P.snapshot.errors>0 or P.deferred or P.scanStale or P.char.class~=P.actualClass then return end
    for _,set in ipairs(P.Data.certifiedBiSSets or {}) do
        if set.verified==true and set.certification=='complete-bis-with-enchants' and type(set.source)=='string' and set.source:match('^https://')
            and set.level==level and set.class==P.char.class and set.spec==P.char.spec and set.context==P.char.context
            and (not set.faction or set.faction==P.Safe(UnitFactionGroup,'player')) then
            local valid=true;local required=0
            for _,slot in ipairs(P.slotOrder) do
                local skip=slot==17 and set.twoHanded==true
                if skip then
                    local main=P.snapshot.equipped[16]
                    if not main or not main.details or main.details.equipLoc~='INVTYPE_2HWEAPON' or P.snapshot.equipped[17] then valid=false end
                else
                    required=required+1
                    local goal=set.slots and (set.slots[tostring(slot)] or set.slots[slot])
                    local worn=P.snapshot.equipped[slot]
                    if not goal or not worn or worn.id~=goal.itemID or type(goal.enchantID)~='number' then valid=false
                    else
                        local itemPayload=payload(worn.link)
                        local field=itemPayload and itemPayload:match('^item:%d+:([^:]*):')
                        local enchant=field=='' and 0 or tonumber(field)
                        if enchant~=goal.enchantID then valid=false end
                        -- Ambiguous random suffixes require an exact variant payload in the certified dataset.
                        if goal.randomSuffix and (not goal.itemPayload or goal.itemPayload~=itemPayload) then valid=false end
                        if goal.itemPayload and goal.itemPayload~=itemPayload then valid=false end
                    end
                end
            end
            if valid and required>=16 then return set end
        end
    end
end
function P.OptimizationReport(snapshotOverride)
    local snapshot=snapshotOverride or P.snapshot
    local level=P.Safe(UnitLevel,'player') or 0
    local r={level=level,slots={},recommendations={},ratedSlots=0,totalSlots=#P.slotOrder,complete=false,fullBiS=false}
    if not P.char or not P.ProfileSupported() or P.char.class~=P.actualClass then r.unavailable='Select your character class and a supported profile.';return r end
    if not snapshot or #snapshot.errors>0 or P.deferred or P.scanStale or P.Safe(InCombatLockdown) then r.unavailable='Refresh equipped gear outside combat before calculating a rating.';return r end
    local info=P.ProfileInfo();local source=info and P.SourceData.listVariants[info.path]
    r.source=source and source.source;r.sourceLevel=source and tonumber(source.title:lower():match('level%s+(%d+)'));r.shared=info and info.shared or false
    r.enchants=P.EnchantReport(snapshot)
    local candidates=P.GearCandidates();local groups={}
    for _,g in ipairs(candidates) do
        if g.slot~=16 and g.slot~=17 and level>=g.min and level<=g.max and g.confirmed~=false and not g.randomSuffix and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) then
            local details=P.CandidateDetails(g)
            if P.SlotMatches(g.slot,details) and finite(details.minLevel) and details.minLevel<=level then
                local stats,enchant=P.BenchmarkStats(details,g.slot);local value=P.WeightedStatScore(stats)
                if value and value>0 then groups[g.slot]=groups[g.slot] or {};groups[g.slot][#groups[g.slot]+1]={item=g,value=value,enchant=enchant} end
            end
        end
    end
    local sum=0;local used={};local assigned={}
    for _,firstSlot in ipairs({11,13}) do
        local choices=groups[firstSlot] or {};table.sort(choices,function(a,b)if a.value~=b.value then return a.value>b.value end return a.item.id<b.item.id end)
        local a,b=choices[1],choices[2]
        if a and b then
            local first,second=snapshot.equipped[firstSlot],snapshot.equipped[firstSlot+1]
            local x=not first and 0 or first.details and P.WeightedStatScore(first.details.stats)
            local y=not second and 0 or second.details and P.WeightedStatScore(second.details.stats)
            if finite(x) and finite(y) then
                if math.min(1,x/b.value)+math.min(1,y/a.value)>math.min(1,x/a.value)+math.min(1,y/b.value) then assigned[firstSlot]=b;assigned[firstSlot+1]=a
                else assigned[firstSlot]=a;assigned[firstSlot+1]=b end
            end
        end
    end
    local hand=P.HandBenchmark(candidates,P.WeightedStatScore,P.CandidateDetails,level,true)
    local currentMain=snapshot.equipped[16]
    local two=currentMain and currentMain.details and currentMain.details.equipLoc=='INVTYPE_2HWEAPON'
    if two then r.totalSlots=r.totalSlots-1 end
    for _,slot in ipairs(P.slotOrder) do
        local row={slot=slot,label=P.slotNames[slot],weight=1}
        if slot==16 then
            row.label='Weapon set (main + off hand)';row.weight=two and 1 or 2
            if hand then
                local compared,reason=P.CompareEquipment(16,hand.main.details,P.WeightedStatScore,hand.off,snapshot)
                if compared then row.current=compared.before;row.best=hand.value;row.target=hand.main.item;row.hand=hand;row.ratio=math.min(1,row.current/row.best)
                else row.reason=reason end
            else row.reason='No complete comparable weapon-set benchmark at this level' end
        elseif slot==17 then row.reason=two and 'Not applicable: equipped two-hand weapon' or 'Counted with the weapon set; never added twice'
        else
            local groupSlot=(slot==12 and 11) or (slot==14 and 13) or slot
            local choices=groups[groupSlot] or {};table.sort(choices,function(a,b)if a.value~=b.value then return a.value>b.value end return a.item.id<b.item.id end)
            local best=assigned[slot]
            if not best then for _,entry in ipairs(choices) do if not used[groupSlot..':'..entry.item.id] then best=entry;break end end end
            if not best then row.reason='No comparable confirmed benchmark at this level'
            else
                used[groupSlot..':'..best.item.id]=true
                local worn=snapshot.equipped[slot]
                local value=not worn and 0 or worn.details and P.SlotMatches(slot,worn.details) and P.WeightedStatScore(worn.details.stats)
                if finite(value) and value>=0 then row.current=value;row.best=best.value;row.target=best.item;row.enchant=best.enchant;row.ratio=math.min(1,value/best.value);row.empty=not worn
                else row.reason='Equipped stats / enchant effect pending or unscored' end
            end
        end
        if row.ratio then r.ratedSlots=r.ratedSlots+row.weight;sum=sum+row.ratio*row.weight end
        r.slots[#r.slots+1]=row
    end
    if r.ratedSlots>0 then r.percent=100*sum/r.ratedSlots end
    r.complete=r.ratedSlots==r.totalSlots and r.enchants.unscored==0 and r.enchants.unknown==0
    for _,row in ipairs(r.slots) do if row.ratio and row.ratio<1 then
        local target=row.target;local owned=P.CandidateOwned(target);local enchant=row.enchant;local why=target.acquire;local kind
        local title
        if row.hand then
            local h=row.hand
            title='Compare weapon set: '..h.main.item.name..(h.off and (' + '..h.off.item.name) or ' (two-hand; replaces off hand)')..'.'
            why='Combined weighted stats include resolved enchants on both equipped hands. Weapon damage, procs and equip training still require inspection.'
            if owned=='Equipped' and h.off and P.CandidateOwned(h.off.item)~='Equipped' then target=h.off.item;owned=P.CandidateOwned(target) end
            enchant=h.main.enchant or h.off and h.off.enchant
        else
            local advice=P.ShortTermReplacement(row.target)
            title=advice and advice.text or owned=='In bags (not equipped)' and ('Inspect your carried '..target.name..' for '..row.label..'.') or ('Compare '..target.name..' for '..row.label..'.')
            why=advice and advice.why or why
        end
        if owned=='Equipped' and enchant then title='Review enchant: '..enchant.name..' for '..row.label..'.';why='Published level-30 reference; Enchanting '..enchant.skill..'. Confirm target restrictions and price. The reported gain is the complete slot/set gap.';kind='enchant' end
        local questID=P.RewardQuestID(target);local _,questStatus;if questID then _,questStatus=P.QuestNext(questID) end
        local resolved=questStatus=='completed' and owned~='In bags (not equipped)' and kind~='enchant'
        if not P.profile.skipped[tostring(target.id)] and not resolved and (owned~='Equipped' or kind=='enchant') then
            r.recommendations[#r.recommendations+1]={item=target,partner=row.hand and row.hand.off and (target.id==row.hand.off.item.id and row.hand.main.item or row.hand.off.item),slot=row.slot,gainPoints=100*(1-row.ratio)*row.weight/r.ratedSlots,title=title,why=why,kind=kind,enchant=enchant,enchantSlot=row.hand and enchant and ((enchant.group=='Off-Hand' or enchant.group=='Shield') and 17 or 16) or row.slot}
        end
    end end
    table.sort(r.recommendations,function(a,b)if a.gainPoints~=b.gainPoints then return a.gainPoints>b.gainPoints end return a.slot<b.slot end)
    local certified=not snapshotOverride and P.CertifiedBiSSet(level)
    if certified then
        r.fullBiS=true;r.complete=true;r.percent=100;r.totalSlots=#P.slotOrder-(certified.twoHanded and 1 or 0);r.ratedSlots=r.totalSlots;r.certifiedSource=certified.source;r.source=certified.source;r.sourceLevel=level;r.shared=false;r.recommendations={}
        for _,row in ipairs(r.slots) do row.certified=not (row.slot==17 and certified.twoHanded);row.ratio=nil;row.reason=row.certified and 'Matches certified item and enchant' or 'Not applicable: two-hand set' end
        if level==60 then r.easterEgg='100% BiS. Go outside and touch grass.' end
    end
    return r
end
function P.OptimizationSummary(r)
    r=r or P.OptimizationReport()
    if r.unavailable then return 'Gear rating unavailable: '..r.unavailable end
    if r.fullBiS then return '100% optimized - verified full BiS item and enchant set' end
    if not r.percent then return 'Gear rating unavailable - no comparable benchmark for level '..r.level end
    return string.format('Estimated gear rating: %.1f%% | %d/%d positions evaluated%s',r.percent,r.ratedSlots,r.totalSlots,r.complete and '' or ' | partial coverage')
end

function P.ProjectedItemRating(slot,details)
    if not P.snapshot or not details then return end
    local equipped={};for k,v in pairs(P.snapshot.equipped) do equipped[k]=v end
    equipped[slot]={id=tonumber((details.link or ''):match('item:(%d+)')),link=details.link,name=details.name,details=details}
    if slot==16 and details.equipLoc=='INVTYPE_2HWEAPON' then equipped[17]=nil end
    return P.OptimizationReport({equipped=equipped,errors={},bags=P.snapshot.bags})
end
