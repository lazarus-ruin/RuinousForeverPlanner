from urllib.request import urlopen,Request
from pathlib import Path
import json
root=Path('research/questie');root.mkdir(exist_ok=True)
r=json.load(urlopen(Request('https://api.github.com/repos/Questie/Questie/git/trees/master?recursive=1',headers={'User-Agent':'RuinousForeverPlanner'}),timeout=30))
(root/'tree.json').write_text(json.dumps(r,indent=2))
print('COMMIT',r['sha'])
for x in r['tree']:
 p=x['path']
 if ('questDB' in p or 'QuestDB' in p or 'license' in p.lower() or 'LICENSE' in p or ('Database/Forever' in p) or p.endswith('QuestieDB.lua')): print(p)
