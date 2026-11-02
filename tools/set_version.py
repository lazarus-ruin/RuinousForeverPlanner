"""Update current release sources without overwriting older downloadable releases."""
import json,re,sys
from pathlib import Path
new=sys.argv[1] if len(sys.argv)==2 else ''
if not re.fullmatch(r'\d+\.\d+\.\d+',new): raise SystemExit('Usage: python tools/set_version.py MAJOR.MINOR.PATCH')
p=Path('release.json'); release=json.loads(p.read_text()); old=release['version']
old_short='.'.join(old.split('.')[:2]); new_short='.'.join(new.split('.')[:2])
for name in ['tools/make_data.py','tools/build_prd.py','tools/render_pdf.py','tools/package.py',
             'RuinousForeverPlanner/UI.lua','RuinousForeverPlanner/RuinousForeverPlanner.toc','RuinousForeverPlanner/RuinousForeverPlanner_Camelot.toc','RuinousForeverPlanner/README.md']:
    file=Path(name); t=file.read_text(encoding='utf8').replace(old,new)
    if old_short!=new_short: t=t.replace(old_short,new_short)
    file.write_text(t,encoding='utf8')
release['version']=new; p.write_text(json.dumps(release,indent=2)+'\n')
print('Updated current sources to',new,'; regenerate data, test, document and package before publishing')
