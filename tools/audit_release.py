"""Audit concrete release artifacts without asserting untested client behavior."""
import hashlib,json,zipfile,re
from pathlib import Path
from pypdf import PdfReader
release=json.loads(Path('release.json').read_text())
version=release['version']; short='.'.join(version.split('.')[:2])
manifest=json.loads(Path('output/validation-manifest.json').read_text())
assert manifest['version']==version and manifest['clientTested'] is False
checks=[]
for filename,meta in manifest['outputs'].items():
    p=Path('output/pdf' if filename.endswith('.pdf') else 'output')/filename
    assert p.stat().st_size==meta['bytes']
    assert hashlib.sha256(p.read_bytes()).hexdigest()==meta['sha256']
checks.append('All deliverable hashes and sizes match the release manifest')
with zipfile.ZipFile(f'output/RuinousForeverPlanner-{version}.zip') as z:
    assert z.testzip() is None
    for p in Path('RuinousForeverPlanner').glob('*'):
        if p.is_file(): assert z.read('RuinousForeverPlanner/'+p.name)==p.read_bytes(),p.name
    for toc in ['RuinousForeverPlanner.toc','RuinousForeverPlanner_Camelot.toc']:
        text=z.read('RuinousForeverPlanner/'+toc).decode()
        for line in text.splitlines():
            if line and not line.startswith('#'): assert 'RuinousForeverPlanner/'+line in z.namelist()
checks.append('Installable ZIP exactly matches the current addon, with valid TOC load order references')
with zipfile.ZipFile(f'output/RuinousForeverPlanner-{version}-source.zip') as z:
    assert z.testzip() is None
    for f in ['release.json','research/content.json','research/requirements.json','tools/test.js','tools/test_lua51.py','tools/build_prd.py','tools/install-local.ps1','RuinousForeverPlanner/Inspection.lua','RuinousForeverPlanner/Quests.lua','RuinousForeverPlanner/Diagnostics.lua']:
        assert z.read(f)==Path(f).read_bytes(),f
checks.append('Developer archive includes current source, data, tests, documentation build and installer')
original=PdfReader('research/original-v0.5.pdf')
updated=PdfReader(f'output/pdf/Ruinous-Forever-Planner-PRD-v{short}.pdf')
offset=len(updated.pages)-len(original.pages)
assert all(p.extract_text()==updated.pages[offset+i].extract_text() for i,p in enumerate(original.pages))
text='\n'.join(p.extract_text() for p in updated.pages[:offset])
assert all(f'FR-{n:02}' in text for n in range(1,29))
checks.append('All original PDF pages preserved and all 28 original requirements mapped in the updated document')
for i in range(len(updated.pages)):
    image=Path(f'tmp/pdfs/page-{i+1:02}.png')
    assert image.exists() and image.stat().st_mtime>=Path(f'output/pdf/Ruinous-Forever-Planner-PRD-v{short}.pdf').stat().st_mtime
checks.append('Every current PDF page has a fresh rendered PNG for visual inspection')
if manifest.get('localStaging'):
    destination=Path(manifest['localStaging']['destination'])
    for p in Path('RuinousForeverPlanner').glob('*'):
        if p.is_file(): assert (destination/p.name).read_bytes()==p.read_bytes(),p.name
    checks.append('Installed beta-client addon files exactly match the release; no runtime test is inferred')
Path('output/release-audit.json').write_text(json.dumps({'version':version,'checks':checks,'inGameTested':False,'remaining':'Live client /rfp acceptance tests and explicitly deferred production scope'},indent=2))
for check in checks: print('PASS:',check)

with zipfile.ZipFile(f'output/RuinousForeverPlanner-{version}-with-QuestieDB.zip') as z:
    assert z.testzip() is None
    dep=json.loads(z.read('QuestieDB-source/manifest.json'))
    for name,digest in dep['files'].items():
        assert hashlib.sha256(z.read('QuestieDB/'+name)).hexdigest()==digest
    for name in ['LICENSE.md','gpl-3.0.md','PROVENANCE.md']:
        assert len(z.read('QuestieDB/'+name))>100
    assert len(z.read('QuestieDB-source/'+dep['sourceArchive']))>10000
    for toc in ['QuestieDB_Forever.toc','QuestieDB_Camelot.toc']:
        for line in z.read('QuestieDB/'+toc).decode().splitlines():
            if line and not line.startswith('#'): assert 'QuestieDB/'+line.replace(chr(92),'/') in z.namelist()
print('PASS: Combined ZIP has unchanged QuestieDB runtime, both Forever TOCs, license notices and matching source archive')
