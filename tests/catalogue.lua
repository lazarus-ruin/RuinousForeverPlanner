local P=TEST_P
RuinousForeverPlannerDB.schema=2;P.Init();P.actualClass='PRIEST';TEST_LEVEL=30;TEST_CACHED=true;TEST_BADBAG=false;TEST_COMBAT=false
local total=0
local function check(v,m)total=total+1;assert(v,m) end
for class,specs in pairs(P.Data.profiles) do
 for _,spec in ipairs(specs) do
  for _,context in ipairs({'PvE','PvP'}) do
   P.actualClass=class;P.Profile(class,spec);P.Context(context);P.char.mode='group';P.Scan()
   local info=P.ProfileInfo();check(info and P.ProfileSupported(),'profile mapped: '..class..' '..spec..' '..context)
   check(#P.Targets(30)>0,'nonempty current gear list: '..class..' '..spec..' '..context)
   local weights=P.UpgradeWeights();check(type(weights.ITEM_MOD_INTELLECT_SHORT)=='number','profile weights initialized')
   local plan=P.Plan();check(#plan>0,'gear or leveling action available for mapped profile')
   for _,g in ipairs(P.Targets(30)) do
    check(g.source and g.source:find('foreverchanges.pro/item/',1,true) and g.sourceList,'candidate retains item and list provenance')
   end
   P.QuestRecommendations()
  end
 end
end
P.actualClass='PRIEST';P.Profile('PRIEST','Discipline');P.Context('PvE');P.char.mode='group';P.Scan()
check(P.ProfileInfo().shared and #P.Targets(30)>0,'Discipline PvE uses labeled shared healer reference rather than an empty list')
local found=false;for _,g in ipairs(P.Targets(30)) do if g.id==253987 then found=true end end
check(found,'Discipline receives item candidates without changing selected spec')
P.Profile('WARRIOR','Arms');P.actualClass='WARRIOR'
local w=P.UpgradeWeights();check(w.ITEM_MOD_STRENGTH_SHORT>w.ITEM_MOD_INTELLECT_SHORT,'strength role has relevant default weights')
P.Profile('MAGE','Frost');P.actualClass='MAGE';w=P.UpgradeWeights();check(w.ITEM_MOD_SPELL_POWER_SHORT>w.ITEM_MOD_ATTACK_POWER_SHORT,'caster role has relevant default weights')
P.actualClass='PRIEST';P.Profile('PRIEST','Discipline');P.Context('PvE')
local records={
 [100]={name='Test baseline root',requiredLevel=10,questLevel=12,requiredClasses=16,requiredRaces=1},
 [101]={name='Test baseline branch',requiredLevel=20,questLevel=30,requiredClasses=16,requiredRaces=1,preQuestGroup={100}},
 [102]={name='Test other class',requiredLevel=10,questLevel=30,requiredClasses=1,requiredRaces=1},
 [103]={name='Test alternatives',requiredLevel=10,questLevel=30,requiredClasses=16,requiredRaces=1,preQuestSingle={100,101}}}
LibQuestieDB={RequireContract=function(n)return n==4 end,Quest={
 GetAllIds=function()return {100,101,102,103}end,
 GetAll=function(id,keys)local r=records[id];if not r then return end;local out={};for i,key in ipairs(keys)do out[i]=r[key]end;return out end}}
P.StartBaseline();P.BaselineStep()
check(P.baselineIndex==4 and P.GetBaselineQuest(101).name=='Test baseline branch','QuestieDB full ID index and named-field projection consumed')
check(not P.BaselineQuestMatches(102),'Questie class masks prevent other-class quest recommendations')
TEST_QUEST_COMPLETED={};TEST_QUEST_ACTIVE={};P.RefreshQuests()
check(P.NextBaselineQuest(101).id==100,'AND prerequisite selected from baseline')
TEST_QUEST_COMPLETED[100]=true
check(P.NextBaselineQuest(101).id==101,'completed baseline prerequisite advances next objective')
check(P.NextBaselineQuest(103).id==103,'OR prerequisites accept an already completed alternative')
TEST_QUEST_ACTIVE[101]=true;check(select(2,P.NextBaselineQuest(101))=='active','active baseline objective preferred')
TEST_QUEST_COMPLETED[101]=true;check(select(2,P.NextBaselineQuest(101))=='completed','completed baseline final quest resolved')
check(#P.BrowseBaseline('101',true)==1,'baseline quest catalogue searchable by ID')
check(#P.BrowseBaseline('branch',true)==1,'baseline quest catalogue searchable by name')
P.Show();P.ShowQuestBrowser();check(P.activeDialog~=nil and not P.IsPlannerShown(),'quest catalogue uses isolated dialog')
P.activeDialog:Hide();
P.baselineQuests[103].exclusiveTo={101}
check(P.KnownQuestBlock(103)~=nil,'completed exclusive alternative blocks a new acquisition recommendation')
P.baselineQuests[103].exclusiveTo=nil
LibQuestieDB=nil;P.StartBaseline()
check(P.baselineMessage:find('not available',1,true),'missing optional provider leaves clear baseline coverage status')


local function sourceSlot(class,spec,slot,location)
 P.actualClass=class;P.Profile(class,spec);P.Context('PvE')
 for _,g in ipairs(P.ProfileCandidates())do if g.slot==slot and g.equipLoc==location then return true end end
end
check(sourceSlot('PRIEST','Holy',17,'INVTYPE_HOLDABLE'),'held source section imports actual off-hand goals')
check(sourceSlot('PRIEST','Holy',16,'INVTYPE_2HWEAPON'),'two-hand source section imports staffs')
check(sourceSlot('WARRIOR','Protection',17,'INVTYPE_SHIELD'),'shield section retains shield type rather than treating it as a held book')
P.actualClass='PRIEST';P.Profile('PRIEST','Discipline');P.Context('PvE')
print('PASS: '..total..' imported catalogue and QuestieDB integration assertions; APIs mocked')
