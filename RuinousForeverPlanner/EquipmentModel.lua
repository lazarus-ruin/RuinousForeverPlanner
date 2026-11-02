local _,P=...
function P.SlotMatches(slot,d)
    local loc=d and d.equipLoc
    local types={
        [1]={INVTYPE_HEAD=true},[2]={INVTYPE_NECK=true},[3]={INVTYPE_SHOULDER=true},[5]={INVTYPE_CHEST=true,INVTYPE_ROBE=true},[6]={INVTYPE_WAIST=true},[7]={INVTYPE_LEGS=true},[8]={INVTYPE_FEET=true},[9]={INVTYPE_WRIST=true},[10]={INVTYPE_HAND=true},[11]={INVTYPE_FINGER=true},[12]={INVTYPE_FINGER=true},[13]={INVTYPE_TRINKET=true},[14]={INVTYPE_TRINKET=true},[15]={INVTYPE_CLOAK=true},
        [16]={INVTYPE_WEAPON=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_2HWEAPON=true},[17]={INVTYPE_HOLDABLE=true,INVTYPE_SHIELD=true,INVTYPE_WEAPON=true,INVTYPE_WEAPONOFFHAND=true},[18]={INVTYPE_RANGED=true,INVTYPE_RANGEDRIGHT=true,INVTYPE_THROWN=true,INVTYPE_RELIC=true}}
    return loc and types[slot] and types[slot][loc] or false
end
function P.CompareEquipment(slot,details,scorer,partner,snapshot)
    scorer=scorer or P.WeightedStatScore
    local snap=snapshot or P.snapshot
    if not snap or P.scanStale or P.deferred or #snap.errors>0 then return nil,'Refresh equipped gear' end
    if not P.SlotMatches(slot,details) then return nil,'Equipment slot / item type mismatch' end
    if slot~=16 and slot~=17 then
        local worn=snap.equipped[slot]
        local before=not worn and 0 or worn.details and scorer(worn.details.stats)
        local after=scorer(details.stats)
        if before==nil or after==nil then return nil,'Comparable numeric stats pending / enchant effect unscored' end
        return {before=before,after=after,slot=slot,empty=not worn}
    end
    local main,off=snap.equipped[16],snap.equipped[17]
    if not main or not main.details or not P.SlotMatches(16,main.details) then return nil,'Main-hand details are required to compare the weapon set' end
    local two=main.details.equipLoc=='INVTYPE_2HWEAPON'
    if two and off then return nil,'Inconsistent two-hand / off-hand scan; rescan gear' end
    if slot==17 and two and not partner then return nil,'Pair this off hand with a one-hand weapon; it cannot accompany your two-hander' end
    local before=scorer(main.details.stats)
    local oldOff=0;if off then oldOff=off.details and scorer(off.details.stats) end
    if before==nil or oldOff==nil then return nil,'Equipped weapon-set stats / enchant effect unavailable' end
    before=before+oldOff
    local after=scorer(details.stats);local buddy
    if slot==17 then
        buddy=partner and partner.details or main.details
        if not P.SlotMatches(16,buddy) or buddy.equipLoc=='INVTYPE_2HWEAPON' then return nil,'Off-hand pairing requires a one-hand main weapon' end
    elseif details.equipLoc~='INVTYPE_2HWEAPON' then buddy=partner and partner.details or off and off.details end
    if slot==16 and buddy and not P.SlotMatches(17,buddy) then return nil,'Off-hand partner type is not compatible with that slot' end
    local value=buddy and scorer(buddy.stats) or 0
    if after==nil or value==nil then return nil,'Candidate weapon-set stats / enchant effect unavailable' end
    return {before=before,after=after+value,slot=slot,hands=true,removesOffHand=slot==16 and details.equipLoc=='INVTYPE_2HWEAPON' and off~=nil,partner=partner,leavesOffHandEmpty=slot==16 and details.equipLoc~='INVTYPE_2HWEAPON' and not buddy}
end
function P.HandBenchmark(candidates,scorer,detailsFor,level,withEnchant,windowStart)
    local mains,offs={},{};local best
    for _,g in ipairs(candidates) do if g.slot==16 or g.slot==17 then
        if level>=g.min and (windowStart or level)<=g.max and g.confirmed~=false and not g.randomSuffix and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) then
            local d=detailsFor(g)
            if d and P.SlotMatches(g.slot,d) and type(d.minLevel)=='number' and d.minLevel<=level then
                local stats,enchant=d.stats
                if withEnchant then stats,enchant=P.BenchmarkStats(d,g.slot) end
                local value=scorer(stats)
                if value and value>=0 then
                    local entry={item=g,details=d,value=value,enchant=enchant}
                    if g.slot==16 then mains[#mains+1]=entry else offs[#offs+1]=entry end
                end
            end
        end
    end end
    for _,main in ipairs(mains) do
        if main.details.equipLoc=='INVTYPE_2HWEAPON' then
            if main.value>0 and (not best or main.value>best.value) then best={main=main,value=main.value,twoHanded=true} end
        else
            for _,off in ipairs(offs) do if off.item.id~=main.item.id then
                local value=main.value+off.value
                if value>0 and (not best or value>best.value) then best={main=main,off=off,value=value,twoHanded=false} end
            end end
        end
    end
    return best
end
