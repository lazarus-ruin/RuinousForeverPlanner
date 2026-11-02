"""Cache public dungeon factual data; bounded requests, no runtime network."""
import json,re,time
from pathlib import Path
from urllib.request import Request,urlopen
from concurrent.futures import ThreadPoolExecutor
ROOT=Path('research/dungeons');ROOT.mkdir(exist_ok=True)
def flight(s):return ''.join(json.loads(m) for m in re.findall(r'self\.__next_f\.push\(\[1,("(?:[^"\\]|\\.)*")\]\)',s))
def prop(s,key):
 m=re.search(r'"'+key+r'":(?=[\[{])',s)
 return json.JSONDecoder().raw_decode(s[m.end():])[0] if m else None
index=flight(Path('research/dungeons-page.html').read_text(encoding='utf8'));dungeons=prop(index,'dungeons')
def fetch(d):
 p=ROOT/(d['id']+'.html')
 if not p.exists():
  time.sleep(.3)
  try:p.write_text(urlopen(Request('https://foreverchanges.pro/dungeons/'+d['id'],headers={'User-Agent':'RuinousForeverPlanner research prototype (offline addon; public factual source review)'}),timeout=25).read().decode(),encoding='utf8')
  except Exception as e:return {'id':d['id'],'error':str(e)}
 t=flight(p.read_text(encoding='utf8'));qs=prop(t,'quests') or [];bosses=prop(t,'bosses') or []
 return {'id':d['id'],'name':d['name'],'min':d['levels'][0],'max':d['levels'][1],'zone':d['zone'],'new':d['status']=='new','source':'https://foreverchanges.pro/dungeons/'+d['id'],'quests':qs,'bosses':bosses}
with ThreadPoolExecutor(max_workers=3) as pool:records=list(pool.map(fetch,dungeons))
Path('research/dungeons/raw.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
print('Dungeon pages',len(records),'quests',sum(len(d.get('quests',[])) for d in records),'errors',[(d['id'],d['error']) for d in records if 'error'in d])
print('boss sample',str(next((d['bosses'][:1] for d in records if d.get('bosses')),[]))[:2000].encode('ascii','backslashreplace').decode())
