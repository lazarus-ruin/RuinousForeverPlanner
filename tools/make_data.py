"""Authoritative content input; emits the same Lua and JSON used by PDF/tests."""
import json
from pathlib import Path

sources={
'forever':'https://foreverchanges.pro/bis/priest/holy',
'api':'https://atraeau.github.io/WoW-Addons/',
'classic':'https://www.icy-veins.com/wow-classic/leveling-guide',
'alliance':'https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/',
'horde':'https://www.warcrafttavern.com/wow-classic/guides/horde-leveling-guide',
'priest':'https://www.icy-veins.com/wow-classic/classic-priest-leveling-guide',
'zf':'https://www.icy-veins.com/wow-classic/zul-farrak-quests-guide',
'st':'https://www.icy-veins.com/wow-classic/sunken-temple-quests-guide',
'quests30':'https://www.wow-pro.com/james-alliance-leveling-guide-chapter-i-30-41-old-version/',
'quests40':'https://www.wow-pro.com/james-alliance-leveling-guide-chapter-ii-40-50/',
'quests50':'https://www.wow-pro.com/james-horde-leveling-guide-chapter-iv-51-60-old-version-1-2/',
'starter':'https://www.wowhead.com/classic/quest=783/a-threat-within',
'crystals':'https://www.wowhead.com/classic/quest=4284/crystals-of-power',
'tirion':'https://www.wowhead.com/classic/quest=5542/demon-dogs',
'core':'https://www.wowhead.com/classic/guide/classic-wow-attunements-and-keys-dungeons-raids',
'defias':'https://foreverchanges.pro/quest/166',
'undeadStart':'https://www.wowhead.com/classic/quest=363/rude-awakening',
'trollStart':'https://www.wowhead.com/classic/quest=4641/your-place-in-the-world',
'candles':'https://www.wowhead.com/classic/quest=60/kobold-candles',
'chill':'https://www.wowhead.com/classic/quest=375/the-chill-of-death',
'oases':'https://www.wowhead.com/classic/quest=870/the-forgotten-pools',
'wcQuests':'https://www.wowhead.com/classic/guide/classic-wow-wailing-caverns-dungeon-quests',
'ashenvale':'https://www.wowhead.com/classic/quest=6383/the-ashenvale-hunt',
'priestQuests':'https://www.icy-veins.com/wow-classic/priest-quests-in-wow-classic',
'classicWeapons':'https://www.wowhead.com/classic/guide/wow-classic-best-priest-weapons',
'foreverWands':'https://www.icy-veins.com/wow-forever/frost-mage-leveling',
'fireWand':'https://foreverchanges.pro/item/5069',
'gravestone':'https://foreverchanges.pro/item/7001',
'smQuests':'https://www.icy-veins.com/wow-classic/scarlet-monastery-quests-guide',
'smLibrary':'https://www.icy-veins.com/wow-classic/scarlet-monastery-library-dungeon-guide',
'wandProgression':'https://www.warcrafttavern.com/wow-classic/guides/priest-leveling-guide/',
'morrow':'https://www.wowhead.com/classic/quest=2942/the-morrow-stone',
'tailoringClassic':'https://www.wowhead.com/classic/guide/tailoring-leveling-1-300-wow-classic',
'smokey':'https://www.wowhead.com/classic/quest=6041/when-smokey-sings-i-get-violent',
'truefaith':'https://www.wowhead.com/classic/item=14512/pattern-truefaith-vestments',
'benediction':'https://www.icy-veins.com/wow-classic/benediction-anathema-quest-guide-to-the-balance-of-light-and-shadow'}
profiles={
'PRIEST':['Holy','Shadow','Discipline'], 'WARRIOR':['Arms','Fury','Protection'],
'MAGE':['Arcane','Fire','Frost'], 'ROGUE':['Assassination','Combat','Subtlety'],
'WARLOCK':['Affliction','Demonology','Destruction'], 'HUNTER':['Beast Mastery','Marksmanship','Survival'],
'PALADIN':['Holy','Protection','Retribution'], 'SHAMAN':['Elemental','Enhancement','Restoration'],
'DRUID':['Balance','Feral','Restoration']}
# Stage levels are planning bands, never asserted entry or quest minimum levels.
rows=[
(1,5,'Learn the character','Starting settlement','Starting settlement',
'Finish nearby starter kill/delivery quests. Learn core attacks, loot bags, and set a return point.',
'Only nearby shared objectives; no dungeon priority.',
'Replace missing basic armor; keep a usable weapon. Priest: start looking for a wand.',
'Train professions when available; gather locally rather than travel for recipes.',
'Complete race-specific introductions before leaving; class training takes priority.'),
(6,10,'Finish the starter zone','Elwynn / Dun Morogh / Teldrassil','Durotar / Mulgore / Tirisfal',
'Finish local quest chains and class unlock introductions before moving to a second zone.',
'Ask for help with elite finales; skip them if a group takes too long.',
'Weapon or wand upgrades first; useful stamina and class primary stats next.',
'Save cloth for bags, bandages or tailoring. Keep money for skills.',
'Visit the class trainer; Classic class unlock levels are not guaranteed in Forever.'),
(11,15,'Build efficient loops','Westfall / Loch Modan / Darkshore','The Barrens / Silverpine',
'Batch quests by location. Alliance: begin The Defias Brotherhood setup; Horde: build Crossroads or Sepulcher quest loops.',
'Ragefire Chasm is a Horde candidate; collect available city quests before a run.',
'Aim for a reliable damage weapon or wand; avoid buying an entire temporary set.',
'Craft bags and low-cost consumables; buy recipes only if usable soon.',
'Faction and prior quest completion govern chain offers; verify quest text in game.'),
(16,20,'First dungeon payoff','Westfall / Redridge / Darkshore','The Barrens / Stonetalon / Silverpine',
'Finish local non-elite chains. Alliance: advance Defias preparations; Horde: gather Wailing Caverns quests.',
'Deadmines (Alliance) or Wailing Caverns; Shadowfang Keep when party-ready. Complete quest objectives in one visit.',
'Seek a substantial weapon upgrade and fill weak armor slots; keep a healing set for groups.',
'Spend on consumables for the planned run; use gathered cloth before buying materials.',
'The Defias Brotherhood has a preceding Westfall chain; Staff of Westfall is a source-listed reward, eligibility needs live confirmation.'),
(21,25,'Prepare the midlevel set','Duskwood / Wetlands / Redridge','Hillsbrad / Stonetalon / Ashenvale',
'Alliance: investigate The Fury Runs Deep setup. Both factions: prioritize yellow quests and collect travel connections.',
'Stockade for Alliance, Blackfathom Deeps or Shadowfang Keep for a prepared party. Avoid repeating a run for a tiny gain.',
'Holy Priest: Pristine Leggings becomes wearable at 25; plan materials and profession gates first.',
'If committed to tailoring, plan skill 125 for the leggings. Do not assume another crafter can supply a maker-only item.',
'Collect prerequisite quests before traveling; the Stockade reward route is Alliance only.'),
(26,30,'Use the verified Holy sample','Duskwood / Wetlands / early Stranglethorn','Hillsbrad / Thousand Needles / Ashenvale',
'Keep ordinary questing moving. Alliance: The Grand Betrayal; Horde: Rig Wars are dungeon quest candidates, not solo errands.',
'Razorfen Kraul for Death Speaker Robes at 26; Gnomeregan after gathering quests and checking boss difficulty.',
'Holy Priest: compare the bundled legs, chest and level-30 boots targets. Other profiles: verified gear data missing.',
'Tailoring 150 enables the Gilded Slippers recipe; reserve materials only after checking maker and workstation requirements.',
'Leggings: level 25/skill 125; boots: level 30/skill 150. Recipe-source conflict for leggings must be checked in game.'),
(31,35,'Resume quest momentum','Stranglethorn / Arathi / Desolace','Stranglethorn / Arathi / Desolace',
'Choose one nearby hub at a time; work hunting and collection chains in shared areas.',
'Scarlet Monastery early wings or Razorfen Kraul cleanup, when appropriate for the group.',
'Replace the weakest slot through quests; the level-30 sample expires after 30 and is not a current BiS list.',
'Advance chosen professions with gathered materials; retain travel and training funds.',
'Classic route only; Forever quest chains, rewards and dungeon tuning above 30 are unverified.'),
(36,40,'Budget for mobility','Stranglethorn / Dustwallow / Badlands','Stranglethorn / Dustwallow / Badlands',
'Finish hub chains that lead to useful rewards; avoid long cross-continent deliveries without another reason to travel.',
'Scarlet Monastery later wings or Razorfen Downs with a prepared party; collect their quests first.',
'Maintain a strong weapon and role-appropriate armor; preserve funds for mobility and class training.',
'Make practical consumables. Check live mount and training rules rather than assuming Classic costs.',
'Dungeon wings differ in difficulty; planning range is not an entry guarantee.'),
(41,45,'Stack dungeon quests','Tanaris / Feralas / Hinterlands','Tanaris / Feralas / Hinterlands',
'Build Gadgetzan and nearby quest circuits; start Screecher Spirits for the later Yeh\'kinya chain if available.',
'Prepare Zul\'Farrak quests including Gahz\'rilla. Defer difficult steps until party-ready.',
'Target clear weapon or role upgrades; no Forever-verified item targets for this band.',
'Prepare food, drink and profession consumables for a longer instance.',
'Classic Gahz\'rilla requires level 40. Confirm a party member has the summoning mallet before planning that boss.'),
(46,50,'Finish long chains deliberately','Tanaris / Hinterlands / Searing Gorge','Tanaris / Hinterlands / Searing Gorge',
'Finish accessible hub quests and continue Yeh\'kinya preparations; skip isolated elite objectives without help.',
'Zul\'Farrak, Maraudon or Jintha\'Alor objectives with a party; plan boss routes before entering.',
'Use quest rewards to repair weak slots. Keep useful resistance or healing alternatives without calling them BiS.',
'Train profession ranks when available; craft only upgrades that justify their material cost.',
'Classic mallet route uses the Sacred Mallet and the Jintha\'Alor altar. Confirm Forever steps before making the trip.'),
(51,55,'Prepare the final push','Un\'Goro / Felwood / Searing Gorge','Un\'Goro / Felwood / Searing Gorge',
'Batch Un\'Goro collection objectives; continue Felwood hubs and class quests when offered.',
'Sunken Temple or early Blackrock Depths objectives; coordinate which quests and bosses the party will do.',
'Build a functional dungeon role set; save expensive endgame crafts until their Forever recipes are verified.',
'Stock useful consumables and keep a material reserve for confirmed endgame crafts.',
'Sunken Temple chains may require earlier dungeons and travel. Check quest log and class trainer first.'),
(56,59,'Convert preparation into access','Western / Eastern Plaguelands / Winterspring','Western / Eastern Plaguelands / Winterspring',
'Finish safe quest hubs and travel links. Start relevant key/access chains only after verifying live requirements.',
'Blackrock Depths; assess Lower Blackrock Spire, Stratholme and Scholomance with a competent group.',
'Prioritize dependable quest upgrades and role readiness; no full-BiS percentage is available.',
'Prepare sustained dungeon supplies. Verify actual level, reputation and recipe gates before investing.',
'Classic endgame paths are planning candidates; Forever access, tuning and rewards remain unverified.'),
(60,60,'Begin horizontal progression','Chosen endgame hubs','Chosen endgame hubs',
'Audit unfinished access quests and profession goals; choose a small number of rewarding activities.',
'Run verified available endgame dungeons with agreed objectives; coordinate raid preparation with your group.',
'Require a fresh level-60 dataset before identifying BiS; track checklist completion separately from gear quality.',
'Choose confirmed lasting crafts and enchants after checking current rules and budget.',
'No verified Forever level-60 target list is bundled. Endgame access and raid availability require live confirmation.')]
stages=[]
for lo,hi,title,a,h,solo,group,gear,craft,pre in rows:
    sid='level-%02d'%lo
    stages.append(dict(id=sid,min=lo,max=hi,title=title,alliance=a,horde=h,status='Classic-derived; Forever route unverified',
        tasks=[dict(id=sid+'-'+k,mode=m,text=t) for k,m,t in [('solo','solo',solo),('group','group',group),('gear','solo',gear),('craft','solo',craft),('gates','solo',pre)]],sources=['classic','alliance','horde']+(['zf'] if lo in (41,46) else [])+(['st'] if lo==51 else [])))
