import json, html, re
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4

D=json.loads(Path('research/content.json').read_text())
C=json.loads(Path('research/catalogue.json').read_text())
test_match=re.search(r'(\d+) mocked behavior assertions',Path('output/test-results.txt').read_text(encoding='utf-8-sig'))
if not test_match: raise RuntimeError('Run tests and save output/test-results.txt before building the release PDF')
test_count=test_match.group(1)
out=Path('output/pdf'); out.mkdir(parents=True,exist_ok=True)
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='TitleX',fontName='Helvetica-Bold',fontSize=29,leading=34,textColor=colors.HexColor('#123650'),spaceAfter=18))
styles.add(ParagraphStyle(name='Deck',fontName='Helvetica',fontSize=14,leading=21,textColor=colors.HexColor('#38566a'),spaceAfter=16))
styles['BodyText'].fontName='Helvetica'; styles['BodyText'].fontSize=10; styles['BodyText'].leading=14; styles['BodyText'].spaceAfter=8
styles['Heading1'].textColor=colors.HexColor('#123650'); styles['Heading1'].fontSize=20; styles['Heading1'].leading=25; styles['Heading1'].spaceAfter=14
styles['Heading2'].textColor=colors.HexColor('#176779'); styles['Heading2'].fontSize=12; styles['Heading2'].leading=16; styles['Heading2'].spaceAfter=6
styles.add(ParagraphStyle(name='SmallX',fontSize=8,leading=11,textColor=colors.HexColor('#526470'),spaceAfter=7))
story=[]; md=[]
def p(text,style='BodyText'):
    story.append(Paragraph(html.escape(text),styles[style])); md.append(text+'\n')
def h(text): p(text,'Heading1'); md[-1]='# '+md[-1]
def sub(text): p(text,'Heading2'); md[-1]='## '+md[-1]
def new(): story.append(PageBreak()); md.append('\n---\n')
def table(rows,widths):
    data=[[Paragraph(html.escape(str(c)),styles['SmallX']) for c in row] for row in rows]
    t=Table(data,colWidths=widths,hAlign='LEFT',repeatRows=1)
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e5eff4')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,0),1,colors.HexColor('#176779')),('LINEBELOW',(0,1),(-1,-1),0.3,colors.HexColor('#dce4e8'))]))
    story.append(t)
    md.extend([' | '.join(map(str,row))+'\n' for row in rows])

