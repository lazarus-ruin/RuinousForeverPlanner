local _,P=...
local names={MAGE='Mage',PRIEST='Priest',DRUID='Druid',WARRIOR='Warrior',ROGUE='Rogue',HUNTER='Hunter',WARLOCK='Warlock',PALADIN='Paladin',SHAMAN='Shaman'}
function P.ClassLevelNotes(level)
    level=level or P.Safe(UnitLevel,'player') or 1
    if not P.char then return {} end
    local name=names[P.char.class] or P.char.class
    local priorities={
        MAGE='Compare spell power, Intellect and useful Stamina; keep an effective damage weapon or wand and enough recovery supplies.',
        PRIEST='Use your selected healing or damage role weights; compare a weapon and off hand as a complete set.',
        DRUID='Compare gear for your selected caster, healing or feral role. Feral form damage is not inferred from weapon base DPS.',
        WARRIOR='Inspect weapon damage and the complete weapon/shield set first; compare Strength and useful Stamina.',
        ROGUE='Inspect your main/off-hand combination and weapon training; compare Agility and attack stats.',
        HUNTER='Inspect the ranged weapon and useful Agility; compare melee stat items separately from ranged damage.',
        WARLOCK='Compare spell power, Intellect and useful Stamina; keep recovery supplies and a usable damage weapon or wand.',
        PALADIN='Compare your selected damage, tank or healing role; inspect the whole weapon/shield combination.',
        SHAMAN='Compare your selected spell, melee or healing role; inspect the whole weapon/off-hand combination.'}
    return {name..' level '..level..' planning: '..(priorities[P.char.class] or 'Use class-appropriate gear and training.'),
        'Review useful training when visiting a trainer. Batch local quests and save gold for skills and affordable upgrades; do not travel or farm just to fill a reference list.',
        'These are planning heuristics. Actual item requirements, upgrades and quest availability need client/source evidence.'}
end
function P.UpcomingTargets(level)
    local rows={};if not P.char or not P.ProfileSupported() then return rows end
    local hi=math.min(60,level+10)
    for _,g in ipairs(P.ProfileCandidates()) do
        if g.confirmed~=false and not g.randomSuffix and g.sourceMinLevel and g.min>level and g.min<=hi and g.min<=g.max
            and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) and not P.profile.skipped[tostring(g.id)] then rows[#rows+1]=g end
    end
    table.sort(rows,function(a,b) if a.min~=b.min then return a.min<b.min end if a.slot~=b.slot then return a.slot<b.slot end return a.id<b.id end)
    return rows
end
function P.UpcomingTargetLines(level)
    local rows=P.UpcomingTargets(level)
    local lines={'UPCOMING '..(names[P.char.class] or P.char.class):upper()..' REFERENCES | next 10 levels | future only'}
    for i,g in ipairs(rows) do if i<=6 then lines[#lines+1]='Level '..g.min..': '..g.name..' | '..g.mode..' | '..g.acquire end end
    if #rows==0 then lines[#lines+1]='No source-backed upcoming targets resolved for this profile. Use the local quest/stage plan; gear coverage is incomplete.' end
    lines[#lines+1]='These are future source references, not wearable-now or proven upgrade claims.'
    return lines
end
function P.StageTitle(stage)
    if stage and stage.min==26 and P.char and P.char.class~='PRIEST' then return 'Review class gear and dungeon readiness' end
    return stage and stage.title or ''
end
