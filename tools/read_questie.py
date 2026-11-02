from pathlib import Path
from urllib.request import urlopen,Request
import json
commit=json.loads(Path('research/questie/tree.json').read_text())['sha']
for name in ['.gitmodules','Questie_Camelot.toc','Database/QuestieDB.lua','FOREVER_WORK_LEFT_TO_DO.md','README.md']:
 try:
  raw=urlopen(Request('https://raw.githubusercontent.com/Questie/Questie/'+commit+'/'+name,headers={'User-Agent':'RuinousForeverPlanner'}),timeout=20).read().decode()
  Path('research/questie',name.replace('/','__')).write_text(raw,encoding='utf8')
  if name=='.gitmodules': print(raw)
 except Exception as e: print(name,e)