p('PRODUCT REQUIREMENTS / INTEGRATED UPDATE TO v0.5','SmallX')
p('Ruinous Forever Planner','TitleX')
p('v0.22 - Integrated leveling guide and installable prototype','Deck')
p('October 30, 2026 | Level 1-60 | Solo and group planning','Deck')
story.append(Spacer(1,8))
sub('Document status')
p('This revision reconciles the supplied nine-page PRD v0.5 with the implemented prototype. All 28 original functional requirements are retained in the traceability appendix. The unmodified v0.5 is appended as a historical baseline; its planning-only status is superseded by the user\'s explicit instruction to implement. The original vision remains the product target, while partial features are labeled honestly.')
sub('What is delivered')
p('Ruinous Forever Planner bundles all 38 crawled class/role lists, 634 item records and 110 accessible source-linked quest records. Thirty planning profiles map all nine classes and their specs/extra roles across 60 PvE/PvP combinations. It scans equipped/carried gear and integrates the installed QuestieDB quest baseline. Item lists describe level 30, not a complete 1-60 database.')
sub('Source and baseline coverage')
p('Every profile has an explicit published source or labeled shared role reference. Discipline PvE uses the published Holy healer list as a shared reference, without changing the selected spec. Source-confirmed and unconfirmed records remain distinguishable. The installed QuestieDB Forever registry contains 5,226 numeric quest IDs; the runtime integration enumerates all provider IDs in bounded batches and exposes a searchable class/race-filtered quest catalogue. No Questie code or full database is redistributed.')
sub('Estimated optimization rating')
p('The Rating view reports the average equipped-to-benchmark stat ratio across evaluated slots, with explicit coverage and per-slot unknowns. Recommendations rank potential rating-point gains. Positive upgrade estimates are green, negative red and unknown/neutral values uncolored. Full BiS is a separate complete item-and-enchant certification; no certified level-60 set is bundled. The level-60 easter egg is gated on that certification. START-HERE.html and USAGE_GUIDE.md in the addon ZIP explain all features and practical routines.')
sub('Evidence boundary')
p('The user has loaded earlier builds and reported UI problems. The expanded renamed build has passed Lua syntax and mocked checks but awaits live QA. The source marks 621 item records beta-confirmed; this is third-party evidence, not a client test by the author. Missing list combinations use explicit shared references. Levels 31-60 remain Classic-derived route guidance; supplementary dungeon quest/reward facts are now bundled, but complete routes, exact eligibility and restricted API behavior are not guaranteed.')
new()
h('v0.22: ordered routes and a clearer next action')
p('Prepared October 30 for offline release and November 4 launch acceptance. Now is the default page, with six main tabs and a More dropdown for advanced tools. Current route steps appear before optional gear/class suggestions, and context-specific controls replace the old item/checklist buttons on Now. No live launch-client behavior is claimed.')
sub('Factoruide data-only route bridge')
p('The bundled local HTML converter reads single-character Forever .fgguide JSON files, formats 1/2, and emits a bounded RFP1 text representation. The addon never executes pasted guide Lua or compressed FGG1 text. Import validates class/race/faction, level ranges, numeric fields, prerequisite/exclusion lists, 5,000-step / 1 MB limits and text controls before replacing the current character route. An actual upstream 870-step sample was converted and parsed offline; it is not shipped as a universal player route.')
p('Observed quest acceptance, indexed objective completion and recorded turn-ins advance supported steps. Catch-up is capped at 40 steps per refresh. Missing/restricted flags, incomplete prerequisites and unconfirmed manual actions stay pending. Manual next acknowledges a player choice; Undo pauses automation for review. Marks and progress save per character. Group routes, upstream parallel/background behavior, item-buy/held conditions, combat/travel simulation and gameplay automation are not reproduced.')
sub('Destination navigation and all-level carried gear')
p('A manual button requests a native waypoint only when map support, the exported API and runtime map-point helper are available. Map ID and destination coordinates remain visible when it fails. There is no terrain-aware pathfinder or safe-route promise. Observed carried gear can produce weighted-stat comparison suggestions beyond level 30 without inventing a BiS list. Training, unique restrictions, special effects and complete late-level coverage still need inspection.')
p('The external source index was checked October 30 and still labels its lists level 30. Cached item facts retain their October 20 review date. A source-backed Druid Cat Form reminder distinguishes the level-20 Forever quest chain from Classic assumptions; complete unlock-to-spell mappings for all classes remain incomplete.')
sub('Measured sessions and launch validation')
p('An explicit XP session timer counts all observed XP, handles one-level rollovers, includes travel/recovery time, and stores up to 20 finished samples. It does not overwrite grinding-only estimates. Missing observations or ambiguous transitions invalidate the sample; active samples do not survive reload or character changes. Offline native Lua 5.1, Fengari and JavaScript converter tests cover route transitions, malformed inputs, race/class mismatches, navigation failures, high-level bag comparisons, UI context and XP math. Launch checks and an offline report are included in the ZIP.')
p('Route-format references: https://github.com/brouznouf/factoruide ; data fields were reviewed at the pinned research commit recorded in research/factoruide/tree.json. Druid guidance: https://foreverchanges.pro/druid-cat-form . Neither source review nor mocked tests establishes live client correctness or faster leveling.')
new()
h('Alt character and action-bar window corrections')
p('Guild feedback reported action bars and hotkey labels drawing in front of the main window and incorrect guidance for a level-10 Mage. The main planner now uses an opaque DIALOG layer; settings and profile menus have higher dialog levels. It does not hide or change action bars or keybindings. Custom third-party layers still require live visual QA.')
sub('Character identity and saved profiles')
p('Login now chooses the actual player class and live level. It selects a supported active client spec when readable, otherwise retaining a class-specific saved planning profile with an explicit fallback label. A new Mage fallback uses Frost. No talents are changed. Saved per-class profile data is retained. Manual class previews remain available during a session, but they no longer override the class selected at the next login. /rfp current exits a preview immediately. Switching character identities clears the previous inventory snapshot before scanning. An unavailable player class no longer silently falls back to Priest.')
sub('Level-10 Mage and incomplete gear data')
p('The bundled Mage reference has no verified gear targets wearable at level 10. The empty Gear view now explains the limitation, provides Mage-specific planning notes, and lists known Mage targets in the next ten levels as future references. It labels equipped-position rows as inventory rather than recommended targets. Legacy automatic level-30 milestones are capped to the next ten levels below level 20; an explicitly requested milestone remains valid. Non-Priest stage tasks and titles no longer expose the original Holy Priest sample.')
p('If the full catalogue is missing, non-Priest profiles do not receive the Priest-only fallback records. Diagnostics identify actual class, selected class/spec, actual level and manual class preview. These distinctions make future guild screenshots more actionable. The local class planning notes are heuristics and do not establish item availability, talent selection or exact spell-unlock levels.')
sub('Validation boundary')
p('Regression checks simulate distinct Priest and Mage characters, stale cross-class saved selections, level previews, inventory isolation, retained specs/settings, missing catalogue behavior, the rendered empty Mage gear view, and main/menu/settings layering. The new build passes offline Lua checks; live testing with guild members using action-bar and hotkey addons remains necessary. Users previously reported v0.18 working on Priest and Druid; that does not establish live acceptance of this new release.')
p('Existing gear, enchant, ten-level guide and dungeon-comparison behavior is retained. START-HERE.html describes the recovery command and early-level data boundaries.')
new()
h('Enchant and off-hand corrections')
p('The importer previously skipped the site sections named held, shield, two-hand and relic. Their mappings are now explicit, and an unfamiliar future slot-* section stops the crawl. The refreshed 38 lists contain 634 item records, including 621 source-confirmed records, and 110 accessible linked quest pages. Dungeon facts additionally contain 2,058 reward/drop rows. One linked quest page, 79242, is unavailable. These are source records, not live client acceptance evidence.')
sub('Permanent enchant stats')
p('Owned and hovered item links preserve their permanent enchant IDs and suffix fields. The reader compares an exact link with the same payload after removing only its permanent enchant. When the item-stat API already includes the enchant, that numeric total is retained. Otherwise recognized permanent-enchant tooltip stats are added once to the unenchanted base. Numeric link differences support any locale; the guarded text fallback currently supports English. Unrecognized procs and utility retain known base stats with an explicit unscored flag. Temporary weapon buffs and effects are not simulated.')
p('A local catalogue contains 165 enchant references, 103 with recognized static effects. At level 30 only, numeric options explicitly associated with the selected published class/role reference can augment the benchmark. Missing such an enchant can lower the rating even when the target gear item is equipped. The former exact-item-ID shortcut no longer forces 100 percent or a zero-percent comparison. Maker skill does not establish player wear eligibility: target restrictions, access, price and materials still need verification.')
sub('Main hand and off hand together')
p('Rating and gear comparisons score the complete weighted-stat weapon set. Replacing an off hand retains the main hand. A two-hander removes the off hand and its enchant contribution. An off hand cannot be independently combined with a two-hander. The Guide can propose a complete one-hand-plus-off-hand set. The set ratio counts as two applicable positions for a one-hand setup, or one for a two-hander; the off hand is never counted again separately. Ranged item stats can also enter the stat model, without claiming a weapon-DPS simulation.')
p('Tooltip rating predictions recalculate the model using a temporary snapshot, including enchant loss, ring/trinket assignment and changing applicable position counts. No equipped gear is changed. Rating exposes enchant coverage and source options; tracked enchant goals remain separate from already-owned gear goals. Health and Mana have editable model weights. Unsupported effects remain outside full BiS certification.')
sub('Validation and practical QA')
p('Regression checks cover omitted source sections, enchanted versus unenchanted copies, both item-stat API behaviors, no double counting, proc/locale fallback, off-hand upgrades, empty off-hand fill, two-hand replacement, complete weapon sets and projection without mutation. Syntax and native Lua behavior are checked offline. Restart the client, scan gear, then inspect Rating, Guide and owned/auction/loot tooltips. Live client behavior still awaits user QA.')
p('Sources: https://foreverchanges.pro/professions/enchanting and corrected class/role list item records; Forever UI TooltipInfoSharedDocumentation.lua for permanent-enchant line types. Full installation and usage notes are bundled in START-HERE.html.')
new()
h('Ten-level efficiency and five-player decisions')
p('Guide now evaluates the actual character through the next ten levels, capped at 60. It combines the existing stage hubs and local QuestieDB quest checks with equipped/carried ownership, positive client-stat comparisons, accepted/completed quests, Solo / Group preference and future wear/dungeon bands. It favors already-carried improvements and on-route quests, labels optional group and low-cost crafting goals, and can defer short-lived grinds. These are explainable heuristics, not a certified fastest route.')
sub('Dungeon facts and preparation')
p('The bundled supplementary data covers 34 five-player dungeon/wing references, including nine new Forever dungeons, 331 quest rows and 2,058 reward/drop rows. These are records rather than unique-item counts. Upper Blackrock Spire is excluded. New level bands are source-attributed to Blizzard; Classic bands remain unconfirmed in Forever. Reward and drop candidates require current client details to support a numerical comparison; the new data does not create a complete BiS benchmark.')
sub('One prepared run versus grinding')
p('Dungeon / XP opens a separate readable comparison panel. The player can measure a grinding XP/hour sample or enter a rate, then enter kill XP, clear time, travel, group wait, quest/wipe overhead and any additional verified quest XP. The automatic beta-XP subtotal includes only accepted, uncompleted, matching quests with known minimum levels and no more than five levels below the player. Missing, future, unaccepted or potentially reduced payouts do not silently enter that subtotal. The quest list shows completion and source-linked prerequisite checks.')
p('First-run XP/hour includes all entered minutes. Break-even total XP, maximum tolerable wait and equal-XP opportunity cost explain the verdict. Grinding to the next level is shown separately when player XP resolves. Repeat clear XP/hour omits one-time quest XP and explicitly omits repeat overhead. Run inputs must be reconfirmed after leveling. All entered values and beta payouts remain estimates; party safety and live access are separate checks.')
sub('Gear value and uncertainty')
p('The plan shows positive weighted-stat comparisons and guarded same-type weapon base-DPS comparisons from English live tooltip data. It includes complete main/off-hand stat combinations and resolved permanent enchants, but does not simulate character DPS, procs, feral forms or future minutes saved. Quest rewards depend on completing and choosing the reward; boss loot is random. Drop odds, competition, prices and gear time payback remain unknown. Solo healer leveling ignores healing-only stats without changing Rating weights.')
p('Guide can pin an efficiency gear/quest goal to the objective tracker; Settings controls the compact ten-level tracker view and clearing leveling goals. All new behavior has syntax and mocked Lua tests, including XP completion, wait-cost decisions, level-up sampling and dialog isolation. Auction House, loot, routes and dungeon calculations still need live client QA.')
p('Sources: https://foreverchanges.pro/dungeons and linked detail pages; https://www.icy-veins.com/wow-classic/leveling-guide for general policy. Numeric thresholds and time comparisons are RFP model choices, not guide-author claims. Full usage steps are in START-HERE.html.')
new()
h('Expanded class/spec catalogue')
p('Crawl reviewed October 20, 2026: 38 source lists, 634 unique items and 111 linked quest URLs; 110 quest pages were accessible. All source paths, confirmation labels, numeric stats, suffix distinctions and source wear levels are bundled. Known wear levels support earlier-level planning; unknown levels remain level-30 references. Shared mappings are labeled, never presented as dedicated rankings.')
table([['Class','Planning specs / roles','Contexts']]+[[cls,', '.join(specs),str(len(specs)*2)] for cls,specs in C['profiles'].items()],[85,345,65])
p('The Quest catalogue reads installed QuestieDB contract 4. It provides all provider IDs, class/race metadata, AND/OR prerequisites, completion/active observations, ID/name search, level filters and manual quest tracking. Indexing is batched outside combat. Disabling the provider leaves the source-linked subset and an explicit coverage message. The 5,226-ID local baseline audit is not a guarantee that every server quest or reward is represented.')
p('Role presets support healer, caster, strength, agility, ranged and tank comparisons. Weights are subjective and editable. Rating includes combined main/off-hand stat sets and resolved permanent enchants. Efficiency also supports guarded same-type base-DPS comparisons. Random-suffix catalogue uncertainty and combat effects remain unscored. Source stats may back a missing client cache only when beta confirmation and wear-level evidence are present. Empty/zero baselines do not produce percentages.')
new()
h('1. Product purpose and scope')
p('Help a player decide the next useful activity while leveling, keep gear reasonably current without delaying progress for marginal upgrades, and prepare for horizontal progression at level 60. The player must be able to tell verified facts from planning assumptions.')
sub('Primary flow')
p('Open /rfp, select a planning class/spec, choose Solo or Group, and review the current level band. Complete nearby quests and essential prerequisites, compare available targets with equipped and carried gear, then mark activities done. Reassess when leveling or changing equipment.')
table([
['Requirement','Prototype behavior / acceptance'],
['Profiles','Nine class families with manual spec and PvE/PvP profiles; independent gates, skipped goals and history. Holy PvE has sample data.'],
['Character context','Current player level and faction determine stage and hubs; another-class planning shows a warning.'],
['Inventory','Real API calls for player equipment and carried bags. IDs, locations and cache status shown; no bank or remote storage.'],
['Gear candidates','Filter by class/spec, level window and activity mode. Show equipped comparison slot and exact-ID ownership.'],
['Leveling priorities','13 contiguous bands; solo quests, group runs, gear goals, crafting and prerequisites shown together.'],
['Checklists','Stable per-character task IDs; manual toggle; retained through reload/logout. Group objectives hidden in Solo.'],
['Incomplete data','Persistent partial-data notice, missing-profile/level message, pending item labels and scan errors. No invented BiS score.']
],[105,390])
sub('Scope deferred from a complete product')
p('Full leveling BiS per class/spec, numeric upgrade scoring, percentage-to-BiS trends, automatic quest completion and eligibility checks, profession/reputation scanning, travel routing, attunement graphs, enchant optimization and verified level-60 content. These require expanded source data and client tests, not merely interface controls.')
new()
h('2. Decisions, priorities and data rules')
sub('Priority order')
p('First: essential class unlocks, safe quest progress and usable equipment. Second: batch nearby quests and prerequisites for one worthwhile dungeon visit. Third: a meaningful weapon or role upgrade and confirmed crafts. Optional rare drops and expensive temporary items should not displace leveling momentum. The adaptive planner applies this qualitative order using actual target ownership, empty comparison slots, manual gates and a future milestone. It does not compute time or combat-value scores.')
sub('Solo and group semantics')
p('Solo displays preparation, ordinary questing, gear goals, crafting and gate checks. Group adds dungeon and elite objectives. A craft labeled solo means it can be planned without a dungeon run, not that all materials can be gathered alone. Dungeon-quest pickup may be solo while its completion requires a party. Band levels describe when to plan, not when access is guaranteed.')
sub('Evidence categories')
table([
['Category','Required treatment'],
['Source-confirmed beta item','An individual Forever item page explicitly labels the item confirmed. Preserve ID, wear level, slot, source URL and review date. Recheck on data updates.'],
['Classic-derived route','Authored from existing Classic guides. Label unverified for Forever, including quests, prerequisites, profession rules and dungeon tuning.'],
['Conflicting record','Show the disagreement. Do not manufacture a single certain gate or spend recommendation.'],
['Unknown / unsupported','Show absent coverage; never substitute Classic stats or a fabricated item ranking.'],
['Client observation pending','API presence and offline mocks do not prove live behavior; keep the in-game acceptance checklist open.']
],[128,367])
sub('No misleading denominator')
p('The sample contains six item candidates in at most six of seventeen inspected equipment positions for Alliance (five for Horde). That is partial dataset coverage, not a full-BiS percentage. Owning a target in a bag is not equivalent to equipping it. Checklist completion measures manual activity tracking, not character power. A complete BiS score and trend must remain unavailable until a comparable full-slot, level-specific dataset exists.')
new()
h('3. Addon and client contract')
sub('Packaging and persistence')
p('Folder: RuinousForeverPlanner. Generic and Camelot TOCs declare Interface 16001 and load Data.lua, Core.lua, Inspection.lua, Upgrades.lua, Quests.lua, Planner.lua, Diagnostics.lua, UI.lua, Controls.lua in that order. SavedVariables: RuinousForeverPlannerDB, schema 2 (migration from schema 1). characters[UnitGUID] stores class, spec, context, mode, milestone, stage preview and done[taskID]. Per-profile tables retain gates, skipped targets and versioned sample-count history. Inventory remains a runtime snapshot. A newer schema is left untouched; unknown profile values receive valid defaults.')
sub('Verified API evidence')
p('The reviewed export was generated from client APIDocumentation on October 1, 2026: build 70170, interface 16001. The source site advertises later item beta builds; these are separate evidence snapshots. Symbol presence is checked locally against the downloaded export. Equipment globals appear in its global inventory; this is weaker than a typed runtime test.')
table([
['Purpose','Call / interpretation'],
['Equipment','GetInventoryItemID("player", slot), GetInventoryItemLink("player", slot). Inspect slots 1-18 except shirt 4; tabard 19 excluded.'],
['Carried bags','C_Container.GetContainerNumSlots(bag), GetContainerItemInfo(bag, slot). The latter returns a table; read itemID, hyperlink, stackCount.'],
['Item cache','C_Item.GetItemInfo(link or ID): first return is item name. If unavailable, show pending and RequestLoadItemDataByID once per ID; re-read on ITEM_DATA_LOAD_RESULT.'],
['Character context','UnitLevel, UnitClass, UnitFactionGroup and UnitGUID; profile is manual and never changes talents.'],
['Refresh','Login, bag update, equipment change, item-data completion, level change and end of combat. Level change refreshes on the next frame.']
],[105,390])
sub('Failure handling and restrictions')
p('Calls are guarded; missing or failing scan APIs produce visible errors. Scanning is deferred during combat. Secret top-level values are rejected and inaccessible bag fields are caught. Unknown item ownership remains unknown on an incomplete scan. Cache requests are bounded; /rfp retry allows a new attempt. No protected equip action, server request automation or network traffic is implemented.')
new()
h('4. How to use the leveling plan')
p('The following stages are the same records bundled in the addon. Each stage combines quest priorities with equipment, crafting and preparation. Both factions are shown here; the addon shows the current faction. All Classic guidance must be checked against live Forever quest text and availability. This is a staged plan, not a complete quest-by-quest navigation addon.')
sub('Before leaving a hub')
p('Collect available quests for your next location, check the chain prerequisites, train essential abilities and repair. Set a return point and carry consumables. If the next quest is too difficult, finish nearby easier objectives or change hub rather than force an elite solo.')
sub('Before joining a dungeon')
p('Agree on your role, intended bosses, quest objectives and any key or summoning requirement. Bring the quest before entry when required. A low minimum quest level does not establish a safe party level. Complete worthwhile quests together; repeat only if the expected benefit justifies the time.')
sub('Class and role interpretation')
p('A Holy Priest gear target serves the healing profile. Solo leveling can still favor sustained damage, a useful wand and fewer recovery stops. Other classes should apply the same activity plan while using their own role-appropriate weapon and armor goals. The current prototype does not have verified per-spec stat weights or talent guidance.')
sub('Known route anchors')
p('Alliance: The Defias Brotherhood chain supports an early Deadmines plan; The Fury Runs Deep supports Stockade planning. Around the level-30 sample, The Grand Betrayal (Alliance) and Rig Wars (Horde) are Gnomeregan candidates. These are not automatic eligibility claims. Later, Screecher Spirits precedes The Prophecy of Mosh\'aru, then The Ancient Egg and The God Hakkar in the Classic chain; verify the live sequence before a long trip.')
sub('Data beyond the beta sample')
p('Levels 31-60 remain useful as Classic-derived planning bands, but their dungeon rewards and access are not source-confirmed for Forever in this release. At 60, choose a verified available activity and request an updated dataset before using any full-BiS comparison.')
new()
for index,s in enumerate(D['stages']):
    if index: new()
    sub('Levels %s-%s | %s'%(s['min'],s['max'],s['title']))
    p('Alliance: '+s['alliance']+' | Horde: '+s['horde'],'SmallX')
    for label,t in zip(['Solo / quest priority','Group / dungeon priority','Gear goal','Crafting priority','Prerequisites / gates'],s['tasks']):
        p(label+': '+t['text'])
    m=s['milestones']
    for label,key in [('Alliance named quests','alliance'),('Horde named quests','horde'),('Priest equipment goals','gear'),('Crafting / preparation','craft'),('Prerequisites / solo or group decision','gate'),('Priest class quests','classQuest')]:
        if m.get(key): p(label+': '+m[key])
    p('Evidence: Classic-derived planning; Forever route unverified. Sources: '+', '.join(s['sources']),'SmallX')
    if index%2==0: story.append(Spacer(1,10))