# Add named quest anchors without asserting automatic eligibility or Forever gates.
anchors={
1:('solo','Human example: A Threat Within -> Kobold Camp Cleanup. Other races should finish their own starter chain, then class introductions.','starter'),
16:('gear','Holy Priest: Pristine Gloves is a verified level-15+ candidate, Tailoring 75 and maker-only; keep a usable damage weapon or wand.','forever'),
31:('solo','In Stranglethorn, start the early Tiger Mastery and Panther Mastery steps at Nesingwary\'s camp. Complete each preceding step before its follow-up.','quests30'),
36:('solo','Continue Tiger Mastery / Panther Mastery follow-ups only when their targets are suitable; defer named elite finales to a party.','quests30'),
41:('solo','In Tanaris, batch Wastewander Justice and Water Pouch Bounty. Prepare Screecher Spirits before the later Mosh\'aru dungeon step.','quests40'),
46:('group','Zul\'Farrak: complete The Prophecy of Mosh\'aru after Screecher Spirits, then plan The Ancient Egg. Jintha\'Alor steps need a party.','zf'),
51:('solo','Un\'Goro: collect for Crystals of Power at J.D. Collie, then investigate The Eastern Pylon and its companion pylon steps when offered.','crystals'),
56:('solo','Eastern Plaguelands: batch Demon Dogs, Blood Tinged Skies and Carrion Grubbage from Tirion Fordring. Avoid difficult chain finales without help.','tirion'),
60:('group','If available in Forever and relevant to your group, plan Attunement to the Core during Blackrock Depths. In Classic it unlocks a shortcut, not the only possible raid entrance.','core')}
for s in stages:
    if s['min'] in anchors:
        kind,text,source=anchors[s['min']]
        for t in s['tasks']:
            if t['id']==s['id']+'-'+kind: t['text']=text
        if source not in s['sources']: s['sources'].append(source)
