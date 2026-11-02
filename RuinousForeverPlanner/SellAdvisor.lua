local _,P=...
local function plain(v) return not (type(issecretvalue)=='function' and issecretvalue(v)) end
local function number(v) return plain(v) and type(v)=='number' and v>=0 and v<1e12 end
local function clock() return P.Safe(time) or 0 end
local function trim(t,limit)
    local count=0;for _ in pairs(t) do count=count+1 end
    while count>limit do
        local oldest,key
        for k,v in pairs(t) do local stamp=type(v)=='table' and v.seen or 0;if not oldest or stamp<oldest then oldest=stamp;key=k end end
        if not key then return end;t[key]=nil;count=count-1
    end
end
function P.EconomyDB()
    if not P.char then return end
    if type(P.char.economy)~='table' then P.char.economy={} end
    local e=P.char.economy
    for _,key in ipairs({'vendors','sell','estimates','keep'}) do if type(e[key])~='table' then e[key]={} end end
    if not number(e.minimumGain) then e.minimumGain=1000 end -- Explicit 10-silver extra-effort threshold.
    return e
end
function P.Money(copper)
    if not number(copper) then return 'unknown' end
    copper=math.floor(copper);return string.format('%dg %ds %dc',math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
end
function P.VendorValue(reference)
    if not C_Item or type(C_Item.GetItemInfo)~='function' then return end
    local ok,name,link,quality,itemLevel,min,kind,subkind,stack,loc,icon,sell,classID=pcall(C_Item.GetItemInfo,reference)
    if not ok or not plain(name) or not number(sell) or not plain(quality) or not plain(classID) then return end
    return sell,quality,classID
end
local merchantOpen=false
local dirty=false
local elapsedTotal=0
function P.ObserveVendor()
    local e=P.EconomyDB();if not e or not merchantOpen or P.Safe(InCombatLockdown) then return end
    local npc=P.Safe(UnitGUID,'npc');local name=P.Safe(UnitName,'npc')
    if type(npc)~='string' then P.vendorMessage='Merchant identity unavailable; no visit recorded.';return end
    local vendor={name=type(name)=='string' and name or 'Merchant',seen=clock(),stock={}}
    local count=P.Safe(GetMerchantNumItems)
    if number(count) and C_MerchantFrame and type(C_MerchantFrame.GetItemInfo)=='function' then
        for i=1,math.min(200,count) do
            local info=P.Safe(C_MerchantFrame.GetItemInfo,i)
            local link=P.Safe(GetMerchantItemLink,i)
            if type(info)=='table' and type(link)=='string' and plain(link) then
                local ok,row=pcall(function()
                    if not number(info.price) or not number(info.stackCount) or not plain(info.hasExtendedCost) then return end
                    local id=tonumber(link:match('item:(%d+)'));if not id then return end
                    return {id=id,price=info.price,stackCount=info.stackCount,extended=info.hasExtendedCost==true,seen=clock()}
                end)
                if ok and row then vendor.stock[tostring(row.id)]=row end
            end
        end
    end
    e.vendors[npc]=vendor
    -- Sell value is a separate client field, never inferred from merchant purchase price.
    for _,item in ipairs(P.snapshot and P.snapshot.bags or {}) do
        local value=P.VendorValue(item.link or item.id)
        if value then e.sell[tostring(item.id)]={unit=value,seen=clock(),vendor=npc} end
    end
    trim(e.vendors,50);trim(e.sell,2000)
    P.vendorMessage='Vendor visit recorded: '..vendor.name..'. Buy stock and bag-item sell values are stored separately.'
end
function P.SetSellEstimate(id,auction,de,minimumGain)
    if not number(id) or id<1 or id~=math.floor(id) or (auction~=nil and not number(auction)) or (de~=nil and not number(de)) or (minimumGain~=nil and not number(minimumGain)) then return false end
    local e=P.EconomyDB();if not e then return false end
    e.estimates[tostring(id)]={auction=auction,de=de,seen=clock()}
    if minimumGain~=nil then e.minimumGain=minimumGain end
    trim(e.estimates,500);return true
end
function P.SellDecision(item)
    local e=P.EconomyDB();if not e or not item then return {action='SCAN BAGS',why='No carried item selected.'} end
    local id=tostring(item.id);local vendor,quality,classID=P.VendorValue(item.link or item.id)
    local stored=e.sell[id]
    vendor=vendor or (stored and stored.unit)
    local result={vendor=vendor,action='REVIEW',why='Price or item eligibility is incomplete.'}
    if P.scanStale or P.deferred or not P.snapshot or #(P.snapshot.errors or {})>0 then result.why='Refresh gear/bags outside combat before deciding.';return result end
    if P.char.class~=P.actualClass then result.why='Select your actual class before deciding whether gear is useful.';return result end
    if type(quality)~='number' or type(classID)~='number' then result.why='Item quality/type unavailable; inspect before discarding.';return result end
    if e.keep[id] or (P.profile.tracked and P.profile.tracked[id]) or quality and quality>=5 or classID==12 then result.action='KEEP / INSPECT';result.why='Manually kept, tracked, quest item or exceptional quality.';return result end
    if item.details and item.details.stats then
        for _,slot in ipairs(P.slotOrder) do
            if P.SlotMatches(slot,item.details) then
                local cmp=P.CompareEquipment(slot,item.details,P.WeightedStatScore)
                if cmp and cmp.after>cmp.before then result.action='KEEP / COMPARE';result.why='Potential equipped upgrade. Inspect before selling or disenchanting.';return result end
            end
        end
    elseif classID==2 or classID==4 then result.why='Wearable stats are unavailable; inspect before discarding.';return result end
    local estimate=e.estimates[id]
    if estimate and clock()-estimate.seen<=86400 then
        result.auction=item.bound==false and estimate.auction or nil
        local knows=P.Safe(C_SpellBook and C_SpellBook.ContainsAnyDisenchantSpell)
        if knows==true and quality and quality>=2 and quality<=4 and (classID==2 or classID==4) then result.de=estimate.de end
    elseif estimate then result.stale=true end
    local best,method=vendor,'VENDOR'
    if result.auction and (not best or result.auction>best) then best=result.auction;method='AUCTION ESTIMATE' end
    if result.de and (not best or result.de>best) then best=result.de;method='CHECK DISENCHANT' end
    if best and vendor then
        local gain=best-vendor
        if gain>=e.minimumGain and method~='VENDOR' then result.action=method;result.why='User-entered net estimate beats vendor value by '..P.Money(gain)..' per item. Confirm trade/recipe eligibility and time cost.'
        else result.action='VENDOR FOR SPEED';result.why='No known net estimate beats vendor by the '..P.Money(e.minimumGain)..' extra-effort threshold. Unknown AH/DE values may be higher.' end
    elseif best then result.action='CHECK '..method;result.why='Vendor baseline unknown; this is not a verified best-value decision.' end
    if item.bound~=false then result.auctionNote='Bound or trade status unknown: auction option excluded.' end
    return result
end
P.sellIndex=1
function P.SelectedSellItem()
    local bags=P.snapshot and P.snapshot.bags or {}
    P.sellIndex=math.max(1,math.min(P.sellIndex,#bags));return bags[P.sellIndex],#bags
end
function P.SellLines()
    local e=P.EconomyDB();if not e then return {} end
    local item,count=P.SelectedSellItem();local lines={'QUICK SELL ADVISOR | bag item '..P.sellIndex..' / '..count}
    lines[#lines+1]=P.vendorMessage or 'Visit a vendor to record stock prices and carried-item sell values automatically.'
    if not item then lines[#lines+1]='Scan gear to read carried items.';return lines end
    local d=P.SellDecision(item)
    lines[#lines+1]=(item.name or ('Item '..item.id))..' ['..item.id..'] | stack '..(item.count or 1)
    lines[#lines+1]=d.action..': '..d.why
    lines[#lines+1]='Vendor per item: '..P.Money(d.vendor)..' | stack: '..P.Money(d.vendor and d.vendor*(item.count or 1))
    local observation=e.sell[tostring(item.id)]
    if observation then lines[#lines+1]='Sell value last observed at a vendor '..math.max(0,math.floor((clock()-observation.seen)/3600))..' hour(s) ago.' end
    local stockRows={}
    for _,vendor in pairs(e.vendors) do
        local row=vendor.stock and vendor.stock[tostring(item.id)]
        if row then stockRows[#stockRows+1]={vendor=vendor,row=row} end
    end
    table.sort(stockRows,function(a,b)return a.vendor.seen>b.vendor.seen end)
    for i,stock in ipairs(stockRows) do if i<=4 then
        lines[#lines+1]='Observed seller: '..stock.vendor.name..' | buy stack '..stock.row.stackCount..' for '..P.Money(stock.row.price)..(stock.row.extended and ' + additional currency/items (not valued)' or '')
    end end
    lines[#lines+1]='User net estimates per item | Auction: '..P.Money(d.auction)..' | Disenchant materials: '..P.Money(d.de)
    if d.auctionNote then lines[#lines+1]=d.auctionNote end
    if d.stale then lines[#lines+1]='Market estimate is older than 24 hours and excluded. Refresh it.' end
    lines[#lines+1]='Use Previous / Next item to browse; Edit sell estimates opens price fields. Toggle 1 keeps/unkeeps this item ID.'
    lines[#lines+1]='A vendor stock price is what YOU PAY, not what the vendor pays you. Stock can have reputation discounts, limited supply or currency costs.'
    lines[#lines+1]='Disenchant value is a manual expected net MATERIAL value, not a predicted yield table. Knowing Disenchant does not prove this item meets skill or item restrictions.'
    lines[#lines+1]='Auction estimates must include cut, lost deposits and sale risk. No auction scan, purchases, sales or disenchant actions are automated.'
    lines[#lines+1]='Speed advice uses your extra-effort threshold (default 10 silver per item); it does not simulate minutes saved. Prices are stored per character; visits retain up to 50 merchants and 2,000 sell values.'
    return lines
end
local events=CreateFrame('Frame')
for _,event in ipairs({'MERCHANT_SHOW','MERCHANT_UPDATE','MERCHANT_CLOSED'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function(_,event)
    if event=='MERCHANT_CLOSED' then merchantOpen=false;dirty=false
    else merchantOpen=true;dirty=true;elapsedTotal=0;if P.char then P.Scan() end end
end)
events:SetScript('OnUpdate',function(_,elapsed)
    if dirty then elapsedTotal=elapsedTotal+elapsed;if elapsedTotal>=.5 then dirty=false;P.ObserveVendor();P.Refresh() end end
end)
P.vendorEvents=events