new()
h('5. Original curated sample - retained')
p('The six originally audited Holy Priest candidates below remain as a curated regression sample; the full expanded catalogue is recorded separately in SourceData.lua. Their individual item pages label them confirmed in the beta; this is third-party source verification, not a test by this addon author. Targets are candidates to compare, not guaranteed upgrades. The source list is a level-30 reference, so all sample recommendations expire after 30.')
table([['Target / item ID','Level window / activity','Slot / acquisition gate']]+[[g['name']+' / '+str(g['id']),str(g['min'])+'-30 / '+g['mode'],{3:'Shoulder',5:'Chest',7:'Legs',8:'Feet',10:'Hands',16:'Main hand (2H)'}[g['slot']]] for g in D['gear']],[205,145,145])
for gi,g in enumerate(D['gear']):
    if gi==3:
        new(); h('Verified gear - continued')
    sub(g['name'])
    p(g.get('levelNote','Wear level '+str(g['min'])),'SmallX'); p(g['acquire']); p(g['materials']); p(g['source'],'SmallX')
sub('Comparison policy')
p('Show the item currently equipped in the target slot and whether the exact target ID is equipped, in a carried bag, absent from a complete scan or unknown from an incomplete scan. Do not treat item level as a universal value score. Random suffix variants, ring uniqueness, two-hand/off-hand combinations and full-set optimization are not covered by this sample.')
new()
h('6. Install and test in Forever')
for text in [
'1. Close the client. Extract the ZIP and copy the RuinousForeverPlanner folder into the actual Forever installation\'s Interface/AddOns folder. The documented beta flavor is _classic_beta_; installations can differ.',
'2. Verify RuinousForeverPlanner.toc is directly inside Interface/AddOns/RuinousForeverPlanner. Enable the addon in the character-screen AddOns list. A mismatch with interface 16001 requires a compatibility check, not merely changing the number.',
'3. Log in, run /rfp, and select a profile. Class and Spec buttons cycle planning profiles; /rfp profile PRIEST Holy selects the verified sample. Solo / Group changes visible activities.',
'4. Use Priorities, Gear, Inventory and Help / Sources. Toggle completed activities with the numbered buttons or /rfp done NUMBER. Settings persist on normal reload/logout.',
'5. Compare Inventory with the actual character sheet and carried bags. Equip or move an ordinary item and verify refresh. /rfp scan requests a new scan; /rfp retry retries unresolved names.',
'6. Enable Lua errors with /console scriptErrors 1 and record /run print(GetBuildInfo()). Test every tab, scroll, drag, close and button. No live behavior is certified until these checks pass.',
'7. Check character isolation and persistence across /reload and another character. Test level-band transitions and Solo hiding dungeon targets. At 31 and 60, the sample must show no verified current-level targets.',
'8. Test in and out of combat: scan should defer in combat, then refresh. Test unresolved item data and a client without expected APIs; incomplete states must stay visible.',
'9. Disable the addon through the AddOns list if any test fails. Preserve SavedVariables before reset. Report build, class/level/faction, exact steps and first full Lua error.']:
    p(text)
