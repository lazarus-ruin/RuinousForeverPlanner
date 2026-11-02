const fs=require('fs'), path=require('path');
const parse=require('luaparse'), {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
let files=fs.readdirSync('RuinousForeverPlanner').filter(x=>x.endsWith('.lua'));
for(const f of files) parse.parse(fs.readFileSync('RuinousForeverPlanner/'+f,'utf8'),{luaVersion:'5.1'});
console.log('PASS: all addon files parse as Lua 5.1');
const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(s,name){const b=to_luastring(s);if(lauxlib.luaL_loadbuffer(L,b,b.length,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/mock.lua','utf8'),'mock');
for(const f of ['Data.lua','SourceData.lua','Catalog.lua','Core.lua','Inspection.lua','EnchantData.lua','Enchants.lua','Upgrades.lua','EquipmentModel.lua','ClassGuidance.lua','AutoProfile.lua','ProfessionData.lua','Professions.lua','Baseline.lua','ClassQuests.lua','SellAdvisor.lua','Quests.lua','Planner.lua','Optimization.lua','EfficiencyData.lua','Efficiency.lua','SessionSample.lua','Route.lua','NextAction.lua','Diagnostics.lua','UI.lua','Controls.lua','ItemTooltips.lua'])run('assert(loadstring('+JSON.stringify(fs.readFileSync('RuinousForeverPlanner/'+f,'utf8'))+'))("RuinousForeverPlanner", TEST_P)','load '+f);
run(fs.readFileSync('tests/behavior.lua','utf8'),'behavior');
run(fs.readFileSync('tests/catalogue.lua','utf8'),'catalogue');
run(fs.readFileSync('tests/optimization.lua','utf8'),'optimization');
run(fs.readFileSync('tests/tooltips.lua','utf8'),'tooltips');
run(fs.readFileSync('tests/efficiency.lua','utf8'),'efficiency');
run(fs.readFileSync('tests/enchants_offhands.lua','utf8'),'enchants_offhands');
run(fs.readFileSync('tests/alt_layering.lua','utf8'),'alt_layering');
run(fs.readFileSync('tests/professions_profile_loot.lua','utf8'),'professions_profile_loot');
run(fs.readFileSync('tests/classquests_sell.lua','utf8'),'classquests_sell');
run(fs.readFileSync('tests/routes_next.lua','utf8'),'routes_next');
require('../tests/converter.js');
if(fs.existsSync('tmp/factoruide-real.rfp'))run('assert(TEST_P.ParseRoute('+JSON.stringify(fs.readFileSync('tmp/factoruide-real.rfp','utf8'))+'))','actual upstream route parser');
const data=JSON.parse(fs.readFileSync('research/content.json'));
const release=JSON.parse(fs.readFileSync('release.json'));
if(data.version!==release.version+'-prototype')throw Error('Data/release version mismatch');
for(const toc of ['RuinousForeverPlanner.toc','RuinousForeverPlanner_Camelot.toc'])if(!fs.readFileSync('RuinousForeverPlanner/'+toc,'utf8').includes('## Version: '+release.version))throw Error('TOC/release version mismatch');
for(let level=1;level<=60;level++)if(data.stages.filter(s=>level>=s.min&&level<=s.max).length!==1)throw Error('Stage coverage '+level);
const ids=data.stages.flatMap(s=>s.tasks.map(t=>t.id)); if(new Set(ids).size!==ids.length)throw Error('Duplicate task IDs');
for(const toc of ['RuinousForeverPlanner.toc','RuinousForeverPlanner_Camelot.toc'])for(const line of fs.readFileSync('RuinousForeverPlanner/'+toc,'utf8').split(/\r?\n/).filter(x=>x&&!x.startsWith('#')))if(!fs.existsSync('RuinousForeverPlanner/'+line))throw Error('TOC missing '+line);
console.log('PASS: levels 1-60 covered exactly once; unique checklist keys; both TOCs resolve');
const api=JSON.parse(fs.readFileSync('research/api.json'));
for(const [ns,names] of Object.entries({C_Container:['GetContainerNumSlots','GetContainerItemInfo'],C_Item:['GetItemInfo','GetItemStats','RequestLoadItemDataByID'],C_QuestLog:['IsQuestFlaggedCompleted','IsOnQuest']}))for(const name of names)if(!api.systems.some(s=>s.namespace===ns&&s.functions.some(f=>f.name===name)))throw Error('API unverified '+ns+'.'+name);
for(const name of ['GetInventoryItemID','GetInventoryItemLink','UnitGUID','CreateFrame','issecretvalue'])if(api.globals[name]!=='function')throw Error('Global unverified '+name);
console.log('PASS: scanner API symbols present in exported Forever build 70170');
const targetIDs=new Set();
for(const stage of data.stages){const m=stage.milestones; if(!m||!['alliance','horde','gear','craft','gate','evidence'].every(k=>typeof m[k]==='string'&&m[k].length>15)||!m.sources.every(k=>data.sources[k]))throw Error('Incomplete named milestones '+stage.min);}
console.log('PASS: all 13 stage milestones include faction quests, equipment, crafting, gates and resolving sources');
for(const g of data.gear){if(!Number.isInteger(g.id)||g.id<=0||targetIDs.has(g.id)||g.min>g.max||!['solo','group'].includes(g.mode)||!g.source.startsWith('https://foreverchanges.pro/item/'))throw Error('Invalid gear record'); targetIDs.add(g.id);}
console.log('PASS: verified sample records have unique IDs, valid windows, activity labels and source URLs');
const quests=new Map(data.quests.map(q=>[q.id,q]));
if(quests.size!==data.quests.length)throw Error('Duplicate quest ID');
for(const q of data.quests){let p=q,visited=new Set();while(p){if(visited.has(p.id))throw Error('Quest cycle');visited.add(p.id);if(p.previous&&!quests.has(p.previous))throw Error('Missing prerequisite');p=quests.get(p.previous);}}
for(const name of ['QUEST_LOG_UPDATE','QUEST_TURNED_IN'])if(!api.systems.some(s=>(s.events||[]).some(e=>e.literalName===name)))throw Error('Unverified quest event '+name);
console.log('PASS: source-linked quest graph is acyclic, references existing IDs, and refresh events are exported');
if(!api.systems.some(s=>(s.tables||[]).some(t=>t.name==='BagIndex'&&(t.fields||[]).some(f=>f.name==='ReagentBag'&&f.enumValue===5))))throw Error('Reagent bag index not supported by export');
console.log('PASS: optional reagent bag index is present in the Forever enum export');

for(const reward of data.questRewards||[]){
 if(!reward.source.startsWith('https://foreverchanges.pro/item/')||reward.min>reward.max)throw Error('Invalid quest reward');
 for(const [faction,id] of Object.entries(reward.questByFaction||{}))if(!quests.has(id)||quests.get(id).faction!==faction)throw Error('Invalid faction reward quest');
}
console.log('PASS: additional quest reward sources and faction-specific quest references resolve');

for(const toc of ['RuinousForeverPlanner.toc','RuinousForeverPlanner_Camelot.toc'])if(!/^## Title: Ruinous Forever Planner\r?$/m.test(fs.readFileSync('RuinousForeverPlanner/'+toc,'utf8')))throw Error('Addon display name mismatch');

for(const name of ['UnitXP','UnitXPMax','GetTime','GetLocale','GetRealZoneText'])if(api.globals[name]!=='function')throw Error('Efficiency API missing '+name);
for(const [ns,name] of [['C_Map','GetAreaInfo'],['C_TooltipInfo','GetHyperlink']])if(!api.systems.some(s=>s.namespace===ns&&s.functions.some(f=>f.name===name)))throw Error('Efficiency API missing '+ns+'.'+name);
console.log('PASS: efficiency XP, area-name and tooltip API symbols verified against Forever export');

for(const n of ['GetProfessions','GetProfessionInfo','hooksecurefunc','GetLootSlotLink'])if(api.globals[n]!=='function')throw Error('Profession/tooltip API missing '+n);
for(const n of ['GetSpecialization','GetSpecializationInfo'])if(!api.systems.some(s=>s.namespace==='C_SpecializationInfo'&&s.functions.some(f=>f.name===n)))throw Error('Spec API missing '+n);

for(const [ns,n] of [['C_MerchantFrame','GetItemInfo'],['C_SpellBook','ContainsAnyDisenchantSpell']])if(!api.systems.some(s=>s.namespace===ns&&s.functions.some(f=>f.name===n)))throw Error('Vendor API missing '+n);
for(const n of ['GetMerchantNumItems','GetMerchantItemLink','UnitName','time'])if(api.globals[n]!=='function')throw Error('Vendor API missing '+n);

for(const [ns,n] of [['C_QuestLog','GetQuestObjectives'],['C_Map','SetUserWaypoint'],['C_Map','CanSetUserWaypointOnMap'],['C_SuperTrack','SetSuperTrackedUserWaypoint']])if(!api.systems.some(s=>s.namespace===ns&&s.functions.some(f=>f.name===n)))throw Error('Route API missing '+n);
