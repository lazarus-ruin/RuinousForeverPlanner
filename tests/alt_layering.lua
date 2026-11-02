local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local oldClass,oldID,oldLink=UnitClass,GetInventoryItemID,GetInventoryItemLink
local oldGUID,oldLevel=TEST_GUID,TEST_LEVEL
local priestGUID='qa-priest';local mageGUID='qa-mage'
RuinousForeverPlannerDB.schema=2
UnitClass=function()return 'Priest','PRIEST',5 end;TEST_GUID=priestGUID;TEST_LEVEL=30;P.Init();P.Profile('PRIEST','Discipline');P.char.done.qa=true;P.Scan()
local priest=P.char;priest.ui={compact=true};priest.targetLevel=30
UnitClass=function()return 'Mage','MAGE',8 end;TEST_GUID=mageGUID;TEST_LEVEL=10
GetInventoryItemID=function(_,slot)if slot==8 then return 1427 end end
GetInventoryItemLink=function(_,slot)if slot==8 then return 'item:1427' end end
RuinousForeverPlannerDB.characters[mageGUID]={class='PRIEST',spec='Holy',targetLevel=30,previewLevel=45,profiles={['PRIEST:Holy:PvE']={gates={keep='ready'}}}}
P.Init()
check(P.actualClass=='MAGE' and P.char.class=='MAGE' and P.char.spec=='Frost','login repairs stale Priest selection on actual Mage without pretending to detect talents')
check(P.char~=priest and not P.char.done.qa,'Mage and Priest character records remain isolated')
check(P.char.previewLevel==nil and P.ViewLevel()==10,'login clears old level preview and uses level ten')
check(P.char.targetLevel==20,'legacy level-thirty default no longer overwhelms level-ten planning')
check(P.char.profiles['PRIEST:Holy:PvE'].gates.keep=='ready','repair retains saved profile data')
check(P.snapshot==nil,'switching identities clears previous character equipment snapshot before scanning')
P.Scan();check(P.snapshot.equipped[8].id==1427 and P.snapshot.equipped[5]==nil,'Mage scan reads Mage inventory instead of old Priest robe')
local info=P.ProfileInfo();check(info and info.path=='/bis/mage','Mage Frost uses the actual Mage source list')
check(#P.Targets(10)==0,'absent level-ten reference coverage remains explicit, not fabricated')
local upcoming=P.UpcomingTargets(10)
check(#upcoming>0 and upcoming[1].min==12,'near-future level-twelve Mage reference is shown when current list is empty')
for _,g in ipairs(upcoming)do check(g.sourceList:find('/bis/mage',1,true) and g.min>10 and g.min<=20,'upcoming references remain Mage-specific and within ten levels')end
local notes=table.concat(P.MilestoneNotes(P.Stage(10)),' ')
check(notes:find('Mage level 6 planning',1,true) and not notes:find('Priest gear',1,true),'Mage milestone notes do not show Priest sample guidance')
local tasks=P.Tasks(P.Stage(26));local texts={};for _,t in ipairs(tasks)do texts[#texts+1]=t.text end
check(not table.concat(texts,' '):find('Holy Priest',1,true) and not P.StageTitle(P.Stage(26)):find('Holy',1,true),'class-specific stage tasks and title no longer leak Holy sample into Mage')
P.Show()
local window;for _,f in ipairs(TEST_FRAMES)do if f.name=='RuinousForeverPlannerWindow' then window=f end end
check(window and window.strata=='DIALOG' and window.frameLevel==100,'main window draws at dialog layer above normal action bars')
local function mainText()
 for _,f in ipairs(TEST_FONTS or {})do
  local p=f.parent
  if p and p.parent and p.parent.parent==window then return f.text or '' end
 end
 return ''
end
for _,f in ipairs(TEST_FRAMES)do if f.text=='Gear' then f.scripts.OnClick(f);break end end
local text=mainText()
check(text:find('Character: Mage | Actual level 10',1,true),'rendered header identifies the scanned character and actual level')
check(text:find('No verified current-level gear targets',1,true) and text:find('UPCOMING MAGE REFERENCES',1,true),'empty low-level gear view explains coverage and shows upcoming correct-class goals')
check(text:find('Equipped items below are this character inventory',1,true),'inventory rows are distinguished from recommended targets')
P.classButton.scripts.OnClick(P.classButton)
check(P.profileMenu.strata=='DIALOG' and P.profileMenu.frameLevel>window.frameLevel,'class menu stays above raised main window')
P.HideProfileMenu();P.ShowOptions()
check(P.activeDialog and P.activeDialog.frameLevel>window.frameLevel and not P.IsPlannerShown(),'settings remain above main layer and hide underlying content')
P.activeDialog:Hide()
P.Profile('PRIEST','Holy');P.char.previewLevel=45
SlashCmdList.RUINOUSFOREVERPLANNER('current')
check(P.char.class=='MAGE' and P.char.spec=='Frost' and P.char.previewLevel==nil,'current command restores actual class and remembered per-class spec')
P.char.manualMilestone=true;P.char.targetLevel=30;P.Init();check(P.char.targetLevel==30,'explicitly requested future milestone survives login')
local source=P.SourceData;P.SourceData=nil
check(#P.ProfileCandidates()==0 and #P.GearCandidates()==0 and #P.TrackableGear()==0,'missing imported catalogue never substitutes Priest-only sample for Mage')
P.SourceData=source
local diagnostics=P.CaptureDiagnostics()
check(diagnostics.actualClass=='MAGE' and diagnostics.selectedClass=='MAGE' and diagnostics.actualLevel==10 and not diagnostics.classPreview,'diagnostics distinguish actual character from manual preview')
UnitClass=function()return 'Priest','PRIEST',5 end;TEST_GUID=priestGUID;TEST_LEVEL=30;P.Init()
check(P.char==priest and P.char.class=='PRIEST' and P.char.spec=='Discipline' and P.char.done.qa and P.char.ui.compact,'return to Priest retains Priest spec and settings')
UnitClass=function()return nil,nil end;P.Init();check(P.char==nil and P.dbError~=nil,'unavailable player class cannot silently choose Priest')
UnitClass=oldClass;GetInventoryItemID=oldID;GetInventoryItemLink=oldLink;TEST_GUID=oldGUID;TEST_LEVEL=oldLevel;P.Init();P.Scan()
print('PASS: '..n..' alt login, low-level Mage coverage and window layering assertions; UI APIs mocked')