sub('Release gate')
p('A working offline prototype has been constructed and validated. A client-tested release remains gated by the above live checks on the user\'s actual build. UI templates, event timing, SavedVariables disk persistence and restricted-value behavior cannot be certified by mocks.')
new()
h('7. Validation and remaining work')
table([
['Check','Result / boundary'],
['Lua syntax/runtime','All shipped Lua files parsed using Lua 5.1 grammar and executed through native Lua 5.1 (lupa 2.8). All WoW APIs remain mocked.'],
['Behavior',test_count+' mocked assertions passed, including equipment/bag reads, cache handling, adaptive actions, mode filtering, milestones, faction gates, profile isolation and schema migration.'],
['UI smoke','Frame construction and button handlers exercised with mocks; actual visual layout and frame-template behavior require the client.'],
['Data and packaging','Levels 1-60 each map to one band; task IDs unique; both TOCs resolve; required scanner symbols exist in exported API.'],
['Document','Selectable text PDF rendered and visually inspected; copy-friendly Markdown companion generated from the same authoring flow.'],
['Not executed','In-game addon load, real item cache/quest events, combat security, actual quest eligibility and SavedVariables disk round trip. File staging alone does not prove runtime behavior.']
],[105,390])
sub('Acceptance examples')
p('At level 26 in Holy/Solo, gloves and leggings appear; chest is a group target. In Group, robes and the Alliance-only Defias quest candidate appear too; the latter carries explicit unverified acceptance and wear gates. At 27 the mantle appears, and at 30 boots appear. At 31 the sample is unavailable. Switching to Mage/Frost must not reuse Holy Priest targets. Owning leggings in a bag must say not equipped. Missing bag API must result in an incomplete scan rather than a confident absent-item claim.')
sub('Next data milestones')
p('Original v0.5 reconciliation is complete; retain the requirements traceability on future updates. Expand verified records across every slot and leveling band, then other profiles. Add provenance per quest and recipe gate, explicit faction/class restrictions and a source-conflict review queue. Implement real quest/profession checks only after API verification. Add scoring and trend history only once complete comparison sets and tested stat rules exist.')
sub('Version and reproducibility')
p('Addon 0.22.0; data reviewed October 20, 2026. tools/make_data.py emits the shared dataset; tools/test.js validates shipped Lua and behavior; tools/build_prd.py builds this document. README and SOURCES in the addon contain installation, test steps and evidence boundaries. Test dependencies are development-only, not loaded by the client.')
new()
h('8. Sources and provenance')
p('Reviewed October 20, 2026. Source labels distinguish author guidance, community client exports and observed beta item records. No source establishes universal Forever compatibility.')
for si,(key,url) in enumerate(D['sources'].items()):
    if si and si%8==0:
        new(); h('Additional quest references')
    p(key.capitalize()+': '+url,'SmallX')
    p({'forever':'Holy Priest level-30 beta list; reviewed for candidate selection. Not a 1-60 ranking.',
    'api':'Client-exported API reference, build 70170 / interface 16001. Scanner contracts and global symbol presence checked.',
    'classic':'Classic starting zones and broad route approach; original planning summaries adapted for this product.',
    'alliance':'Judgement\'s Alliance route. Search-index excerpts reviewed; direct retrieval failed. Human Paladin specialization limits generalization.',
    'horde':'Nightfall\'s Horde route. Search-index review only; direct retrieval failed. No exact gate claims adopted.',
    'priest':'Classic Priest leveling considerations. No Forever talent mapping is asserted.',
    'zf':'Classic quest preparations, Gahz\'rilla and the Yeh\'kinya chain.',
    'st':'Classic multi-stage Sunken Temple preparation.',
    'defias':'Individual source-linked quest IDs and predecessor order. Source mixes Classic reconstruction with observed Forever changes; live flags do not establish eligibility.',
    'foreverWands':'Author guidance for Forever leveling; early wand acquisition is guide-reported, not live-tested here. This does not establish level 31-60 availability.',
    'fireWand':'Forever item page confirms Fire Wand, item 5069, wear level 7. Acquisition source is not listed; no vendor claim is adopted.',
    'gravestone':'Forever item page for Gravestone Scepter, item 7001, and Blackfathom Villainy source. No wear level or full upgrade ranking is inferred.'}.get(key,'Classic quest / guide reference for named stage anchors. Availability and exact gates remain unverified for Forever.'),'SmallX')
