local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local saved={item=C_Item,tooltip=C_TooltipInfo,locale=GetLocale,enum=Enum,snap=P.snapshot,info=P.ProfileInfo,weights=P.UpgradeWeights,owned=P.CandidateOwned,candidates=P.GearCandidates,details=P.CandidateDetails,effCandidates=P.EfficiencyCandidates,enchants=P.EnchantData,next=P.QuestNext,block=P.KnownQuestBlock,level=TEST_LEVEL,class=P.char.class,mode=P.char.mode}
TEST_LEVEL=30;P.actualClass='PRIEST';P.char.class='PRIEST';P.char.spec='Holy';P.char.context='PvE';P.char.mode='solo';P.scanStale=false;P.deferred=false;P.profile.skipped={}
local int='ITEM_MOD_INTELLECT_SHORT'
P.UpgradeWeights=function()local w={};for _,f in ipairs(P.UpgradeStats)do w[f[1]]=0 end;w[int]=1;return w end
P.ProfileInfo=function()return {path='/fixture',role='caster'}end
P.CandidateOwned=function(g)for _,v in pairs(P.snapshot.equipped)do if v.id==g.id then return 'Equipped' end end;return 'Not owned'end
P.QuestNext=function()return nil,'unknown'end;P.KnownQuestBlock=function()return nil end
local facts={
 [7001]={value=20,loc='INVTYPE_WEAPONMAINHAND',class=2,subclass=4},
 [7002]={value=10,loc='INVTYPE_HOLDABLE',class=4,subclass=0},
 [7003]={value=40,loc='INVTYPE_2HWEAPON',class=2,subclass=10},
 [7004]={value=15,loc='INVTYPE_HOLDABLE',class=4,subclass=0},
 [7005]={value=100,loc='INVTYPE_ROBE',class=4,subclass=1},
 [7006]={value=0,loc='INVTYPE_WEAPONMAINHAND',class=2,subclass=4},
 [7007]={value=15,loc='INVTYPE_SHIELD',class=4,subclass=6}}
