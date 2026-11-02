local _,P=...
-- User-editable heuristic weights, NOT simulated healing/DPS or Forever class theorycraft.
P.UpgradeStats={
 {'ITEM_MOD_INTELLECT_SHORT','Intellect',1},{'ITEM_MOD_SPIRIT_SHORT','Spirit',.8},
 {'ITEM_MOD_STAMINA_SHORT','Stamina',.2},{'ITEM_MOD_SPELL_HEALING_DONE_SHORT','Healing',1.2},
 {'ITEM_MOD_SPELL_POWER_SHORT','Spell power',1.2},{'ITEM_MOD_MANA_REGENERATION_SHORT','Mana / 5 sec',2},
 {'ITEM_MOD_STRENGTH_SHORT','Strength',0},{'ITEM_MOD_AGILITY_SHORT','Agility',0},
 {'ITEM_MOD_ATTACK_POWER_SHORT','Attack power',0},{'ITEM_MOD_RANGED_ATTACK_POWER_SHORT','Ranged AP',0},
 {'RESISTANCE0_NAME','Armor',0},{'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT','Spell damage',0},
 {'ITEM_MOD_HEALTH_SHORT','Health',.02},{'ITEM_MOD_MANA_SHORT','Mana',.05}}
local presets={
 healer={1,.8,.2,1.2,1.2,2,0,0,0,0,0,0},
 caster={1,.3,.3,0,1.5,.5,0,0,0,0,0,1.5},
 strength={0,0,.4,0,0,0,2,1,1,0,0,0},
 agility={0,0,.4,0,0,0,.7,2,1,0,0,0},
 ranged={.2,0,.3,0,0,0,0,2,.5,1,0,0},
 tank={0,0,2,0,0,0,.8,.5,.2,0,.04,0},
 agilityTank={0,0,2,0,0,0,.4,1,.2,0,.04,0}}
function P.UpgradeWeights()
    if not P.profile then return end
    if type(P.profile.upgradeWeights)~='table' then P.profile.upgradeWeights={} end
    local w=P.profile.upgradeWeights; local defaults=presets[P.ProfileRole()] or presets.caster
    for i,s in ipairs(P.UpgradeStats) do
        if type(w[s[1]])~='number' or w[s[1]]<0 or w[s[1]]>20 or w[s[1]]~=w[s[1]] then w[s[1]]=defaults[i] or (i==13 and (P.ProfileRole()=='tank' and .2 or .02)) or (i==14 and ((P.ProfileRole()=='healer' or P.ProfileRole()=='caster') and .05 or 0)) or 0 end
    end
    return w
end
local function score(stats,w)
    if type(stats)~='table' or not next(stats) then return nil end
    local n=0
    for _,s in ipairs(P.UpgradeStats) do
        local v=stats[s[1]] or 0
        if type(v)~='number' or v~=v or v==math.huge or v==-math.huge then return nil end
        n=n+v*w[s[1]]
    end
    return n
end
function P.UpgradeEstimate(g)
    local function missing(reason) return {text='Upgrade estimate unavailable: '..reason} end
    if not g or not P.ProfileSupported() or P.char.class~=P.actualClass then return missing('select your actual class and a supported profile') end
    local level=P.Safe(UnitLevel,'player') or 0
    if level<g.min or level>g.max or (g.faction and g.faction~=P.Safe(UnitFactionGroup,'player')) then return missing('outside source level / faction coverage') end
    local snap=P.snapshot
    if not snap or #snap.errors>0 or P.deferred or P.scanStale then return missing('gear scan incomplete or deferred') end
    local old=snap.equipped[g.slot]
    if not old and g.slot~=17 then return missing('empty slot; percentage has no baseline') end
    if g.randomSuffix then return missing('random-suffix variant requires exact item comparison') end
    if g.confirmed==false then return missing('source item is not beta-confirmed') end
    local target=P.CandidateDetails(g)
    if not target or not P.SlotMatches(g.slot,target) then return missing('item details / matching slot pending') end
    if not target.minLevel or target.minLevel>level then return missing('client wear level unknown or too high') end
    local compared,reason=P.CompareEquipment(g.slot,target,P.WeightedStatScore)
    if not compared then return missing(reason) end
    local before,after=compared.before,compared.after
    if before<=0 then return missing('equipped weighted score is zero') end
    local percent=(after-before)/before*100
    return {percent=percent,before=before,after=after,hands=compared.hands,text=string.format(compared.hands and 'Est. weapon-set stat upgrade %+.1f%% (enchants counted where resolved)' or 'Est. stat upgrade %+.1f%%',percent)}
end

-- Avoid short-lived grinds only when a source-backed same-slot replacement has
-- actual comparable client stats. No inference across missing dataset brackets.
function P.ShortTermReplacement(g)
    local level=P.Safe(UnitLevel,'player') or 0
    if level>=55 or not g or level<g.min or level>g.max then return end
    if not P.ProfileSupported() or P.char.class~=P.actualClass then return end
    if g.mode~='group' and g.effort~='craft' then return end
    if g.slot==16 or g.slot==17 or g.slot==18 then return end
    if not P.snapshot or #P.snapshot.errors>0 or P.deferred or P.scanStale then return end
    local now=P.CandidateDetails(g)
    if not now or not now.minLevel or now.minLevel>level then return end
    local w=P.UpgradeWeights(); local baseline=score(now.stats,w)
    if not baseline or baseline<=0 then return end
    local best,bestScore
    for _,future in ipairs(P.TrackableGear()) do
        if future.slot==g.slot and future.id~=g.id and future.min>level and future.min<=level+3
            and not P.profile.skipped[tostring(future.id)]
            and (not future.faction or future.faction==P.Safe(UnitFactionGroup,'player')) then
            local details=P.CandidateDetails(future)
            if details and details.equipLoc==now.equipLoc and details.minLevel and details.minLevel<=future.min and future.min<=future.max then
                local value=score(details.stats,w)
                if value and value>baseline and (not bestScore or value>bestScore) then best,bestScore=future,value end
            end
        end
    end
    if best then return {item=best,level=best.min,text='Level to '..best.min..' first, then compare '..best.name..' instead of grinding '..g.name..'.',
        why='A supported same-slot candidate has a higher estimated weighted stat score within 3 levels. Save the dungeon/crafting effort; future availability and prerequisites still need checking.'} end
end

function P.UpgradeDisplay(estimate)
    if not estimate then return 'Upgrade estimate unavailable' end
    local text=estimate.text or 'Upgrade estimate unavailable'
    -- A sub-rounding difference is neutral, so +0.0% is never misleadingly green.
    if type(estimate.percent)=='number' and estimate.percent==estimate.percent then
        if estimate.percent>=.05 then return '|cff40e080'..text..'|r' end
        if estimate.percent<=-.05 then return '|cffff6060'..text..'|r' end
    end
    return text
end