p('Individual item URLs and conflicts appear with the gear records. API implementation/exporter source: https://github.com/Atraeau/WoW-Addons. Client UI reference: https://github.com/Gethe/wow-ui-source/tree/forever.','SmallX')
sub('Video review and excluded evidence')
p('The supplied v0.5 provides channel UCIgnGlGkVRhd4qNFcEwLL4A. Opening that URL returned a page titled AI Search with only generic navigation, not a reviewable WoW video catalog. No WoW claim is attributed to it. The user clarified that no leveling video exists and requested Classic guides. The channel remains an unresolved reference rather than authority for route data. Reported/unconfirmed items and Classic drop percentages are not used as verified Forever recommendations.')

new()
h('9. Adaptive planner in this build')
sub('Owned gear changes the next action')
p('The Priorities view now begins with a personalized action list. An equipped exact-ID target removes its acquisition task; an item in carried bags becomes an inspection action, rather than a duplicate acquisition goal. An incomplete scan produces an unknown-state action. Unowned candidates become current comparison or future preparation actions, with their gates and evidence explained.')
sub('Manual prerequisites and profile independence')
p('Use /rfp gate ITEMID ready, blocked or unknown to declare prerequisite readiness. This is a manual assessment, not an API-derived eligibility verdict. Blocked candidates move to prerequisite resolution. /rfp skip ITEMID defers an unowned goal for the selected profile. Class/spec/PvE/PvP profiles retain separate overrides and histories. Selecting PvP never reuses the PvE ranking dataset.')
sub('Future milestones and stage previews')
p('Use /rfp target 30 to set a separate future milestone. The toolbar now opens Dungeon / XP; Guide automatically plans ten levels ahead. The future target is never interpreted below the actual level. /rfp preview 45 shows that stage without pretending the character is level 45; /rfp preview live returns to current-level guidance. Actual ownership planning stays tied to the live character level. Future wear eligibility remains explicitly unknown until checked.')
sub('Group and preparation views')
p('The Group view consolidates this character\'s outstanding Jargba sample objectives, excluding equipped targets. Solo mode retains preparation for that future outing. Other members are explicitly unknown because party messaging is deferred. Preparation lists materials and prerequisite notes beside each outstanding target; no unverified craft is automated.')
sub('History is evidence, not a simulated readiness score')
p('Up to 60 distinct coverage observations are saved per profile. Each records live level, equipped and bagged matches, unknown count, sample denominator and dataset version. Unchanged observations are deduplicated. A changing denominator or dataset version is visible. No numeric combat readiness or percentage-to-full-BiS is claimed.')
new()
h('10. Structured quest-state slice')
p('The Defias chain is now a small structured route linked to the Staff of Westfall acquisition candidate. Source-linked IDs, predecessor edges and objective summaries are bundled locally. The quest source distinguishes Classic baseline records from observed Forever changes; this is not a fully verified server eligibility graph.')
table([['Quest ID','Predecessor','Planning summary']]+[[q['id'],q['previous'] or 'None bundled',q['summary']] for q in D['quests']],[75,95,325])
sub('Observed state changes the plan')
p('C_QuestLog.IsQuestFlaggedCompleted and IsOnQuest supply completion and log-presence flags. An accepted later step takes precedence over absent earlier flags. Otherwise the planner suggests checking the earliest unresolved source-linked step, without claiming that it is offered or eligible. When the final quest is completed but the target is absent from carried gear, the plan directs the player to check reward choice or storage rather than repeatedly farm a one-time reward.')
sub('Unknown states and refresh')
p('False completion plus false log presence means only not in log / not recorded complete: availability, eligibility, repeatability and difficulty remain unknown. Missing or restricted flags remain unknown. Quest events schedule one refresh on the next frame and reads defer in combat. These observations do not replace manual stage checklist progress or infer that dungeon objectives are ready to turn in.')
p('Individual sources: https://foreverchanges.pro/quest/166 and its predecessor links. Runtime API contracts and QUEST_LOG_UPDATE / QUEST_TURNED_IN are present in the reviewed client export. Live-client observation still requires the pending acceptance test.','SmallX')
new()
h('11. Gear comparison and inspection')
p('The Gear view combines each active target with its current equipped comparison slot and carried alternatives matched by equip type. Every other inspected position is listed as having no active target in the current dataset or activity filter. This makes missing coverage visible without inventing an upgrade.')
sub('Client details and source conflicts')
p('C_Item.GetItemInfo supplies the cached client required level, item level and equip-location type. C_Item.GetItemStats supplies exposed numeric fields from the actual item link. Unknown, uncached or restricted fields remain unknown. This is a partial inspection aid, not a complete model of enchants, effects, usability or combat value. Item level is explicitly not an upgrade score.')
p('A higher client required level inside the source window changes the action to future preparation. If the cached requirement exceeds the entire local source window, the record becomes a conflict to verify, not an invented future recommendation. Source and client facts are shown separately. A two-hand candidate requires considering the off-hand contribution, not comparing an isolated weapon slot.')
sub('Tooltip controls')
p('Previous / Next selects an active candidate. Target tooltip requests its item hyperlink; Equipped tooltip uses the live equipment location; Bag tooltip uses the exact carried location. Next bag item cycles equip-type alternatives. This preserves the client tooltip for owned variants rather than substituting a generic ID. Matching a slot does not establish class, training, maker or dual-wield eligibility.')
p('Inspection uses a private GameTooltipTemplate frame with guarded, source-reviewed SetHyperlink, SetInventoryItem and SetBagItem accessors. It defers in combat and never equips, moves or consumes items. A successful call means a tooltip request was made, not proof that the client rendered all data. Actual appearance and behavior remain part of the live acceptance test.')
p('Additional commands: /rfp item ITEMID, /rfp slot SLOTID, /rfp bag BAG SLOT. Live test: compare all three controls with character sheet and bags, move a bag item and verify rescan updates its location, and inspect an uncached target without fabricated stats.','SmallX')
new()
h('12. First-client-test diagnostics')
p('After restarting the intended Forever client and enabling the addon, open /rfp and run /rfp doctor. The report uses that runtime\'s GetBuildInfo result, API-capability flags and scan counts. A planner UI exception is contained and its first bounded error is recorded, leaving the diagnostic command available. A successful frame-build/render call is not a visual layout or combat compatibility certificate.')
sub('What is saved')
p('Normal reload or logout saves per-character diagnostics with capability flags, actual build/interface, scan counts and a UI-error message limited to 500 characters. It does not persist an inventory snapshot, item links, gear stats or a full quest log. No report is transmitted. No automatic reload, restart, movement, equip or other gameplay action is performed.')
sub('Live acceptance sequence')
p('1. Restart the Forever client so it discovers the staged addon, enable it and log into a character. 2. Open /rfp; inspect every tab, scroll area and tooltip control. 3. Run /rfp doctor and preserve any first error. 4. Compare equipment/bag IDs and locations with the game UI. 5. Toggle a checklist, reload normally and verify it remains saved. 6. Test the supported Defias quest flags if applicable and confirm an unavailable quest is not described as eligible. 7. Test combat deferral and source/client requirement conflicts without automating gameplay.')
p('Until those observations are available, native Lua tests, frame mocks, source review and staged files support an installable test build only. They do not prove that the addon has successfully run in the actual client.')
new()
h('Profession planning, active specs and world loot')
p('The Professions screen integrates learned profession skill/cap observations with the ten-level XP plan. Twelve standard profession guides have local attributed route summaries, gear/supply uses, preparation notes and manual skill-band checklists. A dropdown supports browsing unlearned professions as previews; it never changes professions. A character-level 1-60 time-efficiency policy prioritizes nearby gathering and batched town crafting over detours for temporary gear.')
sub('Coverage and prerequisites')
p('Ten guides use Forever-specific WoW-Professions sources. Herbalism and Skinning use Classic-derived heuristics. Several Forever crafting sources end at skill 225 because recipe ranges changed; those later sections remain explicitly incomplete. Other post-cap summaries remain untested. Skill bands are not character levels. No automatic recipe ownership, material inventory, craft quantities, auction prices, node coordinates, trainer eligibility or measured craft time savings are claimed. Camping and other new skills have no bundled route.')
p('Source index: https://www.wow-professions.com/forever | reviewed October 21, 2026. Per-profession URLs and condensed route summaries are bundled in ProfessionData.lua and research/professions.json. Sources are third-party beta observations, not author-run client verification.')
sub('Automatic profile selection')
p('Login selects actual class and attempts the active spec through exported C_SpecializationInfo.GetSpecialization/GetSpecializationInfo before the first inventory scan. Known spec IDs map independently of client language; only supported specs for the actual class are accepted. Missing/unselected specs retain a class-specific planning fallback, labeled in the header. Talent/spec events refresh selection; manual previews remain available. /rfp current re-detects. No talent, loot-spec or equipment changes are performed.')
sub('World tooltip corrections')
p('Direct secure post-hooks for GameTooltip loot, bag, hyperlink, loot-roll and inventory methods supplement the shared item processor. Exact available links preserve enchant/suffix details. Uncached items request data and retry briefly only while the same tooltip remains visible. Existing forbidden/combat/setting guards and duplicate protection remain. A pickup alone does not create a popup. Empty/zero baselines and unavailable data do not produce invented percentages. These paths require live loot/bag acceptance testing.')
sub('Validation added')
p('New mocked tests cover sparse learned-profession returns, localized skill names, cap warnings, source-linked skill bands, saved checklists, Warrior/Fury login and stale Priest previews, spec failures, exact loot/bag links and pending tooltip retries. Native Lua 5.1 and Fengari execute the suite; they cannot verify actual client visuals or server behavior. See the updated usage guide for the guild QA sequence.')

