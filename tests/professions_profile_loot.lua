local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local saved={get=GetProfessions,info=GetProfessionInfo,spec=C_SpecializationInfo,class=UnitClass,guid=TEST_GUID,level=TEST_LEVEL}
P.Init();P.char.ui.professions=true
GetProfessions=function()return 2,nil,nil,7,nil,9 end
GetProfessionInfo=function(index)
 if index==2 then return 'Localized Tailoring',0,54,75,0,0,197
 elseif index==7 then return 'Localized Fishing',0,80,150,0,0,356
 elseif index==9 then return 'Localized First Aid',0,125,150,0,0,129 end
end
local found,w=P.ReadProfessions()
check(found[197].skill==54 and found[356].skill==80 and found[129].skill==125 and not w,'learned skills survive nil return gaps and localized names')
P.char.professionGuide=197
local lines=table.concat(P.ProfessionLines(false),'\n')
check(lines:find('learned 54/75',1,true) and lines:find('55-125',1,true),'current skill and next route are shown')
check(lines:find('LATE BETA / UNTESTED',1,true),'future uncertain steps labeled')
check(lines:find('Solo:',1,true) and lines:find('Group:',1,true),'profession plan distinguishes solo and group')
P.ToggleProfessionTask(1);check(P.char.done['profession:197:1:55'],'manual craft checklist persists by profession and milestone')
GetProfessionInfo=function(index)if index==2 then return 'Tailoring',0,75,75,0,0,197 end end
check(table.concat(P.ProfessionLines(false),'\n'):find('TRAINED CAP REACHED',1,true),'trained cap warns before wasted crafting')
P.char.professionGuide=171
check(table.concat(P.ProfessionLines(false),'\n'):find('PREVIEW',1,true),'unlearned guide remains a preview')
GetProfessions=nil;check(select(2,P.ReadProfessions()):find('unavailable'),'missing API remains explicit')
GetProfessions=function()error('unavailable')end;check(select(2,P.ReadProfessions()):find('failed'),'failed skill scan remains explicit')
for _,id in ipairs(P.ProfessionOrder) do
 local d=P.ProfessionData[id];local last=1
 for _,r in ipairs(d.steps) do check(r.from==last and r.to>r.from,'skill bands cover route without gaps');last=r.to end
 check(last==300 and d.source:find('https://',1,true),'every guide has source and skill-300 endpoint')
end
UnitClass=function()return 'Warrior','WARRIOR',1 end;TEST_GUID='warrior-profession-qa';TEST_LEVEL=30
C_SpecializationInfo={GetSpecialization=function()return 2 end,GetSpecializationInfo=function()return 72,'Localized Fury' end}
P.Init();check(P.char.class=='WARRIOR' and P.char.spec=='Fury' and P.detectedSpec=='Fury','login uses actual Warrior and active spec ID without English names')
P.Profile('PRIEST','Holy');P.Init();check(P.char.class=='WARRIOR' and P.char.spec=='Fury','stale manual Priest preview cannot survive Warrior login')
C_SpecializationInfo.GetSpecializationInfo=function()return 257,'Holy' end
P.AutoProfile();check(P.char.class=='WARRIOR' and P.char.spec=='Fury' and not P.detectedSpec,'cross-class ID cannot select Priest profile')
C_SpecializationInfo.GetSpecialization=function()error('restricted')end
P.AutoProfile();check(P.char.class=='WARRIOR' and P.profileDetection:find('unavailable'),'spec failure preserves class-specific planning fallback')
GetProfessions=saved.get;GetProfessionInfo=saved.info;C_SpecializationInfo=saved.spec;UnitClass=saved.class;TEST_GUID=saved.guid;TEST_LEVEL=saved.level;P.Init();P.Scan()
-- World loot/bag direct hooks must supply an exact link when GetItem has not populated.
local oldTip,oldHook,oldAppend,oldLoot,oldContainer=GameTooltip,hooksecurefunc,P.AppendItemRating,GetLootSlotLink,C_Container.GetContainerItemLink
local callbacks={};GameTooltip={SetLootItem=function()end,SetBagItem=function()end,SetHyperlink=function()end}
hooksecurefunc=function(tip,method,callback)callbacks[method]=callback end
P.worldTooltipMethods=nil;check(P.InstallWorldTooltipHooks(),'direct world hooks install')
local received
P.AppendItemRating=function(tip,link)received=link end
GetLootSlotLink=function(slot)check(slot==3,'loot slot preserved');return 'item:123:0:0:0:0:77' end
callbacks.SetLootItem(GameTooltip,3);check(received=='item:123:0:0:0:0:77','loot tooltip passes exact item link')
C_Container.GetContainerItemLink=function(bag,slot)check(bag==1 and slot==2,'bag coordinates preserved');return 'item:456:9' end
callbacks.SetBagItem(GameTooltip,1,2);check(received=='item:456:9','bag hook includes offered enchant')
callbacks.SetHyperlink(GameTooltip,'item:789');check(received=='item:789','chat/world hyperlink hook')
GameTooltip=oldTip;hooksecurefunc=oldHook;P.AppendItemRating=oldAppend;GetLootSlotLink=oldLoot;C_Container.GetContainerItemLink=oldContainer;P.worldTooltipMethods=nil
-- Uncached items retry only while the same tooltip remains visible.
local oldLines,oldRequest=P.ItemRatingLines,C_Item.RequestLoadItemDataByID
local ready=false;P.ItemRatingLines=function()return ready and {'estimate'} or {} end
C_Item.RequestLoadItemDataByID=function()end
local tip={count=1,link='item:123',visible=true}
function tip:GetItem()return 'Loot',self.link end
function tip:IsShown()return self.visible end
function tip:NumLines()return self.count end
function tip:AddLine()self.count=self.count+1 end
P.char.ui.itemTooltips=true;P.AppendItemRating(tip);check(tip.count==1,'uncached loot waits')
ready=true;P.RetryItemTooltips(.21);check(tip.count==3,'late item data appends comparison without second hover')
ready=false;tip.link='item:456';tip.count=1;P.AppendItemRating(tip);tip.link='item:789';ready=true;P.RetryItemTooltips(.21);check(tip.count==1,'tooltip item switch cancels stale retry')
P.ItemRatingLines=oldLines;C_Item.RequestLoadItemDataByID=oldRequest
print('PASS: '..n..' profession, automatic spec and world-loot tooltip assertions; APIs mocked')
