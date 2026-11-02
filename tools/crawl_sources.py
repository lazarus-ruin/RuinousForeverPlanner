"""Crawl public ForeverChanges list variants and linked factual item/quest records.
Caching, bounded concurrency and a request delay keep repeat builds offline.
"""
import json,re,time,hashlib,threading
from pathlib import Path
from urllib.request import Request,urlopen
from concurrent.futures import ThreadPoolExecutor,as_completed
from bs4 import BeautifulSoup
BASE='https://foreverchanges.pro'
ROOT=Path('research/crawl'); ROOT.mkdir(parents=True,exist_ok=True)
errors={}; lock=threading.Lock()
def fetch(path):
 target=ROOT/(path.strip('/').replace('/','__') or 'index')
 target=target.with_suffix('.html')
 if target.exists(): return BeautifulSoup(target.read_text(encoding='utf8'),'html.parser')
 for attempt in range(2):
  try:
   time.sleep(.25)
   with urlopen(Request(BASE+path,headers={'User-Agent':'RuinousForeverPlanner research prototype (offline addon; public factual source review)'}),timeout=25) as response:
    raw=response.read().decode('utf8')
   target.write_text(raw,encoding='utf8')
   return BeautifulSoup(raw,'html.parser')
  except Exception as e:
   if attempt: errors[path]=str(e)
 return None
def parallel(paths):
 result={}
 with ThreadPoolExecutor(max_workers=3) as pool:
  jobs={pool.submit(fetch,p):p for p in sorted(paths)}
  for f in as_completed(jobs): result[jobs[f]]=f.result()
 return result
index=fetch('/bis')
if not index: raise SystemExit('Index unavailable')
paths={a['href'] for a in index.select('a[href]') if re.fullmatch(r'/bis/(warrior|hunter|mage|rogue|priest|warlock|paladin|druid|shaman)(/[a-z-]+)?',a['href'])}
print('List variants discovered:',len(paths),flush=True)
pages=parallel(paths)
slotmap={'head':1,'neck':2,'shoulder':3,'back':15,'chest':5,'wrist':9,'hands':10,'waist':6,'legs':7,'feet':8,'finger':11,'trinket':13,'relic':18,'two-hand':16,'held':17,'shield':17,'offhand':17,'two-hand-weapon':16,'main-hand':16,'off-hand':17,'ranged':18}
variants=[]; itemids=set()
for path,page in pages.items():
 if not page: continue
 title=page.select_one('h1')
 variant={'path':path,'class':path.split('/')[2].upper(),'title':title.get_text(' ',strip=True) if title else '', 'candidates':[]}
 for section in page.select('section.bis-slot'):
  slot=slotmap.get(section.get('id','').removeprefix('slot-'))
  if not slot:
   if section.get('id','').startswith('slot-'): raise RuntimeError('Unmapped source gear slot: '+section.get('id',''))
   continue
  for rank,row in enumerate(section.select('li.bis-row')):
   a=row.select_one('a.bis-name[href]')
   if not a: continue
   match=re.fullmatch(r'/item/(\d+)',a['href'])
   if not match: continue
   itemid=int(match[1]); itemids.add(itemid)
   frm=row.select_one('.bis-from'); mats=row.select_one('.bis-mats')
   links=[dict(url=BASE+x['href'],label=x.get_text(' ',strip=True)) for x in (frm.select('a[href]') if frm else []) if x['href'].startswith('/')]
   variant['candidates'].append(dict(id=itemid,name=a.get_text(' ',strip=True),slot=slot,rank=rank+1,acquisition=frm.get_text(' ',strip=True) if frm else '',materials=mats.get_text(' ',strip=True) if mats else '',links=links))
 variants.append(variant)
print('List variants parsed:',len(variants),'unique linked items:',len(itemids),flush=True)
(ROOT/'lists.json').write_text(json.dumps(variants,indent=2),encoding='utf8')
items=parallel({'/item/'+str(i) for i in itemids})
facts={}; questids=set()
for path,page in items.items():
 if not page: continue
 iid=int(path.rsplit('/',1)[1]); beta=page.select_one('.it-beta')
 tip=next((x for x in page.select('.it-tip') if 'Forever' in x.get_text(' ',strip=True)[:150]),None)
 if not tip: tip=next((x for x in page.select('.it-tip') if x.select_one('.it-label') and 'Forever' in x.select_one('.it-label').get_text()),None)
 if not tip: continue
 lines=[x.get_text(' ',strip=True) for x in tip.select('.it-line') if 'it-del' not in x.get('class',[])]
 text=' '.join(lines); level=re.search(r'Requires Level\s*(\d+)',text,re.I)
 source=page.select_one('.it-from')
 links=[int(re.search(r'/quest/(\d+)',a['href']).group(1)) for a in (source.select('a[href]') if source else []) if re.fullmatch(r'/quest/\d+',a['href'])]
 questids.update(links)
 sub=page.select_one('.it-sub')
 facts[iid]=dict(id=iid,confirmed=bool(beta and 'Confirmed in game' in beta.get_text()),status=beta.get_text(' ',strip=True) if beta else 'Unknown',minLevel=int(level[1]) if level else None,lines=lines,description=sub.get_text(' ',strip=True) if sub else '',quests=links,source=BASE+path)
print('Item pages parsed:',len(facts),'reward quests:',len(questids),flush=True)
(ROOT/'items.json').write_text(json.dumps(facts,indent=2),encoding='utf8')
questpages=parallel({'/quest/'+str(i) for i in questids})
quests={}
for path,page in questpages.items():
 if not page: continue
 main=page.select_one('main'); text=main.get_text(' ',strip=True) if main else page.get_text(' ',strip=True)
 # Store source facts and links, not the full copyrighted quest narrative.
 h=page.select_one('h1'); qid=int(path.rsplit('/',1)[1])
 quests[qid]=dict(id=qid,name=h.get_text(' ',strip=True) if h else '',source=BASE+path,
  faction='Alliance' if re.search(r'quest for the Alliance',text) else 'Horde' if re.search(r'quest for the Horde',text) else None,
  minLevel=int(re.search(r'from level (\d+)',text)[1]) if re.search(r'from level (\d+)',text) else None,
  rewardIDs=sorted({int(re.search(r'/item/(\d+)',a['href'])[1]) for a in page.select('a[href]') if re.fullmatch(r'/item/\d+',a['href'])}),
  chainLinks=sorted({int(re.search(r'/quest/(\d+)',a['href'])[1]) for a in page.select('a[href]') if re.fullmatch(r'/quest/\d+',a['href']) and int(a['href'].rsplit('/',1)[1])!=qid}))
(ROOT/'quests.json').write_text(json.dumps(quests,indent=2),encoding='utf8')
report={'reviewDate':'2026-10-20','listVariants':len(variants),'uniqueLinkedItems':len(itemids),'parsedItems':len(facts),'questPages':len(quests),'errors':errors,'source':'https://foreverchanges.pro/bis','notClientTested':True}
(ROOT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='errors'}),'errors',len(errors),flush=True)