new()
h('Class progression, vendor history and bundled quest data')
sub('Questie-driven class quest planning')
p('The Class Qs page and ten-level guide prioritize actual-class progression checks before optional gear detours. Runtime QuestieDB class categories/masks, player race/faction, minimum level, completion/log flags and AND/OR prerequisites choose a next chain step. Shared steps deduplicate; active quests rank first; future levels are labeled. Known exclusions and parent/availability gates are checked. Missing or cyclic chains remain unresolved. Players can pin resolved steps to the existing tracker, then choose the next one after completion.')
p('The consumed Questie contract has no reliable reward-spell field. The planner therefore does not guarantee specific form, pet, totem, mount or ability unlocks, or their effect on leveling time. Class quests can require elites or dungeons: group difficulty and quest-giver availability remain manual checks. Provider race-mask mappings cover custom races where supplied. A manual class preview cannot redirect actual-character class priorities.')
sub('Vendor database and sell decisions')
p('Merchant visits store observed stock purchase price, stack quantity, extended-cost flag, vendor identity and timestamp. Bag-item unit sell values are stored separately. History is saved per character, capped at 50 merchants and 2,000 sell records. No purchase/sale is performed. C_MerchantFrame.GetItemInfo is used instead of the absent legacy GetMerchantItemInfo global.')
p('The Sell page protects potential numeric upgrades, tracked/manual-kept goals, quest items and exceptional quality. Auction/de values are manual expected NET returns per item ID and expire after 24 hours. The default extra-effort threshold is ten silver per item. Auction requires known unbound status; disenchant candidates require a known Disenchant spell but still need item/skill/yield confirmation. Missing market values remain unknown; vendor-for-speed is not a highest-profit claim. No auction scanning, automatic sales or disenchanting is implemented.')
sub('Combined dependency package')
p('A separate with-QuestieDB ZIP contains both addon folders. QuestieDB remains an independent, unchanged 1.0.6 Forever/Camelot dependency from commit 36ca1ca86f6c1838de479c7c7452eb0a57d5c135. The bundle retains upstream author credits, licensing/provenance notices, and corresponding source archive. It does not include the full Questie map UI. Existing newer working dependencies should be retained. The upstream licensing notice allows copying under GPLv3 terms and describes historic contribution caveats: https://github.com/Questie/QuestieDB/blob/master/LICENSE.md .')
sub('Acceptance boundary')
p('Tests cover all nine class categories, shared prerequisites, completed/excluded branches, cycles, pinning, unknown/expired prices, binding, Disenchant absence, protected upgrades, separate purchase/sell values and stack math. Both Lua runtimes use mocked APIs. ZIP checks verify untouched dependency files, TOC resolution, notices and source inclusion. Live class quest, merchant, price persistence and disenchant eligibility acceptance is still pending.')