milestones=json.loads(Path('research/guide-milestones.json').read_text(encoding='utf8'))
for s in stages:
    m=milestones[str(s['min'])]
    s['milestones']=dict(m,roleClass='PRIEST',evidence='Classic planning references; Forever eligibility, values and difficulty unverified unless specifically source-labeled.')
    s['sources']=list(dict.fromkeys(s['sources']+m['sources']))
gear=[
dict(id=2042,name='Staff of Westfall',slot=16,min=14,max=30,mode='group',faction='Alliance',activity='Deadmines / The Defias Brotherhood',levelNote='Quest planning from Classic acceptance level 14; Forever acceptance and wear/training gates unverified',source='https://foreverchanges.pro/item/2042',
     acquire='Alliance: finish The Defias Brotherhood Westfall prerequisites, collect the dungeon quest and defeat VanCleef with a prepared Deadmines party. Verify live quest availability before travel.',materials='Quest reward; not a repeatable boss-drop farm. Check weapon training and the two-hand/off-hand tradeoff in game.'),
dict(id=253913,name='Pristine Gloves',slot=10,min=15,max=30,mode='solo',source='https://foreverchanges.pro/item/253913',
     acquire='Tailoring 75; maker-only. Item page lists pattern for 30 Merchant\'s Favor at Mivin Shadowweave / Jim\'bek; confirm vendor access.',
     materials='6 Woolen bolts, 4 Fine Thread, 3 Cerulean Dye, 2 Pristine Leather'),
dict(id=6685,name='Death Speaker Mantle',slot=3,min=27,max=30,mode='group',source='https://foreverchanges.pro/item/6685',
     acquire='Death Speaker Jargba, Razorfen Kraul. Forever wear level 27 differs from Classic 25.',materials='Dungeon drop; obtain with a party.'),
dict(id=253987,name='Pristine Leggings',slot=7,min=25,max=30,mode='solo',source='https://foreverchanges.pro/item/253987',
     acquire='Tailoring 125; maker-only; check Spinning Wheel. Recipe source disputed: list says pattern; item page says 30 Merchant\'s Favor at Mivin Shadowweave / Jim\'bek.',
     materials='14 Silk bolts, 3 Fine Thread, 8 Cerulean Dye, 8 Pristine Leather, 2 Silver Bars, 3 Greater Astral Essence'),
dict(id=6682,name='Death Speaker Robes',slot=5,min=26,max=30,mode='group',source='https://foreverchanges.pro/item/6682',
     acquire='Death Speaker Jargba, Razorfen Kraul. Level 26 is wear requirement, not recommended party entry level.',materials='Dungeon drop; obtain with a party.'),
dict(id=254001,name='Gilded Slippers',slot=8,min=30,max=30,mode='solo',source='https://foreverchanges.pro/item/254001',
     acquire='Tailoring 150; trainer recipe; maker-only; check Spinning Wheel before crafting.',
     materials='8 Mageweave bolts, 4 Heavy Silken Thread, 2 Magenta Dye, 2 Cerulean Dye, 2 Gold Bars')]
