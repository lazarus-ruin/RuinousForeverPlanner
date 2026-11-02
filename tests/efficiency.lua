local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local saved={data=P.EfficiencyData,snap=P.snapshot,candidates=P.EfficiencyCandidates,details=P.ItemDetails,obs=P.QuestObservation,next=P.QuestNext,matches=P.BaselineQuestMatches,block=P.KnownQuestBlock,owned=P.CandidateOwned,baseline=P.baselineQuests,weights=P.UpgradeWeights,role=P.ProfileRole,questRecord=P.QuestRecord}
local oldLevel=TEST_LEVEL;local oldClass=P.char.class;local oldMode=P.char.mode
TEST_LEVEL=30;P.char.class=P.actualClass;P.char.mode='solo';P.scanStale=false;P.deferred=false;P.profile.skipped={}
local lo,hi=P.EfficiencyWindow();check(lo==30 and hi==40,'ten-level forward window, not five');TEST_LEVEL=56;lo,hi=P.EfficiencyWindow();check(hi==60,'horizon caps at sixty');TEST_LEVEL=30
check(#P.EfficiencyData.dungeons==34,'34 five-player references, excluding Upper Blackrock Spire')
for _,d in ipairs(P.EfficiencyData.dungeons) do
 check(d.id~='upper-blackrock-spire' and d.min<=d.max and d.source:find('https://foreverchanges.pro/dungeons/',1,true)==1,'source-backed range / five-player filter')
 for _,q in ipairs(d.quests) do check(type(q.id)=='number' and type(q.name)=='string' and (q.xp==nil or q.xp>=0),'quest factual schema') end
end
local d={id='fixture',name='Fixture five-player dungeon',min=25,max=40,zone='Fixture',quests={{id=90001,name='Active quest',level=30,minLevel=25,xp=6000},{id=90002,name='Completed quest',level=30,minLevel=25,xp=99999},{id=90003,name='Unaccepted quest',level=30,minLevel=25,xp=99999},{id=90004,name='Horde quest',level=30,minLevel=25,xp=99999,faction='Horde'}},items={}}
P.EfficiencyData={dungeons={d}}
P.BaselineQuestMatches=function()return true end;P.KnownQuestBlock=function()return nil end
P.QuestObservation=function(id)return {active=id==90001,completed=id==90002}end
P.QuestNext=function(id)return {id=id,name='Fixture next'},id==90002 and 'completed' or id==90001 and 'active' or 'check' end
local input={level=30,grindRate=12000,killXP=12000,clear=40,travel=10,wait=5,prep=5,extraQuestXP=0}
local report=P.DungeonComparison(d,input)
check(report.questXP==6000 and report.accepted==1 and #report.quests==3,'only active unfinished same-faction quest contributes source XP')
check(report.totalXP==18000 and report.minutes==60 and report.rate==18000,'kill XP plus one-time quests divided by all time')
check(report.deltaMinutes==30 and report.maxWait==35,'equal-XP opportunity cost / maximum group wait')
check(report.repeatRate==18000,'repeat scenario excludes one-time quest XP and explicitly excludes overhead')
input.wait=60;report=P.DungeonComparison(d,input);check(report.deltaMinutes<0 and report.verdict:find('GRIND',1,true),'long group wait flips decision to grinding')
TEST_COMBAT=true;check(not P.DungeonComparison(d,input).rate,'combat quest flags cannot silently zero accepted XP');TEST_COMBAT=false
input.wait=5;input.level=29;check(not P.DungeonComparison(d,input).rate,'old level run estimates expire');input.level=30
input.clear=0;check(not P.DungeonComparison(d,input).rate,'zero clear duration rejected');input.clear=40
input.killXP=nil;check(not P.DungeonComparison(d,input).rate,'missing XP remains unavailable');input.killXP=12000
input.grindRate=0;check(not P.DungeonComparison(d,input).rate,'no fabricated grinding rate');input.grindRate=12000
local oldXP,oldMax=UnitXP,UnitXPMax;UnitXP=function()return 900 end;UnitXPMax=function()return 1000 end
check(P.DungeonComparison(d,input).nextLevelWarning~=nil,'next-level timing distinguished from complete-run XP comparison');UnitXP=oldXP;UnitXPMax=oldMax
P.EfficiencyOptions().runs.fixture={};check(not P.DungeonComparison(d).rate,'unset saved run remains unknown')
local robe={id=99001,name='Fixture robe',slot=5,min=1,max=60,mode='solo',effort='quest',questID=90001}
local robe2={id=99002,name='Future robe',slot=5,min=33,max=60,mode='solo',effort='quest',questID=90003}
local values={[99001]=75,[99002]=100};local minimum={[99001]=1,[99002]=33}
P.snapshot={equipped={[5]={id=99000,details={equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=50}}}},bags={},errors={}}
P.ItemDetails=function(id)return {name='Fixture',link='item:'..id,equipLoc='INVTYPE_ROBE',minLevel=minimum[id] or 1,stats={ITEM_MOD_INTELLECT_SHORT=values[id] or 75}}end
P.UpgradeWeights=function()local w={};for _,f in ipairs(P.UpgradeStats)do w[f[1]]=0 end;w.ITEM_MOD_INTELLECT_SHORT=1;return w end
P.ProfileRole=function()return 'caster' end
check(P.LevelingEstimate(robe).percent==50,'current equipped gear drives leveling stat comparison')
P.scanStale=true;check(not P.LevelingEstimate(robe).percent,'stale scan not scored');P.scanStale=false
P.CandidateOwned=function()return 'Not owned' end
P.EfficiencyCandidates=function()return {robe,robe2}end
report=P.EfficiencyPlan();check(report.lastLevel==40 and #report.actions==2,'ten-level plan includes current and future positive upgrades')
check(report.actions[1].action=='ON-ROUTE QUEST','active solo quest favored')
robe.mode='group';robe.effort='dungeon';report=P.EfficiencyPlan();local found
for _,a in ipairs(report.actions)do if a.item.id==robe.id then found=a end end
check(found.action=='LEVEL FIRST','short-lived grind yields to stronger near-future easy reward')
P.profile.skipped['99002']=true;report=P.EfficiencyPlan();check(#report.actions==1 and report.actions[1].action=='OPTIONAL GROUP','solo preference and skip honored')
P.profile.skipped={};P.CandidateOwned=function()return 'In bags (not equipped)'end
check(P.EfficiencyPlan().actions[1].action=='INSPECT CARRIED','owned improvement precedes acquisition')
P.CandidateOwned=function()return 'Equipped'end;check(#P.EfficiencyPlan().actions==0,'equipped items do not cause new farms')
P.CandidateOwned=function()return 'Not owned'end;values[99001]=25;values[99002]=25;check(#P.EfficiencyPlan().actions==0,'non-upgrades excluded')
values[99001]=75;values[99002]=100
TEST_LEVEL=60;check(P.EfficiencyPlan().unavailable:find('60',1,true),'no leveling instructions after cap');TEST_LEVEL=30
local oldTime,oldSampleXP,oldSampleMax,oldSession=GetTime,UnitXP,UnitXPMax,P.grindSample
local tick,xp,max=0,100,1000
GetTime=function()return tick end;UnitXP=function()return xp end;UnitXPMax=function()return max end
check(P.StartGrindSample(),'grinding sample starts from live XP snapshot')
xp=300;tick=30;check(not P.FinishGrindSample(),'short samples not accepted as measured baseline')
tick=120;xp=500;check(P.FinishGrindSample(),'completed sample saved')
check(math.abs(P.EfficiencyOptions().grindRate-12000)<.01,'measured rate includes all elapsed recovery time')
P.StartGrindSample();TEST_LEVEL=31;xp=100;tick=240;P.RecordGrindSample()
check(P.grindSample.gained==600,'level-up XP rollover counted once')
P.RecordGrindSample();check(P.grindSample.gained==600,'repeated XP event does not double-count')
TEST_LEVEL=33;P.RecordGrindSample();check(P.grindSample.error~=nil,'unresolved multi-level transition remains unknown')
GetTime=oldTime;UnitXP=oldSampleXP;UnitXPMax=oldSampleMax;P.grindSample=oldSession;TEST_LEVEL=30
local oldTooltip,oldLocale=C_TooltipInfo,GetLocale
GetLocale=function()return 'enUS'end
C_TooltipInfo={GetHyperlink=function(link)return {lines={{leftText=link=='item:old' and '(10.0 damage per second)' or '(15.0 damage per second)'}}}end}
local oldActual=P.actualClass;P.actualClass='WARRIOR';P.char.class='WARRIOR'
P.snapshot.equipped[16]={link='item:old',details={equipLoc='INVTYPE_2HWEAPON',classID=2,subclassID=1}}
local weapon={id=99999,slot=16};local details={link='item:new',minLevel=25,equipLoc='INVTYPE_2HWEAPON',classID=2,subclassID=1}
check(P.LevelingEstimate(weapon,details).percent==50,'same-type live weapon base DPS compared')
P.snapshot.equipped[17]={id=123};check(not P.LevelingEstimate(weapon,details).percent,'weapon combination changes not scored');P.snapshot.equipped[17]=nil
GetLocale=function()return 'deDE'end;check(not P.LevelingEstimate(weapon,details).percent,'unsupported tooltip locale remains unknown')
GetLocale=function()return 'enUS'end;P.char.class='DRUID';check(not P.LevelingEstimate(weapon,details).percent,'feral form does not inherit weapon base DPS')
C_TooltipInfo=oldTooltip;GetLocale=oldLocale;P.char.class=oldClass;P.actualClass=oldActual
P.EfficiencyCandidates=saved.candidates;P.ItemDetails=saved.details;P.QuestObservation=saved.obs;P.QuestNext=saved.next;P.BaselineQuestMatches=saved.matches;P.KnownQuestBlock=saved.block;P.CandidateOwned=saved.owned;P.UpgradeWeights=saved.weights;P.ProfileRole=saved.role;P.EfficiencyData=saved.data;P.snapshot=saved.snap;P.baselineQuests=saved.baseline;TEST_LEVEL=oldLevel;P.char.mode=oldMode
P.ShowDungeonAdvisor();check(P.activeDialog~=nil,'dungeon advisor opens isolated readable dialog')
check(P.IsPlannerShown()==false,'dungeon advisor hides planner text')
P.activeDialog:Hide()
print('PASS: '..n..' ten-level efficiency, dungeon XP, completion, weapon and dialog assertions; APIs mocked')
