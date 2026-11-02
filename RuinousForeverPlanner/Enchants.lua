local _,P=...
local function finite(v)return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function plain(v)return not (type(issecretvalue)=='function' and issecretvalue(v))end
local function copy(stats)
    if type(stats)~='table' then return end
    local result={}
    local valid=true
    local ok=pcall(function() for k,v in pairs(stats) do
        if not plain(k) or not plain(v) or type(k)~='string' or not finite(v) then valid=false;return end
        result[k]=v
    end end)
    if not ok or not valid then return end
    return result
end
function P.AddStats(a,b)
    local r=copy(a);if not r then return end
    for k,v in pairs(b or {}) do if not finite(v) then return end;r[k]=(r[k] or 0)+v end
    return r
end
local labels={strength='ITEM_MOD_STRENGTH_SHORT',agility='ITEM_MOD_AGILITY_SHORT',stamina='ITEM_MOD_STAMINA_SHORT',intellect='ITEM_MOD_INTELLECT_SHORT',spirit='ITEM_MOD_SPIRIT_SHORT',armor='RESISTANCE0_NAME',health='ITEM_MOD_HEALTH_SHORT',mana='ITEM_MOD_MANA_SHORT',
    ['spell power']='ITEM_MOD_SPELL_POWER_SHORT',['healing spells']='ITEM_MOD_SPELL_HEALING_DONE_SHORT',['healing']='ITEM_MOD_SPELL_HEALING_DONE_SHORT',['damage spells']='ITEM_MOD_SPELL_DAMAGE_DONE_SHORT',['spell damage']='ITEM_MOD_SPELL_DAMAGE_DONE_SHORT',['attack power']='ITEM_MOD_ATTACK_POWER_SHORT',['ranged attack power']='ITEM_MOD_RANGED_ATTACK_POWER_SHORT'}
function P.ParseEnchantStats(text)
    if not plain(text) or type(text)~='string' then return end
    local s=text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):lower():gsub('^enchanted:%s*',''):gsub('^enchant:%s*',''):gsub('^%s+',''):gsub('%s+$','')
    local all=tonumber(s:match('^%+(%d+) all stats$') or s:match('^all stats %+(%d+)$'))
    if all then return {ITEM_MOD_STRENGTH_SHORT=all,ITEM_MOD_AGILITY_SHORT=all,ITEM_MOD_STAMINA_SHORT=all,ITEM_MOD_INTELLECT_SHORT=all,ITEM_MOD_SPIRIT_SHORT=all} end
    local regen=tonumber(s:match('^mana regen (%d+) per 5 sec%.$') or s:match('^%+(%d+) mana every 5 sec%.$') or s:match('^%+(%d+) mana per 5 sec%.$'))
    if regen then return {ITEM_MOD_MANA_REGENERATION_SHORT=regen} end
    s=s:gsub(' and ', ','):gsub('/',',')
    local result={};local count=0
    for part in s:gmatch('[^,]+') do
        part=part:gsub('^%s+',''):gsub('%s+$','')
        local label,n=part:match('^(.-) %+(%d+)$')
        if not n then n,label=part:match('^%+(%d+) (.-)$') end
        local key=label and labels[label]
        if not key or not tonumber(n) then return end
        result[key]=(result[key] or 0)+tonumber(n);count=count+1
    end
    if count>0 then return result end
end
function P.EnchantLink(link)
    if not plain(link) or type(link)~='string' then return end
    local id,field=link:match('item:(%d+):([^:|]*)')
    if not id then return end
    local enchant=field=='' and 0 or tonumber(field)
    if not finite(enchant) or enchant<0 or enchant~=math.floor(enchant) then return end
    -- Replace only the permanent enchant field. Suffixes, gems and every other field survive.
    local stripped=link:gsub('(item:%d+:)[^:|]*','%10',1)
    return enchant,stripped
end
local function tooltipEnchant(link)
    local locale=P.Safe(GetLocale)
    if locale~='enUS' and locale~='enGB' then return nil,'English enchant text parser unavailable for this locale' end
    local kind=Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
    if not kind or not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink)~='function' then return nil,'Permanent-enchant tooltip API unavailable' end
    local data=P.Safe(C_TooltipInfo.GetHyperlink,link)
    if type(data)~='table' or type(data.lines)~='table' then return nil,'Enchant tooltip data pending' end
    local stats={};local found=false
    for _,line in ipairs(data.lines) do
        if type(line)=='table' and plain(line.type) and line.type==kind then
            local parsed=P.ParseEnchantStats(line.leftText)
            if not parsed then return nil,'Proc / utility / unrecognized enchant effect' end
            stats=P.AddStats(stats,parsed);found=true
        end
    end
    if found then return stats end
    return nil,'Permanent-enchant line unavailable'
end
function P.ResolveEnchantDetails(d)
    if not d or not d.link then return d end
    local id,stripped=P.EnchantLink(d.link)
    d.enchant={id=id,status=id==0 and 'none' or 'unknown'}
    if id==nil or id==0 then d.baseStats=copy(d.stats);return d end
    local base=copy(P.Safe(C_Item and C_Item.GetItemStats,stripped))
    local exact=copy(d.stats)
    d.baseStats=base
    if not base or not exact then d.stats=nil;d.statsError='Enchant/base stats pending';d.enchant.reason=d.statsError;return d end
    local delta={};local changed=false
    for k,v in pairs(exact) do delta[k]=v-(base[k] or 0);if delta[k]~=0 then changed=true end end
    for k,v in pairs(base) do if exact[k]==nil then delta[k]=-v;if v~=0 then changed=true end end end
    if changed then
        -- Some clients include enchant stats. Keep that total verbatim; never add it twice.
        d.stats=exact;d.enchant.stats=delta;d.enchant.status='counted';d.enchant.method='API link difference'
        local supported={};for _,field in ipairs(P.UpgradeStats or {}) do supported[field[1]]=true end
        for key,value in pairs(delta) do if value~=0 and not supported[key] then d.enchant.status='partial';d.enchant.reason='Some enchant stats have no model weight' end end
    else
        local addition,reason=tooltipEnchant(d.link)
        if addition then d.stats=P.AddStats(base,addition);d.enchant.stats=addition;d.enchant.status='counted';d.enchant.method='permanent tooltip + unenchanted base'
        else d.stats=base;d.enchant.status='unscored';d.enchant.reason=reason end
    end
    return d
