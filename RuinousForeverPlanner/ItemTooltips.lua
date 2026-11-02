local _,P=...
local locations={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16},INVTYPE_WEAPONMAINHAND={16},INVTYPE_2HWEAPON={16},INVTYPE_HOLDABLE={17},INVTYPE_SHIELD={17},INVTYPE_WEAPONOFFHAND={17},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_RELIC={18},INVTYPE_THROWN={18}}
local seen=setmetatable({},{__mode='k'})
local busy=setmetatable({},{__mode='k'})
local pending=setmetatable({},{__mode='k'})
local function plain(v) return not (type(issecretvalue)=='function' and issecretvalue(v)) end
local function color(v,text) return (v>.049 and '|cff40e080' or v<-.049 and '|cffff6060' or '|cffffffff')..text..'|r' end
function P.ItemRatingLines(link)
    local lines={}
    if not P.char or P.char.class~=P.actualClass or not P.ProfileSupported() then return lines end
    local d=P.ItemDetails(link)
    if not d or not locations[d.equipLoc] then return lines end
    lines[1]='Ruinous Forever Planner - stat estimate'
    local snap=P.snapshot
    if not snap or P.scanStale or P.deferred or #snap.errors>0 then lines[2]='Comparison unavailable: scan gear outside combat';return lines end
    if not d.minLevel or d.minLevel>(P.Safe(UnitLevel,'player') or 0) then lines[2]='Current-level rating unavailable: item level requirement';return lines end
    if d.enchant then lines[#lines+1]='Permanent enchant '..tostring(d.enchant.id or '?')..': '..d.enchant.status..(d.enchant.reason and (' ('..d.enchant.reason..')') or '') end
    local report=P.OptimizationReport()
    for _,slot in ipairs(locations[d.equipLoc]) do
        local comparison,reason=P.CompareEquipment(slot,d,P.WeightedStatScore)
        local label=(slot==16 or slot==17) and 'Main + off-hand set' or P.slotNames[slot] or tostring(slot)
        if comparison and comparison.before>0 then
            local pct=100*(comparison.after-comparison.before)/comparison.before
            lines[#lines+1]=label..': '..color(pct,string.format('%+.1f%% estimated stat upgrade',pct))
            if comparison.removesOffHand then lines[#lines+1]='Two-hand replacement removes the equipped off hand.' end
            if comparison.leavesOffHandEmpty then lines[#lines+1]='This one-hand replacement leaves the off hand empty; compare a complete set.' end
            local projected=P.ProjectedItemRating(slot,d)
            if report.percent and projected and projected.percent then
                local points=projected.percent-report.percent
                lines[#lines+1]=color(points,string.format('Rating: %.1f%% -> %.1f%% (%+.1f points)',report.percent,projected.percent,points))
                if projected.totalSlots~=report.totalSlots then lines[#lines+1]='Applicable position count changes with this weapon set.' end
            else lines[#lines+1]='Rating impact unavailable: no comparable benchmark' end
        elseif comparison and comparison.before==0 then lines[#lines+1]=label..': empty / zero-score baseline; percentage unavailable'
        else lines[#lines+1]=label..': '..(reason or d.statsError or 'comparison unavailable') end
    end
    local unscored=false
    for _,worn in pairs(snap.equipped) do
        local enchant=worn.details and worn.details.enchant
        if enchant and enchant.id and enchant.id>0 and enchant.status~='counted' then unscored=true end
    end
    if unscored then lines[#lines+1]='An equipped enchant effect is unscored; this comparison uses known static stats.' end
    lines[#lines+1]=string.format('Partial stat model: %d/%d positions evaluated',report.ratedSlots or 0,report.totalSlots or 17)
    lines[#lines+1]='Resolved permanent enchants included. Verify class/training, unique restrictions, weapon damage and special effects.'
    return lines
end
function P.AppendItemRating(tooltip,sourceLink)
    if not P.char or not P.UIOptions().itemTooltips or busy[tooltip] or P.Safe(InCombatLockdown) then return end
    if type(tooltip.IsForbidden)=='function' and P.Safe(tooltip.IsForbidden,tooltip) then return end
    if type(tooltip.GetItem)~='function' or type(tooltip.AddLine)~='function' or type(tooltip.NumLines)~='function' then return end
    local ok,_,link=pcall(tooltip.GetItem,tooltip)
    if not ok or not plain(link) then return end
    if type(link)~='string' and plain(sourceLink) then link=sourceLink end
    if type(link)~='string' then return end
    local count=P.Safe(tooltip.NumLines,tooltip)
    if not plain(count) or type(count)~='number' then return end
    local prior=seen[tooltip]
    if prior and prior.link==link and prior.count==count then return end
    busy[tooltip]=true
    local success=pcall(function()
        local lines=P.ItemRatingLines(link)
        if #lines==0 then
            local id=tonumber(link:match('item:(%d+)'))
            if id and not pending[tooltip] then
                pending[tooltip]={link=link,elapsed=0,tries=0}
                if C_Item and type(C_Item.RequestLoadItemDataByID)=='function' then pcall(C_Item.RequestLoadItemDataByID,id) end
            end
            return
        end
        pending[tooltip]=nil
        tooltip:AddLine(' ')
        for _,line in ipairs(lines) do tooltip:AddLine(line,.85,.85,.85,true) end
        seen[tooltip]={link=link,count=tooltip:NumLines()}
        if type(tooltip.Show)=='function' then tooltip:Show() end
    end)
    busy[tooltip]=nil
    return success
end
function P.RetryItemTooltips(elapsed)
    for tip,row in pairs(pending) do
        row.elapsed=row.elapsed+elapsed
        if row.elapsed>=.2 then
            row.elapsed=0;row.tries=row.tries+1
            local ok,_,link=pcall(tip.GetItem,tip)
            if row.tries>10 or not P.Safe(tip.IsShown,tip) or not ok or not plain(link) or link~=row.link then pending[tip]=nil
            else P.AppendItemRating(tip) end
        end
    end
end
function P.InstallWorldTooltipHooks()
    if not GameTooltip or type(hooksecurefunc)~='function' then return false end
    P.worldTooltipMethods=P.worldTooltipMethods or {}
    local methods={
        SetBagItem=function(tip,bag,slot) P.AppendItemRating(tip,P.Safe(C_Container and C_Container.GetContainerItemLink,bag,slot)) end,
        SetLootItem=function(tip,slot) P.AppendItemRating(tip,P.Safe(GetLootSlotLink,slot)) end,
        SetLootRollItem=function(tip) P.AppendItemRating(tip) end,
        SetHyperlink=function(tip,link) P.AppendItemRating(tip,link) end,
        SetInventoryItem=function(tip) P.AppendItemRating(tip) end}
    for name,callback in pairs(methods) do
        if not P.worldTooltipMethods[name] and type(GameTooltip[name])=='function' then
            P.worldTooltipMethods[name]=pcall(hooksecurefunc,GameTooltip,name,callback)
        end
    end
    return true
end
function P.InstallItemTooltipHook()
    P.InstallWorldTooltipHooks()
    if P.itemTooltipHookInstalled then return true end
    if not TooltipDataProcessor or type(TooltipDataProcessor.AddTooltipPostCall)~='function' or not Enum or not Enum.TooltipDataType then return false end
    local itemType=Enum.TooltipDataType.Item
    if type(itemType)~='number' then return false end
    local ok=pcall(TooltipDataProcessor.AddTooltipPostCall,itemType,function(tooltip) P.AppendItemRating(tooltip) end)
    P.itemTooltipHookInstalled=ok
    return ok
end
P.InstallItemTooltipHook()
local retryFrame=CreateFrame('Frame')
retryFrame:SetScript('OnUpdate',function(_,elapsed) P.RetryItemTooltips(elapsed) end)
