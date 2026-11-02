local P=TEST_P
local importedSource=P.SourceData; P.SourceData=nil
local tests=0
local function check(v,m) tests=tests+1; assert(v,m) end
P.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
check(P.char.class=='PRIEST' and P.char.spec=='Holy','default profile')
check(P.snapshot.equipped[5].id==6682,'equipped scan')
check(#P.snapshot.bags==1 and P.snapshot.bags[1].id==253987,'bag scan')
check(P.Owned(6682)=='Equipped','equipped ownership')
check(P.Owned(253987)=='In bags (not equipped)','bag ownership')
check(#P.Targets(26)==2,'solo excludes dungeon')
P.char.mode='group'; check(#P.Targets(26)==4,'group includes solo and dungeon')
check(#P.Targets(13)==0 and #P.Targets(31)==0,'strict dataset level boundaries')
check(#P.Targets(30)==6,'all sample targets at 30')
check(P.Profile('MAGE','Frost'),'profile selection')
check(#P.Targets(30)==0,'unsupported spec has no fabricated data')
check(not P.Profile('PRIEST','Frost'),'invalid profile rejected')
P.Profile('PRIEST','Holy')
local id=P.Stage(26).tasks[1].id
P.Toggle(id); P.Init(); check(P.char.done[id],'checklist survives initialization')
TEST_GUID='character-B'; P.Init(); check(not P.char.done[id],'characters isolated')
TEST_GUID='character-A'; P.Init(); check(P.char.done[id],'first character preserved')
TEST_COMBAT=true; local old=P.snapshot; check(not P.Scan() and P.snapshot==old and P.deferred,'combat scan deferred')
TEST_COMBAT=false; P.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); check(not P.deferred,'deferred refresh')
TEST_CACHED=false; P.requested={}; TEST_REQUESTS=0; P.Scan(); P.Scan()
check(P.snapshot.pending==2 and TEST_REQUESTS==2,'async cache pending and bounded requests')
TEST_CACHED=true; P.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT'); P.events.scripts.OnUpdate(); check(P.snapshot.pending==0,'cache completion refresh')
TEST_BADBAG=true; P.Scan(); check(#P.snapshot.errors==5,'bag errors surfaced')
check(P.Owned(999)=='Unknown: scan incomplete','unknown ownership on incomplete scan')
TEST_BADBAG=false; P.Scan()
TEST_LEVEL=60; check(P.Stage(TEST_LEVEL).max==60,'level 60 transition')
P.Show()
for _,f in ipairs(TEST_FRAMES) do if f.text=='Scan gear' then f.scripts.OnClick(f); break end end
check(#TEST_FRAMES>10,'UI constructed and buttons invoked with mocks')
SlashCmdList.RUINOUSFOREVERPLANNER('profile PRIEST Holy')
SlashCmdList.RUINOUSFOREVERPLANNER('done 1')
SlashCmdList.RUINOUSFOREVERPLANNER('solo')
SlashCmdList.RUINOUSFOREVERPLANNER('scan')
TEST_LEVEL=26; P.char.targetLevel=30; P.char.previewLevel=nil
P.Profile('PRIEST','Holy'); P.Context('PvE'); P.char.mode='solo'; P.Scan()
check(RuinousForeverPlannerDB.schema==2,'schema migrated to version 2')
local function action(id)
 for _,a in ipairs(P.Plan()) do if a.id==id then return a end end
end
check(not action('target-6682'),'equipped target creates no acquisition action')
check(action('owned-253987') and not action('target-253987'),'carried target replaces acquisition with inspect action')
check(action('prepare-6685') and action('prepare-6685').kind=='preparation','solo offers future group preparation')
check(action('target-254001').why:find('Future-level',1,true),'future target clearly marked preparation')
check(P.Gate(254001,'blocked'),'manual gate accepted')
check(action('blocked-254001') and not action('target-254001'),'blocked craft changes next actions')
check(not P.Gate(254001,'invented') and not P.Gate(999,'ready'),'invalid gates rejected')
P.Skip(253913); check(not action('target-253913'),'skip suppresses unowned candidate')
P.Context('PvP'); check(#P.Plan()==0 and #P.Targets(30)==0,'PvP cannot reuse PvE rankings')
check(not P.profile.skipped['253913'] and not P.profile.gates['254001'],'context state independent')
P.Context('PvE'); check(P.profile.skipped['253913'] and P.profile.gates['254001']=='blocked','return restores context settings')
P.Profile('PRIEST','Shadow'); check(not P.profile.skipped['253913'],'spec state independent')
P.Profile('PRIEST','Holy'); P.Skip(253913); P.Gate(254001,'ready')
local coverage=P.Coverage(26)
check(coverage.total==4 and coverage.equipped==1 and coverage.bagged==1,'sample ownership counts accurate')
P.RecordCoverage(); local len=#P.profile.history; P.RecordCoverage()
check(#P.profile.history==len,'unchanged history deduplicates')
for i=1,65 do TEST_LEVEL=i%60+1; P.RecordCoverage() end
check(#P.profile.history<=60,'history bounded')
TEST_LEVEL=30; P.Scan()
check(action('target-253913').why:find('short-lived',1,true),'late sample longevity penalty explained')
check(#P.GroupGoals()==2,'group aggregation excludes equipped robe')
TEST_BADBAG=true; P.Scan()
check(action('unknown-253913') and not action('target-253913'),'incomplete scan prevents confident acquisition')
TEST_BADBAG=false; P.Scan()
P.Profile('MAGE','Frost'); check(P.Plan()[1].id=='mismatch','other-class planning does not infer gear usability')
P.Profile('PRIEST','Holy')
SlashCmdList.RUINOUSFOREVERPLANNER('target 45'); check(P.Milestone()==45,'future milestone command')
SlashCmdList.RUINOUSFOREVERPLANNER('preview 12'); check(P.ViewLevel()==12 and UnitLevel()==30,'preview does not change actual level')
SlashCmdList.RUINOUSFOREVERPLANNER('preview live'); check(P.ViewLevel()==30,'return to live level')
SlashCmdList.RUINOUSFOREVERPLANNER('target 99'); check(P.char.targetLevel==45,'invalid target rejected')
P.char.targetLevel=15; check(P.Milestone()==30,'milestone never below actual level')
P.char.targetLevel=30
local originalFaction=UnitFactionGroup
UnitFactionGroup=function() return 'Horde' end
local hasStaff=false; for _,g in ipairs(P.AllTargets(30)) do if g.id==2042 then hasStaff=true end end
check(not hasStaff and #P.AllTargets(30)==5,'Alliance quest target excluded for Horde')
UnitFactionGroup=originalFaction
check(P.AllTargets(14)[1].levelNote:find('unverified',1,true),'quest planning threshold does not imply wear eligibility')
TEST_GUID='legacy-character'
RuinousForeverPlannerDB.characters[TEST_GUID]={class='PRIEST',spec='Holy',mode='group',done={legacy=true}}
RuinousForeverPlannerDB.schema=1; P.Init()
check(P.char.done.legacy and P.char.mode=='group' and type(P.char.profiles)=='table','true legacy character migrated without loss')
TEST_GUID='character-A'; P.Init()
local oldDone=P.char.done[id]; RuinousForeverPlannerDB.schema=1; P.Init()
check(P.char.done[id]==oldDone and P.char.context=='PvE','schema 1 migration retains checklist and mode')
P.char.previewLevel='corrupt'; P.Init(); check(P.char.previewLevel==nil,'malformed preview sanitized')
local savedItem=C_Item
C_Item=nil; P.Scan()
check(P.snapshot.pending==2 and P.snapshot.equipped[5].id==6682,'missing item namespace preserves IDs and shows pending')
C_Item=savedItem
local savedContainer=C_Container
C_Container=nil; P.Scan()
check(#P.snapshot.errors==5 and P.Owned(253987):find('Unknown',1,true),'missing container namespace cannot imply no ownership')
C_Container=savedContainer
local originalInfo=C_Container.GetContainerItemInfo
local originalSecret=issecretvalue
local secretID={}
issecretvalue=function(v) return v==secretID end
C_Container.GetContainerItemInfo=function(_,slot) if slot==1 then return {itemID=secretID,hyperlink='item:253987',stackCount=1} end end
P.Scan(); check(#P.snapshot.errors==1 and #P.snapshot.bags==0,'restricted nested bag fields rejected without unsafe ownership comparisons')
issecretvalue=originalSecret; C_Container.GetContainerItemInfo=originalInfo; P.Scan()
P.Show(); TEST_LEVEL=26; P.char.mode='group'; P.char.previewLevel=nil
for n=1,5 do
 local target=P.Tasks(P.Stage(26))[n].id; local before=P.char.done[target]
 for _,f in ipairs(TEST_FRAMES) do if f.text=='Toggle '..n then f.scripts.OnClick(); break end end
 check(P.char.done[target]==not before,'checklist button '..n..' closes over its own index')
end
for _,pair in ipairs({{'Prio','PERSONALIZED NEXT ACTIONS'},{'Gear','Candidates are not a numeric'},{'Bags','EQUIPPED'},{'Group','YOUR GROUP OBJECTIVES'},{'Prep','PREPARATION FOR MILESTONE'},{'Help','COVERAGE HISTORY'}}) do
 P.OpenPage(({Prio='Priorities',Bags='Inventory',Prep='Preparation'})[pair[1]] or pair[1])
 check(TEST_BODY.text:find(pair[2],1,true),'tab handler renders '..pair[1])
end
local rIDs={}; for _,a in ipairs(P.Plan()) do check(not rIDs[a.id],'adaptive actions deduplicated'); rIDs[a.id]=true end
P.char.mode='solo'
P.RefreshQuests()
check(P.questSnapshot[65].completed==false and P.questSnapshot[65].active==false,'negative flags preserve false instead of becoming nil')
check(P.QuestStatus(65):find('availability unknown',1,true),'absent flags never prove quest availability')
local nextQuest,questKind=P.QuestNext(166)
check(nextQuest.id==65 and questKind=='check','first unresolved source-linked preparation step')
check(action('quest-2042') and not action('target-2042'),'quest dependency changes gear-aware next activity')
TEST_QUEST_COMPLETED[65]=true; P.RefreshQuests()
check(P.QuestNext(166).id==132,'completed prerequisite advances the suggested check')
TEST_QUEST_ACTIVE[155]=true; P.RefreshQuests()
check(P.QuestNext(166).id==155,'accepted later step overrides absent earlier completion flags')
TEST_QUEST_ACTIVE[155]=nil; TEST_QUEST_ACTIVE[166]=true; P.RefreshQuests()
check(P.QuestNext(166).id==166 and action('prepare-2042'),'accepted final quest reaches group preparation')
TEST_QUEST_COMPLETED[166]=true; P.RefreshQuests()
check(action('completed-2042') and not action('prepare-2042'),'completed one-time reward is not acquisition-farmed again')
local hasCompletedQuestGoal=false; for _,a in ipairs(P.GroupGoals()) do if a.item.id==2042 then hasCompletedQuestGoal=true end end
check(not hasCompletedQuestGoal,'resolved one-time reward excluded from dungeon acquisition aggregation')
local oldQuestAPI=C_QuestLog; C_QuestLog=nil; P.RefreshQuests()
check(P.questSnapshot[166].completed==nil and P.QuestStatus(166):find('Unknown',1,true),'missing quest API remains unknown')
C_QuestLog=oldQuestAPI; TEST_COMBAT=true; P.RefreshQuests()
check(P.questDeferred and P.QuestStatus(166):find('deferred',1,true),'combat quest refresh deferred')
TEST_COMBAT=false; P.RefreshQuests(); check(not P.questDeferred,'quest flags refresh after combat')
TEST_QUEST_COMPLETED[166]=nil; TEST_QUEST_ACTIVE[166]=nil
P.events.scripts.OnEvent(nil,'QUEST_TURNED_IN')
check(P.questDirty,'quest event schedules a refresh')
P.events.scripts.OnUpdate()
check(not P.questDirty and P.questSnapshot[166].completed==false,'quest refresh coalesces on next frame')
UnitFactionGroup=function() return 'Horde' end; P.RefreshQuests()
check(P.questSnapshot[65]==nil and P.questSnapshot[6561]~=nil,'quest observations filtered to the actual faction')
UnitFactionGroup=originalFaction; P.RefreshQuests()
TEST_CACHED=true
local details=P.ItemDetails('item:253987')
check(details.minLevel==25 and details.itemLevel==30 and details.equipLoc=='INVTYPE_LEGS','multi-return client item metadata read correctly')
check(details.stats.ITEM_MOD_INTELLECT_SHORT==7,'numeric client stats retained')
check(P.StatSummary(details):find('Intellect 7',1,true) and P.StatSummary(details):find('not an upgrade score',1,true),'readable stat display avoids item-level score claim')
P.Scan(); check(#P.BagAlternatives(7)==1 and #P.BagAlternatives(5)==0,'bag alternatives filtered by equip-type slot')
check(P.BagAlternatives(7)[1].bag==0 and P.BagAlternatives(7)[1].slot==1,'bag alternative retains exact location')
local originalStats=C_Item.GetItemStats
C_Item.GetItemStats=function() return nil end
check(P.ItemDetails('item:253987').stats==nil,'missing stats remain unknown')
C_Item.GetItemStats=function() return {ITEM_MOD_INTELLECT_SHORT=secretID} end
issecretvalue=function(v) return v==secretID end
check(P.ItemDetails('item:253987').statsError=='Restricted stat fields','restricted stat fields rejected')
issecretvalue=originalSecret; C_Item.GetItemStats=originalStats
local ok,err=P.ItemTooltip({mode='target',id=253987},UIParent)
check(ok and TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][2]=='item:253987','target tooltip uses reviewed hyperlink accessor')
P.ItemTooltip({mode='equipped',slot=5},UIParent)
check(TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][1]=='equipped' and TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][3]==5,'equipped tooltip uses live equipment location')
P.ItemTooltip({mode='bag',bag=0,slot=1},UIParent)
check(TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][1]=='bag','bag tooltip uses exact carried location')
check(not P.ItemTooltip({mode='target',id=-1}) and not P.ItemTooltip({mode='equipped',slot=99}),'invalid item inspection inputs rejected')
TEST_TOOLTIP_DENY=true; check(not P.ItemTooltip({mode='target',id=253987}),'tooltip security rejection surfaced')
TEST_TOOLTIP_DENY=false; TEST_TOOLTIP_THROW=true; check(not P.ItemTooltip({mode='target',id=253987}),'tooltip accessor error contained')
TEST_TOOLTIP_THROW=false; TEST_COMBAT=true; local tooltipCount=#TEST_TOOLTIP_CALLS
check(not P.ItemTooltip({mode='target',id=253987}) and #TEST_TOOLTIP_CALLS==tooltipCount,'tooltip inspection deferred in combat')
TEST_COMBAT=false
P.char.mode='group'; TEST_LEVEL=26; P.Show(); P.inspectIndex=1
for _,f in ipairs(TEST_FRAMES) do if f.text=='Target tooltip' then f.scripts.OnClick(f); break end end
check(TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][2]=='item:2042','inspector target button binds selected candidate')
for _,f in ipairs(TEST_FRAMES) do if f.text=='Equipped tooltip' then f.scripts.OnClick(f); break end end
check(TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][1]=='equipped' and TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][3]==16,'inspector equipped button maps candidate slot')
-- Select by ID rather than assuming database order for the final assertion.
for i,g in ipairs(P.Targets(26)) do if g.id==253987 then P.inspectIndex=i end end
for _,f in ipairs(TEST_FRAMES) do if f.text=='Bag tooltip' then f.scripts.OnClick(f); break end end
check(TEST_TOOLTIP_CALLS[#TEST_TOOLTIP_CALLS][1]=='bag','inspector bag button locates carried slot alternative')
local getInfo=C_Item.GetItemInfo
C_Item.GetItemInfo=function(v)
 if tonumber(v)==253913 then return 'Future gloves','item:253913',3,45,40,'Armor','Cloth',1,'INVTYPE_HAND' end
 return getInfo(v)
end
local highRequirement=action('conflict-253913')
check(highRequirement and highRequirement.why:find('required level 40',1,true) and not action('target-253913'),'client requirement beyond the source window prevents invented future advice')
C_Item.GetItemInfo=function(v)
 if tonumber(v)==253913 then return 'Future gloves','item:253913',3,33,28,'Armor','Cloth',1,'INVTYPE_HAND' end
 return getInfo(v)
end
local validFuture=action('target-253913')
check(validFuture and validFuture.title:find('Prepare',1,true) and validFuture.why:find('required level 28',1,true),'higher client requirement within coverage changes action to future preparation')
C_Item.GetItemInfo=getInfo
local oldEnum=Enum
Enum={BagIndex={ReagentBag=5}}
local oldNumSlots=C_Container.GetContainerNumSlots
local queriedReagent=false
C_Container.GetContainerNumSlots=function(bag) if bag==5 then queriedReagent=true end; return oldNumSlots(bag) end
P.Scan(); check(queriedReagent,'exported reagent bag index scanned even when NUM_BAG_SLOTS is four')
check(#P.snapshot.errors==0,'absent optional reagent bag with zero slots is not a failure')
C_Container.GetContainerNumSlots=oldNumSlots; Enum=oldEnum
local diagnostics=P.CaptureDiagnostics()
check(diagnostics.clientBuild=='70170' and diagnostics.clientInterface==16001,'diagnostics capture actual build metadata from the current runtime')
check(diagnostics.api.ItemInfo and diagnostics.api.BagInfo and diagnostics.api.QuestCompleted,'capability flags reflect current functions')
check(diagnostics.scan.equippedCount==1 and diagnostics.scan.bagItemCount==1,'diagnostics include scan counts')
check(not diagnostics.scan.equipped and not diagnostics.scan.bags and not diagnostics.inventory and diagnostics.visualLayoutVerified==false,'diagnostics do not persist inventory snapshots or imply visual validation')
local originalRender=P.Render
P.Render=function() error('Synthetic planner UI failure') end
P.Show()
check(P.uiAttempted and not P.uiCallSucceeded and P.char.diagnostics.uiError:find('Synthetic planner UI failure',1,true),'UI failure recorded without losing access to diagnostics')
local firstUiError=P.lastUiError
P.Render=function() error('Later secondary failure') end
P.Show(); check(P.lastUiError==firstUiError,'first useful UI error preserved across repeated failure')
SlashCmdList.RUINOUSFOREVERPLANNER('doctor')
check(not P.char.diagnostics.uiCallSucceeded,'doctor does not replace a failed UI result with invented success')
P.Render=originalRender; P.Show()
check(P.uiCallSucceeded and P.char.diagnostics.uiError==nil and not P.char.diagnostics.visualLayoutVerified,'successful UI call clears prior error but does not certify appearance')
P.Render=function() error('Event refresh failure') end
P.Refresh(); check(not P.uiCallSucceeded and P.lastUiError:find('Event refresh failure',1,true),'event-driven UI refresh failures contained')
P.Render=originalRender; P.Show()
local oldInfo=C_Item.GetItemInfo; C_Item.GetItemInfo=nil
check(P.CaptureDiagnostics().api.ItemInfo==false,'missing capability recorded explicitly')
C_Item.GetItemInfo=oldInfo
P.char.class='PRIEST'
local notes=table.concat(P.MilestoneNotes(P.Data.stages[1]),' ')
check(notes:find('Alliance quests:',1,true) and notes:find('Priest gear goals:',1,true) and not notes:find('Horde quests:',1,true),'named milestones respect known faction and Priest profile')
P.char.class='WARRIOR'
notes=table.concat(P.MilestoneNotes(P.Data.stages[1]),' ')
check(notes:find('Warrior level 1 planning:',1,true) and not notes:find('Priest gear goals:',1,true),'Priest role milestones masked for other classes')
local oldFaction=UnitFactionGroup; UnitFactionGroup=function() return nil end
notes=table.concat(P.MilestoneNotes(P.Data.stages[1]),' ')
check(notes:find('Alliance quests:',1,true) and notes:find('Horde quests:',1,true),'unknown faction shows both explicitly labeled routes')
UnitFactionGroup=oldFaction
P.char.class='PRIEST'; P.char.spec='Holy'; P.Context('PvE')
if P.activeDialog then P.activeDialog:Hide() end
P.char.ui={}; P.UIOptions(); P.UpdateControls()
check(P.launcher:IsShown() and P.tracker:IsShown(),'launcher and objective tracker visible by default')
check(not P.ToggleTracked(999999),'unknown target rejected')
P.profile.tracked={}; P.ToggleTracked(6682)
check(table.concat(P.TrackerLines(),' '):find('[Equipped]',1,true),'tracked equipped item reflects scan automatically')
P.ToggleTracked(253987)
check(table.concat(P.TrackerLines(),' '):find('[Carried]',1,true),'tracked carried item distinguished from equipped')
P.char.ui.tracker=false; P.char.ui.minimap=false; P.UpdateControls()
check(not P.tracker:IsShown() and not P.launcher:IsShown(),'feature switches hide tracker and launcher')
P.ShowOptions(); P.ShowTargets()
P.char.ui.tracker=true; P.char.ui.minimap=true; P.char.ui.compact=true; P.UpdateControls()
check(not table.concat(P.TrackerLines(),' '):find('Prep:',1,true),'compact tracker hides detailed preparation')
P.char.ui.compact=false
P.Context('PvP'); P.UIOptions()
check(next(P.profile.tracked)==nil,'tracked targets isolated by profile')
P.Context('PvE'); P.UIOptions()
check(P.profile.tracked['6682'],'tracked targets survive profile switch')
P.char.ui.autoScan=false; local priorSnapshot=P.snapshot
P.events.scripts.OnEvent(P.events,'BAG_UPDATE_DELAYED')
check(P.snapshot==priorSnapshot and P.scanStale,'automatic scanning can be disabled and snapshot marked stale')
P.Scan(); check(P.snapshot~=priorSnapshot,'manual scan remains available while automatic scanning disabled')
P.char.ui.autoScan=true
P.Init(); check(P.char.ui.compact==false and P.profile.tracked['6682'],'settings and targets survive reinitialization')
local savedSnapshot=P.snapshot; local savedItem=P.Item
local g=P.Data.gear[5]
for _,v in ipairs(P.Data.gear) do if v.id==6682 then g=v end end
P.snapshot={equipped={[5]={id=999,details={equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=10}}}},bags={},errors={}}
P.Item=function() return {details={minLevel=26,equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=15}}} end
local est=P.UpgradeEstimate(g)
check(est.percent==50 and est.before==10 and est.after==15,'upgrade estimate uses equipped slot baseline and documented weighted formula')
P.Item=function() return {details={minLevel=26,equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=5}}} end
check(P.UpgradeEstimate(g).percent==-50,'downgrades retain negative percentage')
P.snapshot.equipped[5].details.stats={ITEM_MOD_STAMINA_SHORT=0}
check(P.UpgradeEstimate(g).percent==nil,'zero baseline never produces infinity or invented percentage')
P.snapshot.equipped[5]=nil
check(P.UpgradeEstimate(g).percent==nil,'empty slot reported without meaningless percent')
P.snapshot=savedSnapshot; P.Item=savedItem
local weapon=P.Data.gear[1]
check(P.UpgradeEstimate(weapon).percent==nil,'weapon combinations remain unscored')
P.Context('PvP'); check(P.UpgradeEstimate(g).percent==nil,'unsupported role context unscored'); P.Context('PvE')
P.ShowUpgradeWeights()
local savedEstimate=P.UpgradeEstimate
P.profile.tracked={['6682']=true,['6685']=true}
P.UpgradeEstimate=function(item) return {percent=item.id==6685 and 50 or 10,text='Test estimate'} end
local sortedText=table.concat(P.TrackerLines(),' ')
check(sortedText:find('Death Speaker Mantle',1,true)<sortedText:find('Death Speaker Robes',1,true),'tracker sorts targets by largest numeric stat gain')
P.UpgradeEstimate=savedEstimate
P.char.class='PRIEST'; P.char.spec='Holy'; P.Context('PvE'); P.char.mode='solo'; TEST_LEVEL=26
TEST_QUEST_COMPLETED={}; TEST_QUEST_ACTIVE={}; P.Scan(); P.RefreshQuests()
local function questSuggestion(id) for _,r in ipairs(P.QuestRecommendations()) do if r.item.id==id then return r end end end
check(questSuggestion(2042) and questSuggestion(2042).quest.id==65,'quest recommendations start with unfinished prerequisite and actual gear baseline')
TEST_QUEST_COMPLETED[142]=true; P.RefreshQuests()
check(P.QuestNext(166).id==155,'later completed prerequisite skips obsolete earlier flags')
TEST_QUEST_COMPLETED[166]=true; P.RefreshQuests()
check(not questSuggestion(2042),'completed one-time quest removed from recommendations even if reward absent')
TEST_QUEST_COMPLETED[166]=nil; P.snapshot.bags[#P.snapshot.bags+1]={id=2042}
check(not questSuggestion(2042),'owned carried reward prevents duplicate quest acquisition recommendation')
P.Scan(); TEST_QUEST_COMPLETED[1198]=true; P.RefreshQuests()
check(questSuggestion(7001) and questSuggestion(7001).quest.id==1200,'Alliance Blackfathom suggestion advances to reward quest')
TEST_QUEST_COMPLETED[1200]=true; P.RefreshQuests()
check(not questSuggestion(7001),'completed Blackfathom reward suppressed')
UnitFactionGroup=function() return 'Horde' end; P.RefreshQuests()
check(questSuggestion(7001) and questSuggestion(7001).quest.id==6561 and questSuggestion(7001).reason:find('incomplete',1,true),'Horde reward uses faction-specific quest and preserves incomplete prerequisite indicator')
check(not questSuggestion(2042),'Alliance-only quest rewards never recommended to Horde')
UnitFactionGroup=originalFaction; TEST_QUEST_COMPLETED={}; P.Scan(); P.RefreshQuests()
check(P.ToggleTracked(7001) and P.profile.tracked['7001'],'additional quest reward can be pinned to tracker')
local oldEstimate=P.UpgradeEstimate
P.UpgradeEstimate=function() return {percent=-5,text='Test downgrade'} end
check(#P.QuestRecommendations()==0,'known nonpositive weighted rewards do not become upgrade recommendations')
P.UpgradeEstimate=oldEstimate
P.Context('PvP'); check(#P.QuestRecommendations()==0,'unsupported quest recommendation profile explicitly empty'); P.Context('PvE')
if P.activeDialog then P.activeDialog:Hide() end
P.Show(); P.char.ui.tracker=true; P.UpdateControls()
P.ShowOptions()
check(P.activeDialog and P.activeDialog.strata=='DIALOG' and not P.IsPlannerShown() and not P.tracker:IsShown(),'settings isolate the dialog from both planner text and tracker text')
local dialog=P.activeDialog; P.Refresh()
check(not P.IsPlannerShown() and not P.tracker:IsShown(),'background refresh cannot reveal text under settings')
dialog:Hide()
check(P.IsPlannerShown() and P.tracker:IsShown(),'closing settings restores planner and enabled tracker')
P.HidePlanner(); P.ShowOptions(); P.activeDialog:Hide()
check(not P.IsPlannerShown() and P.tracker:IsShown(),'tracker settings close without opening previously hidden planner')
P.Show(); local oldClass=P.char.class
P.classButton.scripts.OnClick(P.classButton)
check(P.profileMenu:IsShown() and P.char.class==oldClass and P.profileMenuEntries.MAGE,'class dropdown opens without changing profile')
P.profileMenuEntries.MAGE.scripts.OnClick(P.profileMenuEntries.MAGE)
check(P.char.class=='MAGE' and not P.profileMenu:IsShown(),'class menu selects explicit class and closes')
P.specButton.scripts.OnClick(P.specButton)
check(P.profileMenuEntries.Frost and P.profileMenuEntries.Fire,'spec dropdown lists specs for chosen class')
P.profileMenuEntries.Frost.scripts.OnClick(P.profileMenuEntries.Frost)
check(P.char.spec=='Frost' and not P.profileMenu:IsShown(),'spec menu selects explicit spec')
P.Profile('PRIEST','Holy'); P.Context('PvE'); P.profile.tracked={}; P.char.ui.questSuggestions=false;P.char.ui.optimization=false
P.char.ui.nextActionTracker=false
local minimal=table.concat(P.TrackerLines(),' ')
check(minimal=='No active gear goals. Choose Targets to track an item.','empty tracker uses a concise empty state instead of placeholder paragraphs')
P.ToggleTracked(6682); minimal=table.concat(P.TrackerLines(),' ')
check(not minimal:find('Estimate =',1,true) and not minimal:find('Partial data.',1,true) and not minimal:find('Prep: unknown',1,true),'tracker removes repeated boilerplate while preserving actual goal')
-- Synthetic future candidate verifies the policy without inventing shipped gear data.
local originalItem=P.Item; local originalSnap=P.snapshot; local originalLevel=TEST_LEVEL
local current
for _,v in ipairs(P.Data.gear) do if v.id==6682 then current=v end end
local replacement={id=990001,name='Test future robe',slot=5,min=29,max=60,mode='solo',source='test fixture',acquire='Synthetic test acquisition',materials='Synthetic fixture'}
P.Data.gear[#P.Data.gear+1]=replacement
P.Item=function(id) return {details={minLevel=id==990001 and 29 or 26,equipLoc='INVTYPE_ROBE',stats={ITEM_MOD_INTELLECT_SHORT=id==990001 and 20 or 10}}} end
TEST_LEVEL=26; P.snapshot={equipped={},bags={},errors={}}; P.scanStale=false; P.deferred=false
check(P.ShortTermReplacement(current).item.id==990001,'better same-slot item within three levels produces level-first advice')
local scoredItem=P.Item
P.Item=function() return {details={minLevel=26,equipLoc='INVTYPE_ROBE'}} end
check(not P.ShortTermReplacement(current),'missing future stats never fabricate a better replacement')
P.Item=scoredItem
check(action('level-first-6682') and not action('target-6682'),'level-first action replaces hard acquisition recommendation')
TEST_LEVEL=25; check(not P.ShortTermReplacement(current),'policy does not apply before the current candidate level')
TEST_LEVEL=55; current.max=60; replacement.min=56
check(not P.ShortTermReplacement(current),'level-first rule disabled at level 55')
TEST_LEVEL=54; replacement.min=58; current.min=26
check(not P.ShortTermReplacement(current),'distant upgrades outside three-level window do not suppress gear goals')
current.max=30; replacement.min=29
P.Data.gear[#P.Data.gear]=nil; P.Item=originalItem; P.snapshot=originalSnap; TEST_LEVEL=originalLevel
P.char.ui.questSuggestions=true
RuinousForeverPlannerDB.schema=99; P.char=nil; P.Init(); check(P.dbError and not P.char,'future schema protected')
print('PASS: '..tests..' mocked behavior assertions; UI smoke exercised (not client verification)')

P.SourceData=importedSource
