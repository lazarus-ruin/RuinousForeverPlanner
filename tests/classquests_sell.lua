local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local saved={provider=P.baselineProvider,quests=P.baselineQuests,index=P.baselineIndex,ids=P.baselineIDs,class=P.actualClass,selected=P.char.class,spec=P.char.spec,level=TEST_LEVEL,completed=TEST_QUEST_COMPLETED,active=TEST_QUEST_ACTIVE}
P.actualClass='DRUID';P.Profile('DRUID',P.Data.profiles.DRUID[1]);TEST_LEVEL=10
P.baselineProvider={Quest={GetAll=function()end}};P.baselineIndex=6;P.baselineIDs={1,2,3,4,5,6}
P.baselineQuests={
 [20001]={id=20001,name='Form root',requiredClasses=1024,requiredLevel=10,zoneOrSort=-263},
 [20002]={id=20002,name='Form finale',requiredClasses=1024,requiredLevel=10,zoneOrSort=-263,preQuestGroup={20001}},
 [20003]={id=20003,name='Other class',requiredClasses=16,requiredLevel=10,zoneOrSort=-262},
 [20004]={id=20004,name='Future form',requiredClasses=1024,requiredLevel=20,zoneOrSort=-263},
 [20005]={id=20005,name='Outside horizon',requiredClasses=1024,requiredLevel=21,zoneOrSort=-263},
 [20006]={id=20006,name='Generic quest',requiredClasses=1503,requiredLevel=10}}