end
function P.EnchantGroup(slot,details)
    local loc=details and details.equipLoc
    if slot==16 then return loc=='INVTYPE_2HWEAPON' and '2H Weapon' or 'Weapon' end
    if slot==17 then return loc=='INVTYPE_SHIELD' and 'Shield' or loc=='INVTYPE_HOLDABLE' and 'Off-Hand' or 'Weapon' end
    if slot==18 then return nil end -- Wands / relics need item-subtype rules absent from this catalogue.
    return ({[2]='Necklace',[5]='Chest',[8]='Boots',[9]='Bracer',[10]='Gloves',[15]='Cloak'})[slot]
end
function P.EnchantBenchmarks(slot,details)
    local rows={};local info=P.ProfileInfo();local group=P.EnchantGroup(slot,details)
    local level=P.Safe(UnitLevel,'player') or 0
    if not group or not info or level~=P.EnchantData.referenceLevel then return rows end
    for _,e in ipairs(P.EnchantData.enchants) do
        if e.group==group or group=='2H Weapon' and e.group=='Weapon' then
            for _,path in ipairs(e.profiles) do if path==info.path then rows[#rows+1]=e;break end end
        end
    end
    return rows
end
function P.BenchmarkStats(details,slot)
    if not details then return end
    local base=details.baseStats or details.stats
    local best,bestValue
    for _,e in ipairs(P.EnchantBenchmarks(slot,details)) do
        local value=e.stats and P.WeightedStatScore(e.stats)
        if value and value>0 and (not bestValue or value>bestValue) then best=e;bestValue=value end
    end
    return best and P.AddStats(base,best.stats) or base,best
end
function P.EnchantReport(snapshot)
    snapshot=snapshot or P.snapshot
    local r={rows={},applied=0,missing=0,unknown=0,scored=0,unscored=0}
    for _,slot in ipairs(P.slotOrder) do
        local worn=snapshot and snapshot.equipped[slot]
        local d=worn and worn.details
        if d and (P.EnchantGroup(slot,d) or d.enchant and d.enchant.id and d.enchant.id>0) then
            local e=d.enchant or {};local row={slot=slot,label=P.slotNames[slot],status=e.status or 'unknown',id=e.id,reason=e.reason}
            if e.id and e.id>0 then r.applied=r.applied+1 elseif e.id==0 then r.missing=r.missing+1 else r.unknown=r.unknown+1 end
            if e.status=='counted' then r.scored=r.scored+1 end
            if e.id and e.id>0 and e.status~='counted' then r.unscored=r.unscored+1 end
            row.targets=P.EnchantBenchmarks(slot,d)
            row.score=e.stats and P.WeightedStatScore(e.stats)
            r.rows[#r.rows+1]=row
        end
    end
    return r
end
function P.EnchantLines(brief)
    local r=P.EnchantReport()
    local lines={string.format('Enchants: %d applied (%d counted, %d effects unscored), %d missing, %d unknown',r.applied,r.scored,r.unscored,r.missing,r.unknown)}
    if not brief then for _,row in ipairs(r.rows) do
        lines[#lines+1]=row.label..': '..(row.status=='none' and 'No permanent enchant' or row.status=='counted' and 'Enchant '..row.id..' counted in stats' or 'Enchant effect / status unknown: '..(row.reason or 'rescan item data'))
        for _,target in ipairs(row.targets) do lines[#lines+1]='Published level-30 option: '..target.name..' | Enchanting '..target.skill..' | '..(target.stats and 'static stats modeled' or 'utility/proc not modeled')..'. Verify item restrictions and price with an enchanter.' end
    end end
    lines[#lines+1]='Proc, utility, temporary weapon buffs and unsupported stats are not a combat simulation. Enchant targets are partial level-30 source references.'
    return lines
end

function P.PinEnchantGoal(recommendation)
    if not P.profile or not recommendation or not recommendation.enchant then return false end
    if type(P.profile.enchantGoals)~='table' then P.profile.enchantGoals={} end
    local slot=recommendation.enchantSlot or recommendation.slot
    P.profile.enchantGoals[tostring(slot)]={name=recommendation.enchant.name,stats=recommendation.enchant.stats,slot=slot}
    P.UpdateControls();return true
end
function P.EnchantGoalLines()
    local lines={}
    for _,slot in ipairs(P.slotOrder) do
        local goal=P.profile and P.profile.enchantGoals and P.profile.enchantGoals[tostring(slot)]
        if goal then
            local worn=P.snapshot and P.snapshot.equipped[slot];local enchant=worn and worn.details and worn.details.enchant
            local matched=enchant and enchant.status=='counted' and type(goal.stats)=='table'
            if matched then for key,value in pairs(goal.stats) do if not enchant.stats or (enchant.stats[key] or 0)<value then matched=false;break end end end
            lines[#lines+1]='[Enchant] '..P.slotNames[slot]..': '..goal.name
            lines[#lines+1]=matched and 'Target static enchant stats present.' or 'Review enchant / restrictions with an enchanter; rescan after applying.'
        end
    end
    return lines
end
