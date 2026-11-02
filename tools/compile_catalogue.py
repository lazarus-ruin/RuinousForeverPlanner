"""Compile cached source facts into a local class/spec catalogue (no runtime web calls)."""
import json,re
from pathlib import Path
from bs4 import BeautifulSoup
root=Path('research/crawl')
variants=json.loads((root/'lists.json').read_text()); facts=json.loads((root/'items.json').read_text()); quests=json.loads((root/'quests.json').read_text())
attrs={'Strength':'ITEM_MOD_STRENGTH_SHORT','Agility':'ITEM_MOD_AGILITY_SHORT','Stamina':'ITEM_MOD_STAMINA_SHORT','Intellect':'ITEM_MOD_INTELLECT_SHORT','Spirit':'ITEM_MOD_SPIRIT_SHORT','Spell Power':'ITEM_MOD_SPELL_POWER_SHORT','Healing':'ITEM_MOD_SPELL_HEALING_DONE_SHORT','Spell Damage':'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT','Attack Power':'ITEM_MOD_ATTACK_POWER_SHORT','Ranged Attack Power':'ITEM_MOD_RANGED_ATTACK_POWER_SHORT','Armor':'RESISTANCE0_NAME','Health':'ITEM_MOD_HEALTH_SHORT','Mana':'ITEM_MOD_MANA_SHORT'}
previous=json.loads(Path('research/catalogue.json').read_text(encoding='utf8'))['items'] if Path('research/catalogue.json').exists() else {}
items={}
for key,fact in facts.items():
 if key in previous: name=previous[key]['name']
 else:
  page=BeautifulSoup((root/('item__'+key+'.html')).read_text(encoding='utf8'),'html.parser')
  name=page.select_one('h1'); name=name.get_text(' ',strip=True) if name else 'Item '+key
 stats={}
 for line in fact['lines']:
  for label,field in attrs.items():
   m=re.fullmatch(r'(?:Equip: )?\+?(\d+) '+re.escape(label),line)
   if m: stats[field]=stats.get(field,0)+int(m[1])
  m=re.search(r'Restores (\d+) mana per 5 sec',line,re.I)
  if m: stats['ITEM_MOD_MANA_REGENERATION_SHORT']=int(m[1])
 loc=None
 for line in fact['lines']:
  if re.match(r'^(?:Off Hand )?Shield\b',line): loc='INVTYPE_SHIELD';break
  if re.match(r'^Held In Off.hand\b',line,re.I): loc='INVTYPE_HOLDABLE';break
  for prefix,kind in [('Two-Hand','INVTYPE_2HWEAPON'),('Main Hand','INVTYPE_WEAPONMAINHAND'),('One-Hand','INVTYPE_WEAPON'),('Off Hand','INVTYPE_WEAPONOFFHAND'),('Ranged','INVTYPE_RANGED'),('Relic','INVTYPE_RELIC')]:
   if line==prefix or line.startswith(prefix+' '):loc=kind;break
  if loc:break
 items[key]=dict(sourceEquipLoc=loc,id=fact['id'],name=name,source=fact['source'],confirmed=fact['confirmed'],sourceMinLevel=fact['minLevel'],sourceStats=stats,sourceLines=fact['lines'],description=fact['description'],questIDs=fact['quests'])
rows={}
for v in variants:
 clean=[]
 for row in v['candidates']:
  f=items[str(row['id'])]
  if f['sourceMinLevel'] and f['sourceMinLevel']>30: continue
  r=dict(row); r['randomSuffix']=row['name']!=f['name']
  # Keep factual source/acquisition labels; discard drop percentage and narrative notes.
  r['acquisition']=re.sub(r'\d+(?:\.\d+)?% in Classic','',r['acquisition']).strip()
  clean.append(r)
 rows[v['path']]=dict(title=v['title'],className=v['class'],source='https://foreverchanges.pro'+v['path'],candidates=clean)
