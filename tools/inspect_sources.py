import json,re,html
from pathlib import Path
a=json.load(open('research/api.json',encoding='utf8'))
names={'GetInventoryItemID','GetInventoryItemLink','UnitLevel','UnitClass','UnitGUID','UnitFactionGroup','GetBuildInfo','CreateFrame','InCombatLockdown','issecretvalue','UnitXP','UnitXPMax','GetTime','GetLocale','GetRealZoneText','GetMerchantNumItems','GetMerchantItemLink','UnitName','time','IsPlayerSpell','GetZoneText','GetProfessions','GetProfessionInfo','hooksecurefunc','GetLootSlotLink'}
out={'meta':a['meta'],'globals':{n:a['globals'].get(n) for n in sorted(names)},'systems':[]}
for s in a['systems']:
    fs=[f for f in s.get('functions',[]) if (s.get('namespace')=='C_Container' and f['name'] in ['GetContainerNumSlots','GetContainerItemInfo']) or (s.get('namespace')=='C_Item' and f['name'] in ['GetItemInfo','GetItemStats','RequestLoadItemDataByID']) or (s.get('namespace')=='C_SpecializationInfo' and f['name'] in ['GetSpecialization','GetSpecializationInfo']) or (s.get('namespace')=='C_Container' and f['name']=='GetContainerItemLink') or (s.get('namespace')=='C_MerchantFrame' and f['name']=='GetItemInfo') or (s.get('namespace')=='C_SpellBook' and f['name']=='ContainsAnyDisenchantSpell') or (s.get('namespace')=='C_Map' and f['name'] in ['GetAreaInfo','SetUserWaypoint','CanSetUserWaypointOnMap']) or (s.get('namespace')=='C_SuperTrack' and f['name']=='SetSuperTrackedUserWaypoint') or (s.get('namespace')=='C_TooltipInfo' and f['name']=='GetHyperlink') or (s.get('namespace')=='C_QuestLog' and f['name'] in ['IsQuestFlaggedCompleted','IsOnQuest','GetQuestObjectives'])]
    es=[e for e in s.get('events',[]) if e.get('literalName',e.get('name')) in ['PLAYER_LOGIN','PLAYER_LEVEL_UP','PLAYER_EQUIPMENT_CHANGED','BAG_UPDATE_DELAYED','ITEM_DATA_LOAD_RESULT','PLAYER_REGEN_ENABLED','QUEST_LOG_UPDATE','QUEST_TURNED_IN','PLAYER_XP_UPDATE','ZONE_CHANGED_NEW_AREA']]
    ts=[t for t in s.get('tables',[]) if t['name']=='BagIndex']
    if fs or es or ts: out['systems'].append({'name':s['name'],'namespace':s.get('namespace'),'functions':fs,'events':es,'tables':ts})
json.dump(out,open('research/api-used.json','w'),indent=2)
s=Path('research/holy.html').read_text(encoding='utf8') if Path('research/holy.html').exists() else ''
for m in re.finditer(r'href="([^"]+)"[^>]*>(.*?)</a>',s):
    t=html.unescape(re.sub('<[^>]+>','',m[2]))
    if any(n in t for n in ['Death Speaker Mantle','Holy Shroud','Staff of Westfall','Worgenbane','Truefaith','Pristine Gloves','Philanthropist']) or 'youtube' in m[1]: print(t[:100],m[1])
