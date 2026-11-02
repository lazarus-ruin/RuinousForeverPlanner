local _,P=...
local tooltip
local slotMap={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},
    INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},
    INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16,17},
    INVTYPE_WEAPONMAINHAND={16},INVTYPE_WEAPONOFFHAND={17},INVTYPE_2HWEAPON={16},INVTYPE_HOLDABLE={17},
    INVTYPE_SHIELD={17},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18},INVTYPE_RELIC={18}}
local labels={ITEM_MOD_INTELLECT_SHORT='Intellect',ITEM_MOD_STAMINA_SHORT='Stamina',ITEM_MOD_SPIRIT_SHORT='Spirit',
    ITEM_MOD_AGILITY_SHORT='Agility',ITEM_MOD_STRENGTH_SHORT='Strength',ITEM_MOD_SPELL_POWER_SHORT='Spell power',
    ITEM_MOD_SPELL_HEALING_DONE_SHORT='Healing',ITEM_MOD_SPELL_DAMAGE_DONE_SHORT='Spell damage',RESISTANCE0_NAME='Armor'}
local function plain(v)
    return not (type(issecretvalue)=='function' and issecretvalue(v))
end
function P.ItemDetails(reference)
    if not C_Item or type(C_Item.GetItemInfo)~='function' then return nil,'Item API unavailable' end
    local ok,name,link,quality,itemLevel,minLevel,kind,subkind,stack,equipLoc,icon,sellPrice,classID,subclassID=pcall(C_Item.GetItemInfo,reference)
    if not ok then return nil,'Item details unavailable' end
    if not plain(name) or not plain(link) or not plain(itemLevel) or not plain(minLevel) or not plain(equipLoc) then return nil,'Restricted item details' end
    if not name then return nil,'Item data pending' end
    if not plain(classID) or not plain(subclassID) then return nil,'Restricted item type' end
    if type(reference)=='string' and plain(reference) and reference:find('item:',1,true) then link=reference end
    local details={name=name,link=link,itemLevel=type(itemLevel)=='number' and itemLevel or nil,
        minLevel=type(minLevel)=='number' and minLevel or nil,equipLoc=type(equipLoc)=='string' and equipLoc or nil,stats=nil,classID=type(classID)=='number' and classID or nil,subclassID=type(subclassID)=='number' and subclassID or nil}
    if type(link)=='string' and type(equipLoc)=='string' and equipLoc~='' then
        local raw,err=P.Safe(C_Item.GetItemStats,link)
        if type(raw)=='table' then
            local stats={}; local valid=true
            local readOK=pcall(function()
                for key,value in pairs(raw) do
                    if not plain(key) or not plain(value) then valid=false; break end
                    if type(key)=='string' and type(value)=='number' then stats[key]=value end
                end
            end)
            if readOK and valid then details.stats=stats else details.statsError='Restricted stat fields' end
        else details.statsError=err or 'Stats pending / unavailable' end
    end
    if P.ResolveEnchantDetails then
        local resolved=pcall(P.ResolveEnchantDetails,details)
        if not resolved then details.stats=nil;details.statsError='Enchant data restricted / unavailable';details.enchant={status='unknown',reason=details.statsError} end
    end
    return details
end
function P.StatSummary(details)
    if not details then return 'Details pending / unavailable' end
    local fields={}
    if details.minLevel then fields[#fields+1]='client required level '..details.minLevel end
    if details.itemLevel then fields[#fields+1]='client item level '..details.itemLevel..' (not an upgrade score)' end
    if details.stats then
        local keys={}; for key in pairs(details.stats) do keys[#keys+1]=key end; table.sort(keys)
        for i,key in ipairs(keys) do
            if i>12 then fields[#fields+1]='additional stats: inspect tooltip'; break end
            fields[#fields+1]=(labels[key] or key)..' '..details.stats[key]
        end
        if #keys==0 then fields[#fields+1]='no numeric stats exposed by this API' end
    elseif details.equipLoc and details.equipLoc~='' then fields[#fields+1]=details.statsError or 'Stats unavailable' end
    if details.enchant then fields[#fields+1]='permanent enchant '..tostring(details.enchant.id or '?')..': '..details.enchant.status end
    if #fields==0 then return 'No comparable details exposed' end
    return table.concat(fields,'; ')
end
function P.HideItemTooltip()
    if tooltip and type(tooltip.Hide)=='function' then pcall(tooltip.Hide,tooltip) end
end
function P.BagAlternatives(slot)
    local list={}
    if not P.snapshot then return list end
    for _,item in ipairs(P.snapshot.bags) do
        local slots=item.details and slotMap[item.details.equipLoc]
        if slots then for _,candidateSlot in ipairs(slots) do
            if candidateSlot==slot then list[#list+1]=item; break end
        end end
    end
    -- Location order is deterministic and is not an item-value ranking.
    table.sort(list,function(a,b) if a.bag==b.bag then return a.slot<b.slot end return a.bag<b.bag end)
    return list
end
function P.ItemTooltip(reference,owner)
    if P.Safe(InCombatLockdown) then return false,'Item tooltip deferred until out of combat' end
    if type(reference)~='table' then return false,'Choose an item first' end
    local mode=reference.mode
    if mode=='target' then
        if type(reference.id)~='number' or reference.id<1 or reference.id>1000000000 or reference.id~=math.floor(reference.id) then return false,'Invalid item ID' end
        P.Item(reference.id)
    elseif mode=='equipped' then
        if not P.slotNames[reference.slot] then return false,'Unsupported equipment slot' end
    elseif mode=='bag' then
        if type(reference.bag)~='number' or type(reference.slot)~='number' or reference.bag<0 or reference.bag>5 or reference.slot<1 then return false,'Invalid bag location' end
    else return false,'Unknown item tooltip location' end
    if not tooltip then
        local ok,frame=pcall(CreateFrame,'GameTooltip','RuinousForeverPlannerItemTooltip',UIParent,'GameTooltipTemplate')
        if not ok or not frame then return false,'Item tooltip frame unavailable' end
        tooltip=frame
    end
    local setter=mode=='target' and tooltip.SetHyperlink or mode=='equipped' and tooltip.SetInventoryItem or tooltip.SetBagItem
    if type(tooltip.SetOwner)~='function' or type(setter)~='function' or type(tooltip.Show)~='function' then return false,'Tooltip API unavailable' end
    local ok,result=pcall(function()
        tooltip:SetOwner(owner or UIParent,'ANCHOR_RIGHT')
        if mode=='target' then return setter(tooltip,'item:'..reference.id)
        elseif mode=='equipped' then return setter(tooltip,'player',reference.slot)
        else return setter(tooltip,reference.bag,reference.slot) end
    end)
    if not ok or result==false then P.HideItemTooltip(); return false,'Tooltip request failed or restricted' end
    local shown=pcall(tooltip.Show,tooltip)
    if not shown then return false,'Tooltip display unavailable' end
    return true,'Tooltip requested; uncached data may still be pending'
end
