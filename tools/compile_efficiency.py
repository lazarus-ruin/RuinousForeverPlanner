"""Compile reviewed factual dungeon records; no timing, drop odds or XP invented."""
import json,re
from pathlib import Path
raw=json.loads(Path('research/dungeons/raw.json').read_text(encoding='utf8'))
slots={'Head':1,'Neck':2,'Shoulder':3,'Chest':5,'Waist':6,'Legs':7,'Feet':8,'Wrist':9,'Hands':10,'Finger':11,'Trinket':13,'Back':15,'Main Hand':16,'One-Hand':16,'Two-Hand':16,'Shield':17,'Held In Off-Hand':17,'Held In Off-hand':17,'Off-Hand':17,'Relic':18,'Off Hand':17,'Held In Off-hand':17,'Ranged':18,'Thrown':18}
out=[]
for d in raw:
 if d['id']=='upper-blackrock-spire':continue # Not certified as a five-player activity.
 entry={k:d[k] for k in ['id','name','min','max','zone','new','source']};entry['quests']=[];entry['items']=[];seen=set()
 def item(i,quest=None,boss=None):
  if not isinstance(i,dict) or not isinstance(i.get('i'),int):return
  key=(i['i'],quest,boss)
  if key in seen:return
  seen.add(key)
  lines=i.get('x') or [];slot=slots.get(i.get('s'))
  if not slot:
   for line in lines:
    if line.split('\t')[0] in slots:slot=slots[line.split('\t')[0]];break
  if not slot:return
  entry['items'].append({'id':i['i'],'name':i['n'],'slot':slot,'questID':quest,'boss':boss,'sourceMinLevel':i.get('r'),'source':'https://foreverchanges.pro/item/'+str(i['i']),'dungeonID':d['id']})
 for q in d['quests']:
  entry['quests'].append({'id':q['id'],'name':q['title'],'level':q.get('level'),'minLevel':q.get('min'),'faction':{'a':'Alliance','h':'Horde'}.get(q.get('side')),'xp':q.get('xpf') if q.get('forever') else None,'prerequisiteUnknown':bool(q.get('prev') or q.get('where') or q.get('starts')),'className':q.get('class'),'source':'https://foreverchanges.pro/quest/'+str(q['id'])})
  for field in ['choice','given']:
   for i in q.get(field,[]):item(i,q['id'])
 for b in d['bosses']:
  for i in b.get('items',[]):item(i,boss=b['name'])
 out.append(entry)
result={'reviewDate':'2026-10-20','dungeons':out,'note':'New dungeon ranges are source-attributed to Blizzard; Classic ranges are Group Finder reference ranges, unconfirmed in Forever. Quest XP is beta reference XP, not a live payout. No drop odds or clear times bundled.'}
Path('research/dungeons/catalogue.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf8')
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 return '{'+','.join('['+lua(str(k))+']='+lua(x) for k,x in v.items())+'}'
Path('RuinousForeverPlanner/EfficiencyData.lua').write_text('local _,P=...\nP.EfficiencyData='+lua(result)+'\n',encoding='utf8')
print('Compiled',len(out),'five-player dungeon references;',sum(len(d['quests']) for d in out),'quest rows;',sum(len(d['items']) for d in out),'reward/drop rows')
