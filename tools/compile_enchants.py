"""Compile factual Forever enchanting records; unsupported effects remain unscored."""
import json,re
from pathlib import Path
if Path('research/enchanting-flight.txt').exists():
 s=Path('research/enchanting-flight.txt').read_text(encoding='utf8');dec=json.JSONDecoder()
 def prop(k):return dec.raw_decode(s[s.index('"'+k+'":')+len(k)+3:])[0]
 enchants=prop('enchants');recipes=prop('recipes')
 byname={r['name']:int(k) for k,r in recipes.items()}
 labels={'Strength':'ITEM_MOD_STRENGTH_SHORT','Agility':'ITEM_MOD_AGILITY_SHORT','Stamina':'ITEM_MOD_STAMINA_SHORT','Intellect':'ITEM_MOD_INTELLECT_SHORT','Spirit':'ITEM_MOD_SPIRIT_SHORT','Armor':'RESISTANCE0_NAME','Spell Power':'ITEM_MOD_SPELL_POWER_SHORT','Healing Spells':'ITEM_MOD_SPELL_HEALING_DONE_SHORT','Damage Spells':'ITEM_MOD_SPELL_DAMAGE_DONE_SHORT','Health':'ITEM_MOD_HEALTH_SHORT','Mana':'ITEM_MOD_MANA_SHORT'}
 def stats(text):
  result={};text=text.strip()
  if re.fullmatch(r'All Stats \+\d+',text):
   v=int(text.split('+')[1]);return {labels[k]:v for k in ['Strength','Agility','Stamina','Intellect','Spirit']}
  for chunk in re.split(r',|/| and ',text):
   chunk=chunk.strip();m=re.fullmatch(r'(.+?) \+(\d+)',chunk) or None
   if m:label,v=m[1],int(m[2])
   else:
    m=re.fullmatch(r'\+(\d+) (.+)',chunk)
    if m:label,v=m[2],int(m[1])
    else:
     m=re.fullmatch(r'Mana Regen (\d+) per 5 sec\.',chunk)
     if m:result['ITEM_MOD_MANA_REGENERATION_SHORT']=int(m[1]);continue
     return None
   if label not in labels:return None
   result[labels[label]]=result.get(labels[label],0)+v
  return result
 out=[]
 for e in enchants:
  out.append({'name':e['name'],'group':e['group'],'stats':stats(e['text']),'skill':e['learn'],'recipeID':byname.get(e['name']),'formulaID':e['formula']['id'] if e.get('formula') else None,'reagents':e['reagents'],'profiles':[x['href'] for x in e['bis']],'source':'https://foreverchanges.pro/professions/enchanting'})
 result={'reviewed':'2026-10-20','referenceLevel':30,'enchants':out}
 Path('research/enchants.json').write_text(json.dumps(result,indent=2),encoding='utf8')
else:
 result=json.loads(Path('research/enchants.json').read_text(encoding='utf8'));out=result['enchants']
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return str(v)
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 return '{'+','.join('['+lua(str(k))+']='+lua(x) for k,x in v.items())+'}'
Path('RuinousForeverPlanner/EnchantData.lua').write_text('local _,P=...\nP.EnchantData='+lua(result)+'\n',encoding='utf8')
print('Compiled',len(out),'enchant facts;',sum(e['stats'] is not None for e in out),'static stat effects; others unscored')