quests=[]
for qid,step,summary,parent in [
    (65,1,'Speak with Wiley in Lakeshire',0),(132,2,'Return the note to Stoutmantle',65),
    (135,3,'Bring the note to Mathias Shaw',132),(141,4,'Return the report to Stoutmantle',135),
    (142,5,'Investigate the Defias Messenger',141),(155,6,'Prepare the Defias Traitor escort',142),
    (166,7,'Defeat VanCleef with a prepared party',155)]:
    quests.append(dict(id=qid,name='The Defias Brotherhood - step '+str(step),summary=summary,previous=parent,
        faction='Alliance',source='https://foreverchanges.pro/quest/'+str(qid),
        evidence='Source-linked chain; source mixes Classic baseline and observed Forever changes. Live eligibility and difficulty unknown.'))
gear[0]['questID']=166
quests.extend([
 dict(id=1198,name='In Search of Thaelrid',summary='Find Argent Guard Thaelrid in Blackfathom Deeps',previous=0,faction='Alliance',source='https://foreverchanges.pro/quest/1198',evidence='Linked predecessor on Blackfathom Villainy source page; live eligibility unknown.'),
 dict(id=1200,name='Blackfathom Villainy',summary='Collect Kelris head with a party and return to Dawnwatcher Selgorm in Darnassus',previous=1198,faction='Alliance',source='https://foreverchanges.pro/quest/1200',evidence='Source-linked two-step chain; client eligibility unknown.'),
 dict(id=6561,name='Blackfathom Villainy',summary='Check the Horde Blackfathom Villainy quest and live dungeon objectives',previous=0,faction='Horde',source='https://foreverchanges.pro/quest/6561',chainIncomplete=True,evidence='Faction quest ID linked by source item page; direct quest retrieval unavailable; predecessor map incomplete.')])