reqs=json.loads(Path('research/requirements.json').read_text())
for start in range(0,len(reqs),7):
    new(); h('v0.5 requirement traceability '+str(start//7+1)+'/4')
    p('Implemented offline means exercised with local mocks, not certified in the WoW client. Partial and deferred requirements remain part of the product scope.')
    table([['Requirement','Status','Implementation / remaining boundary']]+[[r[0]+' '+r[1],r[2],r[3]] for r in reqs[start:start+7]],[125,95,275])
new()
h('Historical baseline: original v0.5')
p('The following nine pages reproduce the user-supplied PRD unchanged for full requirement preservation and review. They are historical baseline pages, not statements that the current prototype has no code authorization. Current implementation status is documented in the preceding revision and requirement traceability.')
p('Source: WoW_Forever_Progression_Planner_MVP_PRD_v0_5.pdf, supplied by the user. Original date: October 18, 2026. Current revision date: October 20, 2026.')

def footer(c,doc):
    c.setStrokeColor(colors.HexColor('#dce4e8')); c.line(50,43,A4[0]-50,43)
    c.setFont('Helvetica',8); c.setFillColor(colors.HexColor('#526470'))
    c.drawString(50,30,'RUINOUS FOREVER PLANNER | v0.22 integrated | prototype')
    c.drawRightString(A4[0]-50,30,str(doc.page))
doc=SimpleDocTemplate(str(out/'Ruinous-Forever-Planner-PRD-v0.22.pdf'),pagesize=A4,rightMargin=50,leftMargin=50,topMargin=48,bottomMargin=60,title='WoW Ruinous Forever Planner PRD v0.22',author='Progression Planner project')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
from pypdf import PdfReader, PdfWriter
target=out/'Ruinous-Forever-Planner-PRD-v0.22.pdf'
writer=PdfWriter()
writer.append(str(target)); writer.append('research/original-v0.5.pdf')
writer.add_metadata({'/Title':'WoW Ruinous Forever Planner PRD v0.22 - integrated update to v0.5'})
temporary=out/'merged.tmp.pdf'
with temporary.open('wb') as f: writer.write(f)
temporary.replace(target)
md.append('\n# Original v0.5 baseline (user supplied)\n')
for page in PdfReader('research/original-v0.5.pdf').pages: md.append(page.extract_text()+'\n')
Path('output/Ruinous-Forever-Planner-PRD-v0.22.md').write_text('\n'.join(md),encoding='utf8')
print('Built PDF and copy-friendly Markdown')