local apiIncludes=false;local typed='Enchanted: +10 Intellect'
local function link(id,enchant)return 'item:'..id..':'..(enchant or 0)..':0:0:0:0:-77:0:30'end
C_Item={GetItemInfo=function(reference)
 local id=tonumber(tostring(reference):match('item:(%d+)')) or tonumber(reference);local f=facts[id]
 if not f then return end
 return 'Fixture '..id,link(id,0),3,30,1,'Fixture','Fixture',1,f.loc,0,0,f.class,f.subclass
end,GetItemStats=function(reference)
 local id=tonumber(reference:match('item:(%d+)'));local f=facts[id];if not f then return end
 local enchant=P.EnchantLink(reference);local addition=apiIncludes and (enchant==123 and 10 or enchant==124 and 5 or 0) or 0
 return {[int]=f.value+addition}
end}
GetLocale=function()return 'enUS'end;Enum={TooltipDataLineType={ItemEnchantmentPermanent=15}}
C_TooltipInfo={GetHyperlink=function(reference)
 local id=P.EnchantLink(reference)
 return {lines={{type=0,leftText='+999 Intellect'},{type=15,leftText=id==124 and 'Enchanted: +5 Intellect' or typed}}}
end}
local enchant,stripped=P.EnchantLink(link(7005,123))
check(enchant==123 and stripped==link(7005,0),'strip only permanent enchant field, preserving suffix and remaining payload')
check(P.EnchantLink('item:7005::0')==0,'blank enchant field means no permanent enchant')
check(P.EnchantLink('item:7005:bogus:0')==nil,'invalid enchant ID remains unknown')
local d=P.ItemDetails(link(7005,123))
check(d.stats[int]==110 and d.baseStats[int]==100,'tooltip fallback adds enchant exactly once to base')
check(d.link==link(7005,123) and d.enchant.id==123,'exact caller enchant and suffix survive canonicalized GetItemInfo link')
check(d.enchant.status=='counted' and d.enchant.method:find('tooltip',1,true),'resolved tooltip enchant is explicit')
apiIncludes=true;d=P.ItemDetails(link(7005,123));check(d.stats[int]==110 and d.enchant.stats[int]==10,'client stat API including enchant never double-counted')
check(d.enchant.method=='API link difference','numeric API difference preferred when available');apiIncludes=false
check(P.ItemDetails(link(7005,0)).stats[int]==100,'unenchant version retains base stats')
local stats=P.ParseEnchantStats('Enchanted: +2 All Stats');check(stats[int]==2 and stats.ITEM_MOD_STRENGTH_SHORT==2 and stats.ITEM_MOD_SPIRIT_SHORT==2,'all-stats enchant expands once across five attributes')
check(P.ParseEnchantStats('Healing Spells +16, Damage Spells +6').ITEM_MOD_SPELL_DAMAGE_DONE_SHORT==6,'split healing / damage effect parsed separately')
check(not P.ParseEnchantStats('Chance to increase Spirit by 100% for 10 sec.'),'proc description cannot masquerade as static Spirit')
typed='Revelation: next spell critically strikes';d=P.ItemDetails(link(7005,999));check(d.stats[int]==100 and d.enchant.status=='unscored','unmodeled proc remains explicit while retaining known base gear stats')
GetLocale=function()return 'frFR'end;typed='Enchanted: +10 Intellect';check(P.ItemDetails(link(7005,123)).enchant.status=='unscored','unsupported locale cannot guess enchant text')
apiIncludes=true;check(P.ItemDetails(link(7005,123)).stats[int]==110,'numeric link difference supports non-English clients');apiIncludes=false;GetLocale=function()return 'enUS'end
local function worn(id,enchant)return {id=id,name='Fixture '..id,link=link(id,enchant),details=P.ItemDetails(link(id,enchant))}end
P.snapshot={equipped={[16]=worn(7001),[17]=worn(7002)},bags={},errors={}}
local compared=P.CompareEquipment(17,P.ItemDetails(link(7004)))
check(compared.before==30 and compared.after==35,'off-hand replacement includes retained main-hand stats')
P.snapshot.equipped[17]=worn(7002,124)
compared=P.CompareEquipment(17,P.ItemDetails(link(7004)))
check(compared.before==35 and compared.after==35,'old off-hand enchant is lost on replacement, not transferred')
P.snapshot.equipped[17]=worn(7002)
compared=P.CompareEquipment(16,P.ItemDetails(link(7003)))
check(compared.before==30 and compared.after==40 and compared.removesOffHand,'two-hand replacement removes old off-hand contribution')
local shield=P.CompareEquipment(17,P.ItemDetails(link(7007)));check(shield.before==30 and shield.after==35,'shield stat replacement retains the equipped main hand')
P.snapshot.equipped[17]=nil
compared=P.CompareEquipment(17,P.ItemDetails(link(7004)));check(compared.before==20 and compared.after==35,'empty off hand can be filled beside a one-hand weapon')
P.snapshot.equipped[16]=worn(7003)
check(not P.CompareEquipment(17,P.ItemDetails(link(7004))),'standalone off hand cannot be scored beside two-hander')
compared=P.CompareEquipment(16,P.ItemDetails(link(7001)),P.WeightedStatScore,{details=P.ItemDetails(link(7004))})
check(compared.before==40 and compared.after==35,'complete one-hand + off-hand set compared with two-hander')
P.snapshot.equipped={[16]=worn(7006),[17]=worn(7002)}
check(P.CompareEquipment(17,P.ItemDetails(link(7004))).before==10,'known statless main-hand does not suppress useful off-hand stats')
local function goal(id,slot)return {id=id,name='Goal '..id,slot=slot,min=1,max=60,confirmed=true,mode='solo',effort='purchase',acquire='Synthetic fixture'}end
local chest=goal(7005,5);local main=goal(7001,16);local off=goal(7004,17)
P.CandidateDetails=function(g)return P.ItemDetails(link(g.id))end
local list={chest};P.GearCandidates=function()return list end
P.EnchantData={referenceLevel=30,enchants={{name='Fixture +10 Intellect',group='Chest',stats={[int]=10},profiles={'/fixture'},skill=100}}}
P.snapshot.equipped={[5]=worn(7005)}
local report=P.OptimizationReport()
check(math.abs(report.percent-100*100/110)<.001,'missing published numeric enchant lowers rating even on exact target item')
check(report.recommendations[1] and report.recommendations[1].kind=='enchant','missing-enchant improvement recommended even when target item already equipped')
P.snapshot.equipped[5]=worn(7005,123);check(P.OptimizationReport().percent==100,'applying benchmark enchant raises evaluated slot to 100 percent')
local oldControls=P.UpdateControls;P.UpdateControls=function()end
P.PinEnchantGoal({slot=5,enchant={name='Fixture enchant',stats={[int]=10}}})
check(table.concat(P.EnchantGoalLines(),';'):find('Target static enchant stats present',1,true),'enchant goal checks enchant contribution instead of item ownership')
P.profile.enchantGoals=nil;P.UpdateControls=oldControls
local estimate=P.UpgradeEstimate(chest);check(estimate.percent<0,'same item ID with weaker enchant is not forced to zero percent')
local oldSnapshot=P.snapshot;local projected=P.ProjectedItemRating(5,P.ItemDetails(link(7005)))
check(projected.percent<100 and P.snapshot==oldSnapshot and P.snapshot.equipped[5].details.enchant.id==123,'tooltip projection includes lost enchant without mutating actual gear')
P.EnchantData={referenceLevel=30,enchants={}};list={main,off};P.snapshot.equipped={[16]=worn(7001),[17]=worn(7002)}
report=P.OptimizationReport();local hand
for _,row in ipairs(report.slots)do if row.slot==16 then hand=row end end
check(hand and hand.current==30 and hand.best==35 and report.ratedSlots==2,'rating includes actual off hand in weighted two-position weapon set')
check(math.abs(report.percent-100*30/35)<.001,'combined rating ratio uses complete benchmark')
typed='Revelation proc';P.snapshot.equipped[16]=worn(7001,999)
local partial=P.OptimizationReport();check(partial.ratedSlots==2 and partial.enchants.unscored==1,'unmodeled weapon proc does not erase off-hand/base stats from rating')
typed='Enchanted: +10 Intellect';P.snapshot.equipped[16]=worn(7001)
P.snapshot.equipped[17]=worn(7004);check(P.OptimizationReport().percent==100,'better off hand raises rating')
P.snapshot.equipped[17]=nil;P.snapshot.equipped[16]=worn(7003);report=P.OptimizationReport()
check(report.totalSlots==16 and report.ratedSlots==1,'two-hand weapon does not incur an impossible missing off-hand position')
local savedSource=P.EfficiencyCandidates
facts[7004].value=35
P.EfficiencyCandidates=function()return {main,off}end
main.max=30;off.max=30
local plan=P.EfficiencyPlan();local pair
for _,row in ipairs(plan.actions)do if row.partner then pair=row end end
check(pair and pair.partner.id==7004 and pair.estimate.percent>0,'guide recommends complete one-hand + off-hand upgrade when wearing two-hander')
P.snapshot.equipped={[16]=worn(7001),[17]=worn(7002)}
local e=P.LevelingEstimate(off);check(e.percent>0 and e.metric:find('weapon%-set'),'leveling guide scores off-hand improvements against complete set')
local tooltip=table.concat(P.ItemRatingLines(link(7004)),';');check(tooltip:find('Main + off-hand set',1,true) and tooltip:find('Rating:',1,true),'off-hand tooltip includes set comparison and projected rating: '..tooltip)
P.scanStale=true;check(not P.LevelingEstimate(off).percent,'stale scan still blocks off-hand estimate');P.scanStale=false
P.snapshot.equipped[17].details=nil;check(not P.CompareEquipment(16,P.ItemDetails(link(7003))),'missing equipped off-hand details remain unknown rather than zero')
C_Item=saved.item;C_TooltipInfo=saved.tooltip;GetLocale=saved.locale;Enum=saved.enum;P.snapshot=saved.snap;P.ProfileInfo=saved.info;P.UpgradeWeights=saved.weights;P.CandidateOwned=saved.owned;P.GearCandidates=saved.candidates;P.CandidateDetails=saved.details;P.EfficiencyCandidates=saved.effCandidates;P.EnchantData=saved.enchants;P.QuestNext=saved.next;P.KnownQuestBlock=saved.block;TEST_LEVEL=saved.level;P.char.class=saved.class;P.char.mode=saved.mode
print('PASS: '..n..' enchant normalization, no-double-counting, off-hand/set, rating and guide assertions; APIs mocked')
