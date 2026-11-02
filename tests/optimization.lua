local P=TEST_P
RuinousForeverPlannerDB.schema=2;P.Init();P.actualClass='PRIEST';P.Profile('PRIEST','Holy');P.Context('PvE')
local originalEnchantData=P.EnchantData;P.EnchantData={referenceLevel=30,enchants={}}
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local saved={candidates=P.GearCandidates,details=P.CandidateDetails,snap=P.snapshot,level=TEST_LEVEL,source=P.SourceData,skipped=P.profile.skipped}
TEST_LEVEL=30;P.scanStale=false;P.deferred=false
P.profile.upgradeWeights={};local weights=P.UpgradeWeights();for key in pairs(weights)do weights[key]=0 end;weights.ITEM_MOD_INTELLECT_SHORT=1
local target={id=900001,name='Fixture robe',slot=5,min=1,max=60,confirmed=true,mode='group',acquire='Synthetic dungeon fixture',source='https://example.invalid/fixture'}
local list={target}
P.GearCandidates=function()return list end
P.CandidateDetails=function(g)return {equipLoc=g.slot==5 and 'INVTYPE_ROBE' or 'INVTYPE_FINGER',minLevel=1,stats={ITEM_MOD_INTELLECT_SHORT=g.value or 100}}end
P.snapshot={equipped={[5]={id=900002,name='Fixture current',details={equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=50}}}},bags={},errors={}}
local report=P.OptimizationReport()
check(report.percent==50 and report.ratedSlots==1 and report.totalSlots==17,'50 percent rating uses equipped stats and shows partial denominator')
check(#report.recommendations==1 and report.recommendations[1].gainPoints==50,'recommendation predicts potential percentage-point gain within evaluated slots')
P.snapshot.equipped[5].details.stats.ITEM_MOD_INTELLECT_SHORT=85
check(P.OptimizationReport().percent==85,'85 percent rating supported without bins')
P.snapshot.equipped[5].details.stats.ITEM_MOD_INTELLECT_SHORT=150
report=P.OptimizationReport();check(report.percent==100 and not report.fullBiS and not report.easterEgg,'capped partial 100 never asserts full BiS or awards easter egg')
P.snapshot.equipped[5]=nil;check(P.OptimizationReport().percent==0,'empty evaluated slot counts zero')
P.snapshot.equipped[5]={id=900002,details={equipLoc='INVTYPE_ROBE'}}
check(P.OptimizationReport().percent==nil,'missing equipped stats remain unknown rather than zero')
P.snapshot.equipped[5].details.stats={ITEM_MOD_INTELLECT_SHORT=50}
P.profile.skipped={['900001']=true};report=P.OptimizationReport()
check(report.percent==50 and #report.recommendations==0,'skipping a recommendation cannot improve rating by shrinking its denominator')
P.profile.skipped={};P.char.mode='solo';local solo=P.OptimizationReport().percent;P.char.mode='group'
check(solo==P.OptimizationReport().percent,'Solo/Group filter cannot manipulate rating')
P.snapshot.bags={{id=900001,name='Fixture robe'}};report=P.OptimizationReport()
check(report.percent==50 and report.recommendations[1].title:find('carried',1,true),'bag ownership suggests inspection without counting as equipped')
P.snapshot.errors={'incomplete'};check(P.OptimizationReport().unavailable~=nil,'incomplete scan blocks rating');P.snapshot.errors={}
P.scanStale=true;check(P.OptimizationReport().unavailable~=nil,'stale scan blocks rating');P.scanStale=false
P.deferred=true;check(P.OptimizationReport().unavailable~=nil,'combat-deferred scan blocks rating');P.deferred=false
list={{id=910001,name='Fixture ring A',slot=11,min=1,max=60,confirmed=true,mode='solo',value=100,acquire='Fixture'},
{id=910002,name='Fixture ring B',slot=11,min=1,max=60,confirmed=true,mode='solo',value=50,acquire='Fixture'}}
P.snapshot.equipped={[11]={id=920001,details={equipLoc='INVTYPE_FINGER',stats={ITEM_MOD_INTELLECT_SHORT=50}}},[12]={id=920002,details={equipLoc='INVTYPE_FINGER',stats={ITEM_MOD_INTELLECT_SHORT=100}}}}
report=P.OptimizationReport();local normal=report.percent
P.snapshot.equipped[11],P.snapshot.equipped[12]=P.snapshot.equipped[12],P.snapshot.equipped[11]
check(normal==100 and P.OptimizationReport().percent==normal,'distinct two-ring benchmarks are invariant to ring slot ordering')
list={};TEST_LEVEL=60;check(not P.OptimizationReport().easterEgg,'level 60 alone does not trigger easter egg')
local set={level=60,class='PRIEST',spec='Holy',context='PvE',verified=true,certification='complete-bis-with-enchants',source='https://example.invalid/certified-test-fixture',slots={}}
P.snapshot.equipped={}
for _,slot in ipairs(P.slotOrder)do local id=930000+slot;set.slots[tostring(slot)]={itemID=id,enchantID=0};P.snapshot.equipped[slot]={id=id,link='item:'..id..'::0:0:0:0:0:0:60'} end
P.Data.certifiedBiSSets={set};report=P.OptimizationReport()
check(report.fullBiS and report.percent==100 and report.easterEgg=='100% BiS. Go outside and touch grass.','complete certified level-60 set triggers requested easter egg')
P.snapshot.equipped[5].link='item:930005:1:0:0:0:0:0:0:60'
check(not P.OptimizationReport().fullBiS,'wrong enchant prevents full BiS qualification')
P.snapshot.equipped[5].link='item:930005::0:0:0:0:0:0:60';P.snapshot.equipped[10]=nil
check(not P.OptimizationReport().easterEgg,'missing slot prevents easter egg')
P.Data.certifiedBiSSets=nil
check(P.UpgradeDisplay({percent=12,text='+12%'})=='|cff40e080+12%|r','positive upgrade uses green')
check(P.UpgradeDisplay({percent=-12,text='-12%'})=='|cffff6060-12%|r','negative upgrade uses red')
check(P.UpgradeDisplay({percent=0,text='0%'})=='0%','zero upgrade remains neutral')
check(P.UpgradeDisplay({text='Unavailable'})=='Unavailable','unknown estimate remains neutral')
check(P.UpgradeDisplay({percent=.001,text='+0.0%'})=='+0.0%','rounding-sized changes do not get misleading color')
P.GearCandidates=saved.candidates;P.CandidateDetails=saved.details;P.snapshot=saved.snap;TEST_LEVEL=saved.level;P.SourceData=saved.source;P.profile.skipped=saved.skipped
P.EnchantData=originalEnchantData;P.UIOptions();P.char.ui.optimization=true;P.Show()
for _,f in ipairs(TEST_FRAMES)do if f.text=='Rating' then f.scripts.OnClick(f);break end end
check(TEST_BODY.text:find('SLOT BREAKDOWN',1,true),'rating tab renders the score breakdown')
print('PASS: '..n..' optimization rating, certification and upgrade-color assertions; APIs mocked')