questRewards=[dict(id=7001,name='Gravestone Scepter',slot=18,min=18,max=30,mode='group',questByFaction={'Alliance':1200,'Horde':6561},activity='Blackfathom Deeps / Blackfathom Villainy',source='https://foreverchanges.pro/item/7001',acquire='Blackfathom Villainy reward choice. Alliance: investigate In Search of Thaelrid then Blackfathom Villainy. Horde: check the live quest chain; predecessor data incomplete.',materials='Quest reward choice, not a repeatable drop. Classic acceptance reference 18; Forever wear, class/training and safe party level unknown.',levelNote='Classic quest planning from 18; Forever wear eligibility unknown')]

data=dict(version='0.22.0-prototype',reviewed='2026-10-20',sources=sources,profiles=profiles,stages=stages,gear=gear,quests=quests,questRewards=questRewards)
for g in gear:
    g['effort']='dungeon' if g['mode']=='group' else 'craft'
    if g['id'] in (6682,6685): g['activity']='Razorfen Kraul / Death Speaker Jargba'
Path('research/content.json').write_text(json.dumps(data,indent=2),encoding='utf8')
def lua(v):
    if isinstance(v,dict): return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list): return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,str): return json.dumps(v,ensure_ascii=True)
    return str(v).lower()
Path('RuinousForeverPlanner/Data.lua').write_text('local _, P = ...\nP.Data = '+lua(data)+'\n',encoding='utf8')
print('Generated',len(stages),'stages and',len(gear),'verified targets')