TEST_QUEST_COMPLETED={};TEST_QUEST_ACTIVE={}
local r=P.ClassQuestPlan();check(#r.rows==2,'class quest planner filters wrong class, generic quests and beyond ten-level horizon')
check(r.rows[1].quest.id==20001 and r.rows[1].goals==2,'shared prerequisite deduplicates multiple chain goals')
check(r.rows[2].kind=='UPCOMING','future minimum-level class objective labeled')
TEST_QUEST_COMPLETED[20001]=true;r=P.ClassQuestPlan();check(r.rows[1].quest.id==20002,'completed prerequisite advances chain')
TEST_QUEST_ACTIVE[20002]=true;check(P.ClassQuestPlan().rows[1].active,'in-log class quest prioritized')
TEST_QUEST_COMPLETED[20002]=true;r=P.ClassQuestPlan();check(#r.rows==1 and r.rows[1].quest.id==20004,'completed class chain suppressed')
TEST_QUEST_COMPLETED={};TEST_QUEST_ACTIVE={}
P.baselineQuests[20002].preQuestSingle={20003,20001};P.baselineQuests[20002].preQuestGroup=nil
r=P.ClassQuestPlan();check(r.rows[1].quest.id==20001,'OR chain avoids other-class branch')
P.baselineQuests[20001].preQuestGroup={20002};check((P.ClassQuestPlan().unresolved or 0)>0,'cyclic chain reports unresolved instead of looping')
P.baselineQuests[20001].preQuestGroup=nil;P.baselineQuests[20002].preQuestSingle=nil
P.baselineQuests[20001].exclusiveTo={20003};TEST_QUEST_COMPLETED[20003]=true
r=P.ClassQuestPlan();local seen=false;for _,row in ipairs(r.rows)do if row.quest.id==20001 then seen=true end end;check(not seen,'exclusive completed branch never presented as available')
P.baselineQuests[20001].exclusiveTo=nil;TEST_QUEST_COMPLETED={}
P.baselineQuests[20001].parentQuest=20003;check(P.KnownQuestBlock(20001)~=nil,'parent-active gate checked')
P.baselineQuests[20001].parentQuest=nil
check(P.PinClassQuest(20001) and P.profile.trackedQuests['20001'],'class objective pins to existing tracker')
check(not P.PinClassQuest(20003),'other-class quest cannot be pinned through class planner')
for class,sort in pairs({WARRIOR=-81,PALADIN=-141,HUNTER=-261,ROGUE=-162,PRIEST=-262,SHAMAN=-82,MAGE=-161,WARLOCK=-61,DRUID=-263})do
 P.actualClass=class;check(P.IsClassQuest({zoneOrSort=sort}),'class category recognized without name matching: '..class)
end
P.actualClass='DRUID';P.baselineProvider=nil;check(P.ClassQuestPlan().message:find('QuestieDB'),'missing provider explicit; no fallback Priest chain')
P.baselineProvider=saved.provider;P.baselineQuests=saved.quests;P.baselineIndex=saved.index;P.baselineIDs=saved.ids;P.actualClass=saved.class;P.Profile(saved.selected,saved.spec);TEST_LEVEL=saved.level;TEST_QUEST_COMPLETED=saved.completed;TEST_QUEST_ACTIVE=saved.active
local old={vendor=P.VendorValue,time=time,book=C_SpellBook,scan=P.Scan,snap=P.snapshot,npc=UnitGUID,name=UnitName,num=GetMerchantNumItems,link=GetMerchantItemLink,merchant=C_MerchantFrame,cmp=P.CompareEquipment,economy=P.char.economy}
time=function()return 100000 end;C_SpellBook={ContainsAnyDisenchantSpell=function()return true end}
local quality,kind=2,4;P.VendorValue=function()return 500,quality,kind end
local item={id=900001,name='Sell fixture',link='item:900001',bound=false,count=3,details={equipLoc='INVTYPE_CHEST',stats={ITEM_MOD_INTELLECT_SHORT=1}}}
P.snapshot={bags={item},equipped={},errors={}};P.scanStale=false;P.deferred=false;P.char.economy=nil
P.CompareEquipment=function()return {before=100,after=50}end
check(P.SellDecision(item).action=='VENDOR FOR SPEED','vendor is explicit speed fallback when market data absent')
check(P.SetSellEstimate(item.id,5000,3000,1000),'valid net estimates save')
check(P.SellDecision(item).action=='AUCTION ESTIMATE','unbound item uses higher AH net estimate')
item.bound=true;check(P.SellDecision(item).action=='CHECK DISENCHANT','bound item excludes auction and suggests manual DE check')
item.bound=nil;check(not P.SellDecision(item).auction,'unknown binding never assumed tradeable')
C_SpellBook.ContainsAnyDisenchantSpell=function()return false end;check(not P.SellDecision(item).de,'non-enchanter does not receive DE value recommendation')
C_SpellBook.ContainsAnyDisenchantSpell=function()return true end;item.bound=false
P.EconomyDB().keep[tostring(item.id)]=true;check(P.SellDecision(item).action=='KEEP / INSPECT','manual keep protects item');P.EconomyDB().keep[tostring(item.id)]=nil
P.CompareEquipment=function()return {before=50,after=100}end;check(P.SellDecision(item).action=='KEEP / COMPARE','potential upgrade protected before sale');P.CompareEquipment=function()return {before=100,after=50}end
kind=12;check(P.SellDecision(item).action=='KEEP / INSPECT','quest item protected');kind=4
quality=5;check(P.SellDecision(item).action=='KEEP / INSPECT','exceptional quality protected');quality=2
P.scanStale=true;check(P.SellDecision(item).action=='REVIEW','stale bags do not produce a sale recommendation');P.scanStale=false
time=function()return 200000 end;check(P.SellDecision(item).stale and not P.SellDecision(item).auction,'old net price estimate expires');time=function()return 100000 end
check(not P.SetSellEstimate(item.id,-1,20) and not P.SetSellEstimate(item.id,0/0,20),'invalid and NaN market inputs rejected')
P.Scan=function()end;UnitGUID=function(unit)if unit=='npc' then return 'Creature-merchant-qa' end;return old.npc(unit)end;UnitName=function()return 'Test merchant' end
GetMerchantNumItems=function()return 1 end;GetMerchantItemLink=function()return 'item:900002' end
C_MerchantFrame={GetItemInfo=function()return {price=2500,stackCount=5,hasExtendedCost=false}end}
P.vendorEvents.scripts.OnEvent(nil,'MERCHANT_SHOW');P.vendorEvents.scripts.OnUpdate(nil,.6)
local e=P.EconomyDB();check(e.vendors['Creature-merchant-qa'].stock['900002'].price==2500,'merchant buy price recorded')
check(e.vendors['Creature-merchant-qa'].stock['900002'].stackCount==5,'merchant stack quantity retained; no mistaken unit sell price')
check(e.sell[tostring(item.id)].unit==500,'bag sell value stored separately from merchant stock price')
P.vendorEvents.scripts.OnEvent(nil,'MERCHANT_CLOSED');local before=e.vendors['Creature-merchant-qa'].seen;time=function()return 300000 end;P.ObserveVendor();check(e.vendors['Creature-merchant-qa'].seen==before,'no merchant query once closed')
P.sellIndex=1;check(table.concat(P.SellLines(),'\n'):find('stack: 0g 15s 0c',1,true),'per-item vendor value multiplied for stack correctly')
P.ShowSellEstimates();check(P.activeDialog~=nil,'sell estimate input dialog opens');P.activeDialog:Hide()
P.Init();check(P.EconomyDB().sell[tostring(item.id)].unit==500,'vendor database survives character profile initialization')
P.VendorValue=old.vendor;time=old.time;C_SpellBook=old.book;P.Scan=old.scan;P.snapshot=old.snap;UnitGUID=old.npc;UnitName=old.name;GetMerchantNumItems=old.num;GetMerchantItemLink=old.link;C_MerchantFrame=old.merchant;P.CompareEquipment=old.cmp;P.char.economy=old.economy
print('PASS: '..n..' class quest, vendor database and sell-advisor assertions; APIs mocked')
