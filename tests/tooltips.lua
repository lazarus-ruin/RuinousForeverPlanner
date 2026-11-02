local P=TEST_P
local saved={details=P.ItemDetails,score=P.WeightedStatScore,report=P.OptimizationReport,snap=P.snapshot,supported=P.ProfileSupported}
local originalProjection=P.ProjectedItemRating
local n=0;local function check(v,m)n=n+1;assert(v,m)end
P.char.class=P.actualClass;P.char.ui.itemTooltips=true;P.scanStale=false;P.deferred=false
P.ProfileSupported=function()return true end
local value=75;local level=1;local loc='INVTYPE_ROBE';local reference
P.ItemDetails=function(link)reference=link;return {equipLoc=loc,minLevel=level,stats={v=value}}end
P.WeightedStatScore=function(stats)return stats and stats.v end
P.snapshot={equipped={[5]={details={stats={v=50}}}},errors={}}
P.OptimizationReport=function()return {percent=50,ratedSlots=1,slots={{slot=5,ratio=.5,best=100}}}end
P.ProjectedItemRating=function()return {percent=value,ratedSlots=1,totalSlots=17} end
local lines=table.concat(P.ItemRatingLines('item:123:0:0:0:0:77'),';')
check(reference=='item:123:0:0:0:0:77','exact suffix link passed to stat reader')
check(lines:find('+50.0%%') and lines:find('75.0%%') and lines:find('|cff40e080',1,true),'positive comparison and projected rating green')
value=25;lines=table.concat(P.ItemRatingLines('item:123'),';');check(lines:find('|cffff6060',1,true) and lines:find('25.0%%'),'negative comparison red')
level=61;check(table.concat(P.ItemRatingLines('item:123'),';'):find('requirement'),'future item never gets current rating');level=1
P.scanStale=true;check(table.concat(P.ItemRatingLines('item:123'),';'):find('scan gear'),'stale scan suppressed');P.scanStale=false
loc='INVTYPE_WEAPON';check(table.concat(P.ItemRatingLines('item:123'),';'):find('Main%-hand details'),'weapon tooltip explains missing weapon-set data');loc='INVTYPE_ROBE'
local tip={lines=4,added={},link='item:123:0:0:0:0:77'}
function tip:GetItem()return 'Auction / loot fixture',self.link end
function tip:NumLines()return self.lines end
function tip:AddLine(text)self.lines=self.lines+1;self.added[#self.added+1]=text end
P.AppendItemRating(tip);local count=tip.lines;check(count>4,'shared item tooltip receives appended ratings')
P.AppendItemRating(tip);check(tip.lines==count,'repeated callback does not duplicate')
tip.lines=4;P.AppendItemRating(tip);check(tip.lines==count,'rebuilt tooltip gets ratings again')
P.char.ui.itemTooltips=false;tip.lines=4;P.AppendItemRating(tip);check(tip.lines==4,'setting disables tooltip additions');P.char.ui.itemTooltips=true
function tip:IsForbidden()return true end
P.AppendItemRating(tip);check(tip.lines==4,'forbidden tooltip untouched')
local oldProcessor,oldEnum=TooltipDataProcessor,Enum
local callback;TooltipDataProcessor={AddTooltipPostCall=function(kind,fn)check(kind==99,'runtime item enum used');callback=fn end};Enum={TooltipDataType={Item=99}}
P.itemTooltipHookInstalled=false;check(P.InstallItemTooltipHook() and type(callback)=='function','shared tooltip hook registered');check(P.InstallItemTooltipHook(),'hook registration idempotent')
TooltipDataProcessor=oldProcessor;Enum=oldEnum;P.itemTooltipHookInstalled=false
P.ProjectedItemRating=originalProjection;P.ItemDetails=saved.details;P.WeightedStatScore=saved.score;P.OptimizationReport=saved.report;P.snapshot=saved.snap;P.ProfileSupported=saved.supported
print('PASS: '..n..' item tooltip assertions (mock Auction House / loot shared hook; live QA pending)')
