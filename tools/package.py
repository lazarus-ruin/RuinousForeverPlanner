from pathlib import Path
import zipfile,json,hashlib,re
root=Path.cwd()
out=root/'output'
test_match=re.search(r'(\d+) mocked behavior assertions',(out/'test-results.txt').read_text(encoding='utf-8-sig'))
assert test_match, 'Missing recorded test results'
test_count=test_match.group(1)
from pypdf import PdfReader
original=PdfReader('research/original-v0.5.pdf')
revised=PdfReader('output/pdf/Ruinous-Forever-Planner-PRD-v0.22.pdf')
assert all(original.pages[i].extract_text()==revised.pages[len(revised.pages)-len(original.pages)+i].extract_text() for i in range(len(original.pages))), 'Original PRD baseline not preserved'
reqs=json.loads((root/'research/requirements.json').read_text())
assert [r[0] for r in reqs]==['FR-%02d'%i for i in range(1,29)], 'Incomplete requirement traceability'
addon=out/'RuinousForeverPlanner-0.22.0.zip'
with zipfile.ZipFile(addon,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted((root/'RuinousForeverPlanner').glob('*')):
        if p.is_file(): z.write(p,p.relative_to(root))
with zipfile.ZipFile(addon) as z:
    assert z.testzip() is None
    names=set(z.namelist())
    for f in ['RuinousForeverPlanner.toc','RuinousForeverPlanner_Camelot.toc','Data.lua','SourceData.lua','Catalog.lua','Core.lua','Inspection.lua','EnchantData.lua','Enchants.lua','Upgrades.lua','EquipmentModel.lua','ClassGuidance.lua','AutoProfile.lua','ProfessionData.lua','Professions.lua','Baseline.lua','ClassQuests.lua','SellAdvisor.lua','Quests.lua','Planner.lua','Optimization.lua','EfficiencyData.lua','Efficiency.lua','SessionSample.lua','Route.lua','NextAction.lua','Diagnostics.lua','UI.lua','Controls.lua','ItemTooltips.lua','README.md','SOURCES.md','START-HERE.html','USAGE_GUIDE.md','ROUTE-CONVERTER.html','OFFLINE-RELEASE-REPORT.md']:
        assert 'RuinousForeverPlanner/'+f in names
    for f in ['Data.lua','SourceData.lua','Catalog.lua','Core.lua','Inspection.lua','EnchantData.lua','Enchants.lua','Upgrades.lua','EquipmentModel.lua','ClassGuidance.lua','AutoProfile.lua','ProfessionData.lua','Professions.lua','Baseline.lua','ClassQuests.lua','SellAdvisor.lua','Quests.lua','Planner.lua','Optimization.lua','EfficiencyData.lua','Efficiency.lua','SessionSample.lua','Route.lua','NextAction.lua','Diagnostics.lua','UI.lua','Controls.lua','ItemTooltips.lua']:
        assert z.read('RuinousForeverPlanner/'+f)==(root/'RuinousForeverPlanner'/f).read_bytes()
# Optional one-download dependency bundle, with unchanged runtime and matching source.
dep=json.loads((root/'third_party/manifest.json').read_text())
for name,digest in dep['files'].items():
    assert hashlib.sha256((root/'third_party/QuestieDB'/name).read_bytes()).hexdigest()==digest
bundle=out/'RuinousForeverPlanner-0.22.0-with-QuestieDB.zip'
with zipfile.ZipFile(bundle,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted((root/'RuinousForeverPlanner').glob('*')):
        if p.is_file(): z.write(p,p.relative_to(root))
    for p in sorted((root/'third_party/QuestieDB').rglob('*')):
        if p.is_file(): z.write(p,p.relative_to(root/'third_party'))
    z.write(root/'third_party'/dep['sourceArchive'],'QuestieDB-source/'+dep['sourceArchive'])
    z.write(root/'third_party/manifest.json','QuestieDB-source/manifest.json')
    z.writestr('INSTALL-BOTH.txt','Close WoW. Copy RuinousForeverPlanner and QuestieDB into Interface/AddOns. Keep one QuestieDB folder; do not overwrite a newer working version. Enable both addons. QuestieDB-source contains matching upstream source; it is not another addon. QuestieDB is an independent upstream dependency, not the full Questie map UI. Read QuestieDB/LICENSE.md and gpl-3.0.md. Runtime files are unchanged. No live acceptance is claimed.\n')
with zipfile.ZipFile(bundle) as z: assert z.testzip() is None
manifest={
    'version':'0.22.0','buildDate':'2026-10-30','reviewDate':'2026-10-20','clientTested':False,'orderedRoutes':{'wireFormat':'RFP1','upstreamJSONFormats':[1,2],'maxSteps':5000,'liveClientTested':False,'navigation':'guarded native destination marker; no pathfinder'},'questieDependency':{'version':dep['version'],'sourceCommit':dep['sourceCommit'],'unchangedRuntime':True,'sourceIncluded':True},'classQuests':{'source':'QuestieDB contract 4','classes':9,'liveClientTested':False},'sellAdvisor':{'vendorHistory':True,'marketValues':'manual net estimates','disenchantYield':'not predicted','liveClientTested':False},'professions':{'guides':12,'foreverSourceSummaries':10,'classicHeuristics':2,'recipeCoverage':'partial','liveClientTested':False},'enchants':{'sourceRecords':165,'staticEffectsParsed':103,'referenceLevel':30,'liveClientTested':False},'efficiency':{'horizonLevels':10,'dungeonReferences':34,'sourceQuestRows':331,'rewardAndDropRows':2058,'liveClientTested':False},'catalogue':{'lists':38,'distinctItems':634,'sourceConfirmedItems':621,'accessibleQuestPages':110,'profileContexts':60,'installedQuestieBaselineIDs':5226},
    'referenceAPI':{'interface':16001,'build':'70170','exportedAt':'2026-10-01 21:34:30','sha256':hashlib.sha256((root/'research/api.json').read_bytes()).hexdigest()},
    'document':{'pages':len(revised.pages),'originalPagesPreserved':len(original.pages),'requirementsMapped':len(reqs)},
    'checks':['Lua 5.1 grammar','Native Lua 5.1 execution (lupa 2.8)',test_count+' mocked assertions','UI mock smoke','level coverage','TOC resolution','scanner API symbols','gear schema','ZIP CRC and source-byte match'],
    'knownLimits':['Original PRD v0.5 reconciled; full production requirements tracked separately','Classic route unverified in Forever','Imported source lists describe level 30; shared mappings and unknown item wear/eligibility remain labeled','Live client acceptance pending'],
    'outputs':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [addon,bundle,out/'pdf/Ruinous-Forever-Planner-PRD-v0.22.pdf',out/'Ruinous-Forever-Planner-PRD-v0.22.md']}}
install_report=out/'installation-report.json'
if install_report.exists():
    install=json.loads(install_report.read_text(encoding='utf-8-sig'))
    if install.get('version')==manifest['version']:
        manifest['localStaging']={k:install[k] for k in ['version','clientVersion','destination','clientWasRunning','restartRequired','inGameTested']}
(out/'validation-manifest.json').write_text(json.dumps(manifest,indent=2))
kit=out/'RuinousForeverPlanner-0.22.0-source.zip'
with zipfile.ZipFile(kit,'w',zipfile.ZIP_DEFLATED) as z:
    for folder in ['RuinousForeverPlanner','tests']:
        for p in sorted((root/folder).rglob('*')):
            if p.is_file(): z.write(p,p.relative_to(root))
    for p in sorted((root/'tools').glob('*')):
        if p.is_file(): z.write(p,p.relative_to(root))
    for f in ['release.json','research/content.json','research/api-used.json','research/api.json','research/requirements.json','research/original-v0.5.pdf','BUILD_STATUS.md','output/validation-manifest.json','output/test-results.txt']:
        z.write(root/f,f)
    z.write(root/'research/guide-milestones.json','research/guide-milestones.json')
    for f in ['research/catalogue.json','research/crawl/lists.json','research/crawl/items.json','research/crawl/quests.json','research/crawl/report.json','research/questie/installed-baseline-ids.json','research/dungeons/catalogue.json','research/dungeons/raw.json','research/dungeons-page.html','research/enchants.json','research/professions.json']:
        z.write(root/f,f)
    z.write(root/'third_party/manifest.json','third_party/manifest.json')
    if manifest.get('localStaging'): z.write(install_report,'output/installation-report.json')
with zipfile.ZipFile(kit) as z: assert z.testzip() is None
print('Verified addon ZIP:',addon.stat().st_size,'bytes; source ZIP:',kit.stat().st_size,'bytes')
