local P=TEST_P
local n=0;local function check(v,m)n=n+1;assert(v,m)end
local old={race=UnitRace,route=P.char.route,complete=TEST_QUEST_COMPLETED,active=TEST_QUEST_ACTIVE,level=TEST_LEVEL,objectives=C_QuestLog.GetQuestObjectives,actual=P.actualClass,class=P.char.class,spec=P.char.spec,clock=GetTime,xp=UnitXP,max=UnitXPMax}
P.actualClass='PRIEST';P.Profile('PRIEST','Holy');UnitRace=function()return 'Human','Human',1 end;TEST_LEVEL=30;TEST_QUEST_COMPLETED={};TEST_QUEST_ACTIVE={};P.Scan()
local header='RFP1\tQA%20route\tPRIEST\t1\tAlliance\t1\t60\tQA%20fixture'
local function step(kind,id,o,min,text)
 return table.concat({kind,id or 0,o or 0,1429,48,43,min or 0,30,0,text or 'QA%20step','','',0,''},'\t')
end
local text=header..'\n'..step('accept',90001)..'\n'..step('objective',90001,1)..'\n'..step('turnin',90001)..'\n'..step('train')
check(P.ImportRoute(text),'compatible data-only route imports')
local r=P.char.route
check(r.name=='QA route' and #r.steps==4 and r.index==1,'route header/order preserved')
P.AdvanceRoute();check(r.index==1,'unaccepted quest does not advance')
TEST_QUEST_ACTIVE[90001]=true;P.AdvanceRoute();check(r.index==2,'acceptance advances exactly one pending objective')
C_QuestLog.GetQuestObjectives=function()return {{finished=false,numFulfilled=2,numRequired=5}}end
check(select(2,P.RouteStepState(r.steps[2]))=='2 / 5','objective progress counts shown')
C_QuestLog.GetQuestObjectives=function()return {{finished=true,numFulfilled=5,numRequired=5}}end
P.AdvanceRoute();check(r.index==3,'finished objective advances to turn-in')
P.AdvanceRoute();check(r.index==3,'finished objectives never pretend quest was handed in')
TEST_QUEST_COMPLETED[90001]=true;P.AdvanceRoute();check(r.index==4,'completion flag advances turn-in')
P.AdvanceRoute();check(r.index==4,'training remains manual')
check(P.RouteManualNext() and r.index==5,'manual acknowledgement finishes non-quest step')
check(P.RouteUndo() and r.index==4 and r.auto==false,'undo pauses automatic progress and restores acknowledged step')
check(table.concat(P.RouteLines(false),' '):find('paused / undo review',1,true),'paused state visible')
local before=P.char.route
check(not P.ImportRoute(text:gsub('PRIEST','WARRIOR')) and P.char.route==before,'wrong-class import rejected transactionally')
check(not P.ImportRoute(text:gsub('Alliance','Horde')),'wrong-faction import rejected')
UnitRace=function()return 'Dwarf','Dwarf',3 end;check(not P.ImportRoute(text),'wrong-race import rejected');UnitRace=function()return 'Human','Human',1 end
UnitRace=nil;check(not P.RouteCompatibility(r),'unreadable race identity pauses instead of guessing');UnitRace=function()return 'Human','Human',1 end
for _,bad in ipairs({'return (function()error("executed")end)()',text..'\nwhile true do end',text:gsub('QA%%20route','bad%%GGroute'),header..'\n'..step('accept',0),header..'\n'..step('accept',90001,0,61),string.rep('a',1000001)}) do check(P.ParseRoute(bad)==nil,'malformed/oversized/code input rejected without execution') end
check(P.char.route==before,'failed parser inputs cannot replace saved route')
local prerequisite=step('accept',90002);prerequisite=prerequisite:gsub('\t\t\t0\t$', '\t90003\t90004,90005\t2\t')
local pre=P.ParseRoute(header..'\n'..prerequisite)
check(pre and #pre.steps[1].pre==1 and pre.steps[1].need==2,'AND/OR prerequisite metadata retained')
check(P.RouteStepState(pre.steps[1])=='blocked','unfinished AND prerequisite blocks recommendation')
TEST_QUEST_COMPLETED[90003]=true;TEST_QUEST_COMPLETED[90004]=true;check(P.RouteStepState(pre.steps[1])=='blocked','OR required count enforced')
TEST_QUEST_COMPLETED[90005]=true;check(P.RouteStepState(pre.steps[1])=='pending','fulfilled prerequisite set permits giver check')
P.char.route=P.ParseRoute(header..'\n'..step('accept',90001));TEST_QUEST_COMPLETED[90001]=true
TEST_COMBAT=true;P.AdvanceRoute();check(P.char.route.index==1,'combat does not advance route');TEST_COMBAT=false
local oldMap,oldPoint,oldSuper=C_Map,UiMapPoint,C_SuperTrack;local coordinates,marked
C_Map={CanSetUserWaypointOnMap=function()return true end,SetUserWaypoint=function(v)coordinates=v;return true end}
UiMapPoint={CreateFromCoordinates=function(m,x,y)return {map=m,x=x,y=y}end};C_SuperTrack={SetSuperTrackedUserWaypoint=function(v)marked=v end}
check(P.RouteWaypoint() and coordinates.map==1429 and coordinates.x==.48 and coordinates.y==.43 and marked,'map coordinate percentages normalized once')
UiMapPoint=nil;check(not P.RouteWaypoint(),'missing native helper yields readable fallback, no fabricated navigation')
C_Map,UiMapPoint,C_SuperTrack=oldMap,oldPoint,oldSuper
P.char.route=P.ParseRoute(header..'\n'..step('accept',90001))
P.AdvanceRoute();check(P.char.route.index==2,'observed completion catches up a restored route')
local many={header};for i=1,100 do many[#many+1]=step('accept',90001)end
P.char.route=P.ParseRoute(table.concat(many,'\n'));P.AdvanceRoute();check(P.char.route.index==41 and P.routeCatchup,'catch-up bounded to 40 per pass')
P.AdvanceRoute();P.AdvanceRoute();check(P.char.route.index==101 and not P.routeCatchup,'bounded follow-up finishes without skipping pending work')
P.OpenPage('Now');check(P.uiCallSucceeded,'Now page renders after route completion')
for _,b in ipairs(P.itemControls)do check(not b:IsShown(),'detail controls hidden on Now')end
for _,b in ipairs(P.nowControls)do check(b:IsShown(),'route actions visible on Now')end
P.ShowRouteImport();check(P.routeImportBox~=nil and not P.IsPlannerShown(),'import uses isolated dialog');P.activeDialog:Hide()
P.ShowLaunchChecks();check(P.activeDialog~=nil,'launch check report available');P.activeDialog:Hide()
-- All-level bag upgrades work even when the external benchmark has expired.
local oldSnapshot,oldCompare=P.snapshot,P.CompareEquipment
P.snapshot={equipped={},errors={},bags={{id=99991,name='Bag upgrade',bag=0,slot=1,details={equipLoc='INVTYPE_CHEST',minLevel=40,stats={v=1}}}}}
P.CompareEquipment=function()return {before=10,after=15}end
for _,level in ipairs({40,55,60})do TEST_LEVEL=level;check(#P.BagUpgradeActions()==1,'observed bag upgrade available beyond level-30 catalogue')end
TEST_LEVEL=39;check(#P.BagUpgradeActions()==0,'future wearable requirement respected')
P.scanStale=true;check(#P.BagUpgradeActions()==0,'stale bags never recommended');P.scanStale=false
P.snapshot=oldSnapshot;P.CompareEquipment=oldCompare
local now,xp=10,90;TEST_LEVEL=30;GetTime=function()return now end;UnitXP=function()return xp end;UnitXPMax=function()return 100 end
check(P.StartSessionSample(),'session sample starts');now=30;xp=95;P.RecordSessionSample();check(not P.FinishSessionSample(),'short sample rejected')
TEST_LEVEL=31;xp=10;now=70;P.RecordSessionSample();check(P.FinishSessionSample(),'one-level XP rollover sample completes')
check(P.char.sessionSamples[1].xp==20 and P.char.sessionSamples[1].rate==1200,'observed XP includes correct rollover and time denominator')
UnitRace=old.race;P.char.route=old.route;TEST_QUEST_COMPLETED=old.complete;TEST_QUEST_ACTIVE=old.active;TEST_LEVEL=old.level;C_QuestLog.GetQuestObjectives=old.objectives;P.actualClass=old.actual;P.Profile(old.class,old.spec);GetTime=old.clock;UnitXP=old.xp;UnitXPMax=old.max;P.routeCatchup=false
print('PASS: '..n..' ordered-route, Now UI, navigation, all-level bags and session measurement assertions; APIs mocked')