profiles=json.loads(Path('research/content.json').read_text())['profiles']
profiles['DRUID'].append('Feral (Tank)');profiles['PALADIN'].append('Shockadin');profiles['ROGUE'].append('Subtlety (Hemo)')
mapping={}
for cls,specs in profiles.items():
 for spec in specs:
  for context in ['PvE','PvP']:
   pvp=context=='PvP'; base='/bis/'+cls.lower(); suffix=''; shared=False; role='caster'
   if cls=='WARRIOR': suffix='/tank' if spec=='Protection' else '/pvp' if pvp else '';role='tank' if spec=='Protection' else 'strength';shared=spec!='Protection' or pvp
   if cls=='HUNTER': suffix='/pvp' if pvp else '';role='ranged';shared=True
   if cls=='MAGE': suffix=('/arcane' if spec=='Arcane' else '/fire-pvp' if pvp and spec=='Fire' else '/fire' if spec=='Fire' else '/pvp' if pvp else '');shared=spec=='Arcane' and pvp
   if cls=='WARLOCK': suffix='/pvp' if pvp else '';shared=True
   if cls=='ROGUE': suffix='/pvp-hemo' if spec=='Subtlety (Hemo)' else '/pvp' if pvp or spec=='Subtlety' else '/assassination' if spec=='Assassination' else '';role='agility';shared=(pvp and spec in ['Combat','Assassination']) or (not pvp and spec.startswith('Subtlety'))
   if cls=='PRIEST': suffix='/discipline-pvp' if pvp and spec!='Shadow' else '/shadow-pvp' if pvp else '' if spec=='Shadow' else '/holy';role='healer' if spec!='Shadow' else 'caster';shared=(spec=='Discipline' and not pvp) or (spec=='Holy' and pvp)
   if cls=='PALADIN': suffix='/holy-pvp' if spec=='Holy' and pvp else '/holy' if spec=='Holy' else '/tank' if spec=='Protection' else '/shockadin' if spec=='Shockadin' else '/retribution-pvp' if pvp else '';role='healer' if spec=='Holy' else 'tank' if spec=='Protection' else 'caster' if spec=='Shockadin' else 'strength';shared=(spec=='Protection' and pvp) or (spec=='Shockadin' and not pvp)
   if cls=='DRUID': suffix='/tank' if spec=='Feral (Tank)' else '/balance-pvp' if spec=='Balance' and pvp else '/balance' if spec=='Balance' else '/restoration-pvp' if spec=='Restoration' and pvp else '/restoration' if spec=='Restoration' else '/feral-pvp' if pvp else '';role='agilityTank' if spec=='Feral (Tank)' else 'agility' if spec=='Feral' else 'healer' if spec=='Restoration' else 'caster';shared=spec=='Feral (Tank)' and pvp
   if cls=='SHAMAN': suffix='/restoration' if spec=='Restoration' else '/enhancement-pvp' if spec=='Enhancement' and pvp else '/enhancement' if spec=='Enhancement' else '/elemental-pvp' if pvp else '';role='healer' if spec=='Restoration' else 'strength' if spec=='Enhancement' else 'caster';shared=spec=='Restoration' and pvp
   path=base+suffix
   assert path in rows,path
   mapping[cls+':'+spec+':'+context]=dict(path=path,role=role,shared=shared,note='Shared class / role reference; no dedicated list for this exact spec/context.' if shared else 'Published list for this class / role and context.')
# Curated chains remain authoritative overrides; these linked quest records are explicitly incomplete.
qrecords={}
for key,q in quests.items():
 qrecords[key]=dict(id=q['id'],name=q['name'],summary='Check '+q['name']+' objectives and reward choice in the live quest log.',faction=q['faction'],minLevel=q['minLevel'],previous=0,chainIncomplete=True,source=q['source'],evidence='Source-linked reward quest; prerequisites resolved through QuestieDB when available.')
data=dict(reviewed='2026-10-20',listVariants=rows,items=items,profileSources=mapping,profiles=profiles,quests=qrecords,crawl=json.loads((root/'report.json').read_text()))
Path('research/catalogue.json').write_text(json.dumps(data,indent=2),encoding='utf8')
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 return str(v).lower()
Path('RuinousForeverPlanner/SourceData.lua').write_text('local _,P=...\nP.SourceData='+lua(data)+'\nP.Data.profiles=P.SourceData.profiles\n',encoding='utf8')
print('Compiled',len(mapping),'profile/context mappings;',len(rows),'lists;',len(items),'items;',len(qrecords),'linked quest records')
