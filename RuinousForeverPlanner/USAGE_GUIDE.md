# Ruinous Forever Planner — Usage Guide



Version 0.22 • Start here • WoW Forever prototype



## 1. What the addon helps you decide



Ruinous Forever Planner connects your equipped gear, carried items, planning profile and quest progress. Use it to choose a useful next activity, track a small number of gear goals, and compare upgrades without repeatedly farming rewards you already own.



It offers planning advice. It never changes talents, equips items, purchases materials, accepts quests, turns quests in or sends party messages for you.



## 2. Install, update and first launch



1. Fully close WoW Forever before copying an update.

2. Extract the ZIP. Copy the RuinousForeverPlanner folder into your actual Forever client's Interface/AddOns folder. Avoid an extra nested folder.

3. Start the client. Enable Ruinous Forever Planner and QuestieDB in the AddOns list. QuestieDB supplies the full installed quest baseline; it is a separate addon.

4. Log in and type `/rfp`, or left-click the RFP minimap button. Right-click the minimap button for settings.

5. Verify the automatically selected class/spec and choose PvE/PvP and Solo/Group mode. If active spec detection is unavailable, the header labels the class-specific planning fallback; dropdowns allow manual previews.

6. Click Scan gear. Allow pending item names and the QuestieDB index to finish loading.



The local installer archives the old ForeverPlanner folder outside AddOns. Do not enable both the old folder and the renamed addon. Settings for the renamed addon use RuinousForeverPlannerDB and save on normal reload/logout.



## 3. Choose the right profile



Class and Spec open dropdown lists. The selected choice is marked. Extra profiles such as Feral (Tank), Shockadin and Subtlety (Hemo) represent planning roles or source-list variants; selecting one does not alter your character.



Each class/spec/PvE-PvP profile keeps separate tracked gear, quest pins, skipped targets, preparation assessments and estimate weights. Solo/Group changes activity advice, not your character's group or talents. Selecting another class is a preview: the scanned inventory still belongs to your current character, and personalized rating requires the actual class.



Every supported combination maps to a published class/role list or an explicitly labeled shared reference. For example, Discipline PvE uses the published Holy healer reference. A shared list is not a dedicated verified ranking for that exact spec/context.



## 4. Priorities: your next few actions



Priorities is the short action list. It uses ownership and known quest progress to avoid unnecessary acquisition. A carried item produces an inspection suggestion; a completed one-time quest is not suggested as a repeatable farm. Unknown inventory or eligibility stays visible.



Below level 55, expensive dungeon/craft advice can become "Level to X first" when a supported better same-slot candidate is within three levels and comparable stats exist. Missing future data does not imply a replacement. At 55+ this shortcut is disabled.



Guide now adds a ten-level efficiency plan based on your actual level, equipped/carried gear, current profile, quest progress and Solo / Group choice. The window follows your level automatically and stops at 60. Stage previews remain separate. The top toolbar's Dungeon / XP button replaces Milestone +5; the older /rfp target command remains available.



### Ten-level efficiency guide

Open Guide after scanning gear. Item data loads in small batches outside combat; reopen Guide if it is still loading. Read the reason beneath each action: INSPECT CARRIED, ON-ROUTE QUEST, CHECK QUEST CHAIN, LOW-COST ONLY, OPTIONAL GROUP, ONE PREPARED RUN, LEVEL FIRST, PREPARE AT LEVEL, or SKIP FOR XP. These are explainable planning rules, not measured time savings from gear. Positive upgrades use current client stats; unavailable stats remain unscored. Future candidates must fit the next ten levels. Short-lived group/crafting goals can yield to a stronger easier candidate within three levels, below level 55.



The plan includes stage hubs crossed within the window and local similar-level quest checks from the installed QuestieDB. Matching zone and level does not prove a fastest quest order or safe solo difficulty. QuestieDB indexing, prerequisites and live quest-giver availability still matter. Solo healer planning excludes healing-only stats and considers spell damage; this does not change your Rating weights. The remaining planning window is not a predicted item replacement date.



Same-type weapon base-DPS comparisons are included when live English item tooltips resolve. They do not simulate character damage, procs, swing-speed benefits or feral forms. Main-hand/off-hand changes are now compared together with resolved permanent enchants. Unsupported cases stay unknown. Random-suffix catalogue records and unresolved armor-training changes do not become proven upgrades.



### Five-player dungeon versus grinding

Click Dungeon / XP, then Previous / Next dungeon to inspect dungeons overlapping your ten-level window. The bundled reference contains 34 dungeon/wing records, including the nine new Forever dungeons, 331 quest rows and 2,058 reward/drop rows. These are source records, not distinct-item counts or a complete live database. Upper Blackrock Spire is excluded from the five-player list. New ranges are source-attributed to Blizzard; Classic ranges are reference ranges unconfirmed in Forever.



Start grinding sample, close the panel and grind normally for at least a minute, including recovery time. Avoid quest turn-ins and dungeon XP: every XP source during the sample is counted. Return and Finish grinding sample. The measured XP/hour is saved; an interrupted/reloaded sample must be restarted. You can also enter a measured XP/hour manually.



For a dungeon, enter expected kill XP for your character's share, clear minutes, travel minutes, group-wait minutes, and preparation/wipe/quest-turn-in overhead. Enter zero where an overhead does not apply. Other verified quest XP is **additional** XP: do not include quests already in the automatic subtotal. Save / compare to calculate. Estimates must be reconfirmed after each level-up.



The automatic subtotal uses beta reference XP only for accepted, uncompleted, faction/class-matching source quests with known minimum levels and no more than five levels below your level. Other accepted quests are marked unpriced. Future/unaccepted quests appear for preparation and do not silently add XP. Live XP scaling, prerequisites, mutually exclusive quests, objectives and reward selection still require inspection.



First-run XP/hour includes all entered time. The decision compares the complete run against grinding for the same amount of XP, shows break-even total XP and maximum tolerable wait, and separately estimates grinding to your next level when XP APIs resolve. A dungeon can win for total XP while grinding reaches your next level sooner. The kill-only repeat rate omits one-time quest XP and is explicitly before repeat overhead; it is not a promise about repeat-farming speed. Estimates within two minutes are a close call.



Inspect gear alongside XP. Quest rewards require successful completion and choosing the item; boss drops are random. Drop chance, loot competition, future combat time saved and prices are unknown. A slower XP run may still appeal for gear, but RFP does not invent a time credit to force that decision.



Use Track first unfinished quest or Track first gear candidate in the dungeon panel. In Guide, Track top upgrade pins the first efficiency goal instead of a Rating goal. Settings can show the ten-level plan in the objective tracker and clear leveling gear goals. Quest pins are managed separately in Quest catalogue. Normal reload/logout saves preferences and estimates.



## 5. Rating: understand the optimization percentage



Open Rating for the estimated gear rating, source reference, slot breakdown and the largest measurable improvements. A short summary also appears in Priorities, Gear and the objective tracker when enabled.



For armor and jewelry, the addon divides your equipped item's weighted stat score by the best eligible confirmed candidate score, capped at 100%. Resolved permanent enchants are included. The main hand and off hand are compared together: the set ratio counts as two positions for a one-hand setup and one for a two-hander. An impossible empty off-hand position is removed for two-hand setups. An empty slot counts as 0% only when a valid benchmark exists. Unknown stats or absent benchmark data are not treated as zero.



Example: "Estimated gear rating: 85.0% | 12/17 positions evaluated | partial coverage" means the evaluated slots average 85% of their weighted benchmarks. It does not say your entire character is 85% of maximum healing or damage, or that the unscored five slots are optimized.



Two ring/trinket references must be distinct. Swapping ring positions does not change the paired calculation. Bags do not count as equipped. Skipping difficult targets or switching Solo/Group does not shrink the rating denominator to raise the result.



A recommendation's potential rating points estimate the improvement within the currently evaluated slots if that reference item replaced the displayed baseline. Five percentage points means 50% to 55%, not a 5% relative combat gain. Your benchmark set can change when you level or change profile/weights, so ratings across those changes are not directly comparable.



Use Track top upgrade to pin the highest-ranked measurable recommendation. It may suggest inspecting an item already in your bags. Completed quest rewards and skipped targets are not presented as fresh acquisition steps.



## 6. What "100%" and "full BiS" mean



A 100% estimated score for a partial subset is not full BiS. Even a complete weighted-stat score is not a combat simulation: procs, set effects, unscored enchant effects and unweighted stats can change real performance.



The separate "verified full BiS" status requires a complete, locally certified item-and-enchant set for your exact level, class, spec and context, matched against equipped items. Random suffixes and two-hand configurations need explicit verification. Rounding a score to 100%, owning items in bags, or merely reaching level 60 cannot unlock it.



The level-60 easter egg is awarded only when that full-set check passes. The present imported catalogue describes level 30 and includes no complete certified level-60 sets. The feature is ready for such data; no level-60 qualification is invented from the level-30 list.



## 7. Gear: compare candidates and read the colors



Gear shows source-backed candidates for your current profile, level, faction and activity filter. Page - / Page + change the group of six displayed items. Previous item / Next item move the inspector selection. Target, Equipped and Bag tooltip buttons request the normal item details without equipping anything. Next bag item cycles available carried alternatives for the comparison slot.



Positive numeric upgrade estimates are green. Negative estimates are red. Zero, changes too small to display beyond 0.0%, and unavailable estimates stay neutral. Color supports the written sign; it never replaces the number or the data warning.



Percent upgrade = (target weighted score / equipped weighted score - 1) × 100. It compares a candidate with the current comparison slot; it is different from potential overall rating points.



Item level alone is not treated as value. Role weights are editable in Settings > Upgrade estimate weights. Defaults are subjective starting values for healers, casters, strength, agility, ranged and tank roles, not authoritative Forever simulation weights. Ignore a percentage if it conflicts with required training, crafting restrictions, your build or a special effect the model does not cover.



Missing data, zero-score baselines and random suffix uncertainty remain unscored. Weapons, shields and held off-hands now enter the stat model, with main/off hands assessed together; this does not simulate weapon damage or combat performance. Source-confirmed numeric facts can back an uncached item only when the source also supplies a usable wear-level requirement.



## 8. Track targets and use the objective tracker



Track targets opens a paginated catalogue for your selected profile. Track pins an item; Untrack removes the pin. The floating objective tracker shows short item goals, colored estimates, actual equipped/carried ownership and the next known quest step. Source details remain in Gear, Quests and the target catalogue.



Prep cycles unknown / ready / blocked. It records your assessment of prerequisites, recipe access, supplies or party readiness. It does not complete a quest or verify a profession. A blocked target remains a real benchmark rather than disappearing from the rating.



Drag the tracker header to move it. Settings can lock its position, reset it, switch compact mode or hide it. Hide persists; restore Objective tracker in Settings. Tracker and planner text are hidden while a settings/target dialog is open and restored appropriately when closed.



## 9. Quests: gear rewards and completed chains



Quests shows supported reward candidates tied to the selected gear profile. It excludes rewards already equipped/carried and completed one-time final quests. Known later active/completed prerequisites advance the chain, even when old flags are missing. Completed exclusive alternatives can block an unavailable reward path.



Measurable positive rewards rank first. A reward with unknown value is labeled as a candidate to inspect, not a proven upgrade. A false completion flag only means the client did not report it completed; it does not prove the quest is available.



Solo mode can suggest preparation for a group objective, but does not make a dungeon soloable. Confirm the live quest giver, party difficulty and reward choice before traveling.



## 10. Quest catalogue: the full installed QuestieDB baseline



Click Quest catalogue. Search a quest name or exact numeric ID, then press Enter or Search. Nearby levels narrows the view; All levels includes every indexed level matching the selected class/race. Previous / Next page through results. Track pins a quest independently of gear goals. Completed tracked quests stop appearing as outstanding tracker objectives.



The index is built in batches outside combat. The status line reports progress. Refresh index updates the visible page after indexing advances; it is not a network download. Your installed Forever-flavor QuestieDB registry was audited at 5,226 IDs, while the runtime reads whatever IDs the enabled compatible provider actually exposes.



Class/race filters intentionally hide other-class/race quests from the visible result list. Quests can have profession, reputation, phase or other conditions that still need a live check. The catalogue does not guarantee every Classic quest exists unchanged in Forever or that QuestieDB knows every new server quest.



If QuestieDB is absent or incompatible, a clear message appears and the addon retains only its bundled source-linked subset. Enable/update QuestieDB for the full installed baseline. Existing Questie continues to manage its own map pins; this addon does not replace them.



## 11. Other tabs



Guide contains the staged 1–60 route, named faction quest milestones, crafting, gear planning and solo/group preparation. Classic-derived guidance is labeled and must be checked against live Forever availability. The detailed Priest milestone notes are hidden for other class profiles.



Inventory shows actual equipped gear and carried bags. Bank, mail, auction and account storage are excluded. A carried item is ownership evidence, not proof that you can use it.



Group collects your own group objectives by activity. Other party members' goals are unknown; no party synchronization or messaging is performed.



Preparation shows relevant quest observations, materials and manual gates. Help contains command examples, evidence sources and sample coverage history. That existing history records item-match counts, not a simulated combat trend or guaranteed optimization history.



## 12. Settings and saved choices



Minimap button: show/hide the RFP launcher. Use `/rfpsettings` to recover it.



Objective tracker: show/hide the floating goal panel.



Leveling recommendations / Gear recommendations: enable or disable those views. Turning a view off does not alter your equipment or inflate the rating.



Automatic gear scans: refresh equipment/bag observations from events. When disabled, changed gear becomes stale until you click Scan gear.



Lock tracker position / Reset tracker position: prevent accidental dragging or restore its starting position.



Compact tracker: keep the shortest goal view.



Quest reward suggestions: show/hide automatically suggested gear-reward quests in the tracker.



Gear optimization rating: show/hide the estimated rating summary and enable its Rating view.



Upgrade estimate weights: adjust the numeric value assigned to supported stats. Weights and tracked goals save independently for each planning profile; display settings and position save per character.



## 13. A practical play-session routine



1. Select your actual class/spec and intended PvE/PvP role; scan gear.

2. Read the rating coverage before the percentage. Review unscored slots separately.

3. Inspect carried upgrades before planning travel or a craft.

4. Pick one or two high-impact goals. Prefer nearby quest chains and follow level-first advice rather than grinding a short-lived item.

5. Check completed/exclusive quest paths and confirm live reward choices. Combine objectives for one prepared dungeon visit.

6. Track those goals, close the planner and play using the short tracker.

7. Reassess after leveling, replacing equipment or changing role. Save with a normal reload/logout.



## 14. Troubleshooting



No candidates: check class/spec, context, faction, level and Solo/Group. The published imported item lists are level-30 references. Level 31+ gear coverage is incomplete, even though leveling guidance remains available. Shared mappings are explained in the source label.



No rating: refresh gear, wait for item stats and check that a confirmed benchmark exists at your level. Do not turn unknown data into a 0% judgement about the character.



Unknown quest progress: allow the provider index to finish, leave combat and refresh. Verify QuestieDB is enabled. Check the live quest log if completion flags differ from expectations.



Missing minimap button or hidden tracker: type `/rfpsettings` and enable the feature. Reset tracker position if it was moved off the expected area.



Unexpected error: run `/rfp doctor` and include its output with your QA report. A successful API call or passing offline test does not certify the in-game layout. If testing a new file/TOC layout, fully restart the client rather than relying only on a reload.



## 15. Command reference and evidence



`/rfp` opens the planner. `/rfpsettings` opens Settings. `/rfptargets` opens target selection.



`/rfp scan` rescans gear. `/rfp retry` retries uncached item names once. `/rfp doctor` prints diagnostics.



`/rfp profile PRIEST Discipline` selects a planning profile. `/rfp context PvE` or `/rfp context PvP` selects context. `/rfp solo` and `/rfp group` change activity filtering.



`/rfp target 30` sets a future milestone. `/rfp preview 45` previews a stage; `/rfp preview live` returns to actual-level guidance.



`/rfp gate ITEMID ready` accepts ready / blocked / unknown. `/rfp skip ITEMID` toggles a bundled profile target. `/rfp done NUMBER` toggles the corresponding visible stage checklist task.



`/rfp item ITEMID`, `/rfp slot SLOTID` and `/rfp bag BAG SLOT` request inspection only.



Source index: https://foreverchanges.pro/bis . The current bundle contains 38 source list variants, 634 distinct item records and 110 accessible linked quest pages. Source-confirmation claims are separate from author-run client tests. Full provenance and technical boundaries are in SOURCES.md; tests/build inputs are in the developer ZIP. No login, telemetry or runtime web access is required by this addon.



### Item tooltip ratings

Hover an equippable armor, jewelry, weapon or off-hand item in the Auction House, loot windows, bags or item links. RFP appends a green positive or red negative weighted-stat comparison against your equipped item, plus the estimated change in overall rating where a benchmark exists. Rings and trinkets show both possible replacement slots. Enable or disable Item tooltip ratings in Settings. Reopen a tooltip after changing settings or gear.



These are estimates using your selected profile and weights, not a damage/healing simulation or a guarantee that you can equip an item. Exact hovered item links are used for suffix stats. Missing stats, future level requirements, stale scans and absent benchmarks stay marked unavailable; weapon-set stat comparisons include the retained or removed off hand. Comparisons pause during combat. The rating remains partial when data is missing. Tooltip rating projections recalculate the stat model, including paired ring/trinket assignment and two-hand position changes. Unique-item restrictions and special effects still require manual inspection. Auction House and loot integration uses Forever shared tooltip processing; live client QA remains required.



### Enchants and complete weapon sets (v0.18)

Scan gear after applying or replacing an enchant. Rating and Guide show applied, missing, counted and unscored enchant effects. Exact owned links preserve permanent enchant IDs and suffixes. The reader compares an enchanted link with the same payload without its permanent enchant. If the API already includes the enchant it keeps that total; otherwise it adds recognized permanent-enchant tooltip stats to the unenchanted base. It never adds both. Numeric API differences can work in any locale; the guarded tooltip-text fallback currently supports English. Unrecognized proc or utility effects retain known base stats and get an explicit unscored flag. Restricted or pending base data remains unavailable. Temporary oils, stones and spell buffs are not valued.



The bundled Forever catalogue has 165 enchant references, 103 with static effects the parser understands. At level 30, numeric enchant options explicitly recommended by your published class/role reference can augment the rating benchmark. Missing one can therefore reduce the rating even on the correct gear item. Other levels do not inherit an invented enchant target. Movement, procs, unsupported stats and item-specific restrictions remain outside the numeric model. Enchanting skill is the source-reported maker requirement, not a player wear level. Consult an enchanter about exact item restrictions, availability, reagents and cost; no crafting or enchanting is performed. A high crafting skill does not establish that the player can access that enchant.



A replacement off hand keeps your main hand; a two-hander removes the off hand; a one-hander replacing a two-hander leaves the off hand empty unless a complete pair is proposed. Guide can propose a one-hand-plus-off-hand pair and pins both items. Rating identifies its reference weapon set and counts the set once with the appropriate position weight. Shield/book and dual-wield stats are included, but weapon damage, block mechanics, procs, proficiency and unique-equipped restrictions are not a combat simulation. The importer now recognizes held, shield, two-hand and relic sections: 634 source item records and 110 accessible linked quest records are bundled. One linked quest page (79242) remains unavailable.



Item tooltips use the actual offered enchant. Buying a second copy of your current item does not transfer your existing enchant, so it can correctly appear as a downgrade. Tooltip predictions recalculate stat coverage without changing equipped gear. The rating remains an estimate; 100% of a partial model is not verified full BiS.



On Rating, Track top upgrade pins a missing-enchant recommendation as an enchant goal rather than marking the already-owned gear goal complete. Its tracker checks the target static enchant stats; unmodeled effects remain a manual review. Clear leveling goals in Settings also clears these enchant pins.



### Character switching and early-level data (v0.20)

Login selects your actual character class and live level. The active client spec is selected automatically when the supported spec API resolves it. If no spec is selected or readable, a saved class-specific planning profile is used (Frost for a new Mage), with an explicit fallback label. This never changes talents. Class/spec weights, checklists and other saved profile records are retained. Class and level previews are available during a session; login clears the level preview and returns to the actual class. Use /rfp current to return immediately from a manual preview. Diagnostics show actual class, selected class/spec, actual level and whether a class preview is active.



At level 10 the published Mage gear reference has no verified current-level targets. Gear now explains that limit and lists known Mage targets in the next ten levels as future references. These are not wearable-now or proven upgrades. The equipped-position rows are your current inventory, not recommendations. Early guidance and non-Priest stage tasks now use the selected class rather than Priest sample gear/crafts. If the class catalogue is missing, install the complete addon folder; another class's sample is not used as a substitute. Legacy automatic level-30 milestones are capped to the next ten levels below level 20; explicitly set /rfp target milestones are respected.



The main planner is opaque and uses the dialog layer above normal game action bars; settings and class/spec menus are layered above it. Third-party bar or hotkey addons using higher custom layers still need live QA.





## 16. Professions alongside XP and gear (v0.20)



Open the **Professions** tab or type `/rfp professions`. The **Profession v** button at the bottom right opens a dropdown of 12 standard professions. Learned skills and trained caps are read from the character on each refresh; other selections are labeled PREVIEW. This never learns or unlearns a profession. Camping and other Forever-specific skills currently have no bundled route.



Priorities and Guide include short next-step summaries for learned professions alongside the next ten character levels. Detailed routes use **profession skill points**, not character levels. Gather on your existing quest path, batch crafts and trainer visits in town, and avoid long farming detours for short-lived upgrades. Compare an actual crafted item using its tooltip before spending materials; these summaries do not certify a craft as an upgrade or measure its time benefit.



The detailed page includes preparation/material themes, useful gear or consumables, training reminders, solo/group advice, and remaining skill milestones. **Toggle 1–5** marks the first five displayed milestones; these manual checklists save separately per profession and character. A skill at its trained cap prompts you to check the next rank before wasting crafts. Completed skill bands disappear as your scanned skill advances. Settings includes **Profession recommendations** to disable the feature.



Ten guides summarize Forever-specific sources; Herbalism and Skinning remain Classic-derived heuristics. Several source routes end at 225; those later sections are explicitly incomplete. Other later recipes are marked untested. Recipe ownership, exact material counts, auction prices, gathering node availability and trainer eligibility are not scanned. Use the profession source URL on the page for the detailed recipe/vendor guide and confirm requirements in the client.



Source index: https://www.wow-professions.com/forever



### Automatic class and spec



On login, the actual class and readable active spec replace a saved manual preview before the initial gear scan. Spec changes also refresh the planning profile. If the spec API is unavailable or the character has not selected a spec, the header explains the class-specific fallback. `/rfp current` re-detects the current class/spec profile; the class/spec dropdowns still allow manual previews during a session. Live acceptance of the spec API is pending.



### World loot and newly acquired items



With Item tooltip ratings enabled, hover the item in the loot window, your bags or an item hyperlink. Direct world-loot/bag hooks supplement the shared auction/item hook. Uncached item data gets a short retry while the same tooltip stays visible. Close/reopen the tooltip if loading takes longer. Picking up an item does not create a separate popup. Unavailable stats, empty baselines, level requirements, combat and disabled settings can prevent a numeric comparison; unknown data is never treated as a zero-stat upgrade.



### Suggested guild QA



1. Log into a Warrior with a selected spec and verify the actual class/spec before opening the planner. Repeat on an untalented low-level alt and check the fallback label.

2. Open Professions and verify skill/cap against the client. Switch to an unlearned guide and confirm PREVIEW. Toggle a milestone, reload normally and confirm it persists.

3. Hover the same wearable item in a corpse loot window, then in bags after looting, and compare the displayed estimate with an auction tooltip. Test an uncached item and an empty-slot baseline separately.



Offline tests cover these paths; this release has not been tested live by the author.



## 17. Class quest priorities

Open **Class Qs** or `/rfp classquests`. Guide and Priorities put class-chain checks before optional gear detours. The planner uses the installed QuestieDB class category/mask, actual player class/race/faction, known completion/log flags, minimum level, AND/OR prerequisites and known exclusions. It deduplicates shared prerequisite steps and looks ten levels ahead while retaining unresolved older class chains. An active step is prioritized; future steps are labeled UPCOMING. Missing, cyclic or inaccessible branches stay unresolved.

Click **Track class quest** to pin the first resolved step, or `/rfp classquest ID` for another displayed step. Completion hides the pinned step; revisit Class Qs to pin the next one. It does not automatically complete or accept quests. Optional gear rewards can still be evaluated on Gear.

QuestieDB does not expose a reliable reward-spell field through the consumed contract. The planner therefore flags class progression for review, but does not guarantee that a chain unlocks a specific form, pet, totem, ability or mount. It does not measure combat strength/time saved by those unlocks or prove solo difficulty. Check objectives/rewards and arrange help for dungeon/elite steps. Full Questie map pins/arrows are not included. Unknown race/skill/spell/reputation/access conditions still need live checks.

## 18. Vendor database and quick sell advice

Open **Sell** or `/rfp sell`. Use **Previous item / Next item** to browse carried items. **Toggle 1** keeps/unkeeps the selected item ID; tracked goals, quest items, exceptional-quality items and potential numeric upgrades are held for inspection. Unresolved wearable stats also require review.

Visiting a merchant records its stock price, purchase stack size, currency-cost flag and timestamp. It separately records the client sell value of items in your scanned bags. Vendor stock is what you pay; sell value is what you receive. The local, per-character history retains up to 50 merchant identities and 2,000 item sell values. Reputation discounts and stock availability can change. It never buys or sells anything.

Click **Edit sell estimates** and enter whole copper amounts per item: expected auction NET return, expected disenchant-material NET value and an extra-effort gain threshold (default 1,000 copper / 10 silver). Blank prices mean unknown. Include auction cuts, lost deposits, sale probability and material-selling costs yourself. Estimates apply to an item ID; inspect suffixes, enchants and variants before reusing one. Prices expire after 24 hours. The dialog can clear vendor history; your manual estimates are retained.

Auction advice requires known unbound status. Disenchant advice requires the character's known Disenchant spell plus candidate quality/type, but item/skill eligibility and yields are NOT verified. No Classic disenchant table is imposed on Forever. A vendor-for-speed result is a transparent threshold choice against known values, not proof that an unknown market value is lower. No auction scan, sale, purchase, mailing or disenchant action is automated.

For guild QA: visit a vendor with a known stack and compare stock purchase price to per-item sell value; reload normally and check history persistence. Enter a fresh net estimate, test bound/unbound items and a character without Disenchant, then verify a potential equipped upgrade is retained for inspection.

## 19. One download with QuestieDB

Use the **with-QuestieDB** ZIP for a fresh install. Close WoW and copy both **RuinousForeverPlanner** and **QuestieDB** into Interface/AddOns, then enable both. Keep one QuestieDB folder. If you already have a newer working QuestieDB, retain it and install only the planner folder. Your local update installer leaves the existing QuestieDB unchanged.

The bundle contains the unchanged QuestieDB 1.0.6 Forever/Camelot runtime from commit 36ca1ca86f6c1838de479c7c7452eb0a57d5c135, upstream author credits, licensing/provenance notices and its matching source archive. QuestieDB-source is documentation/source, not a third addon folder. QuestieDB remains an independent dependency and is not the full Questie map/tracker UI.

The upstream licensing notice permits copying under GPLv3 terms while describing historic contribution caveats. Read QuestieDB/LICENSE.md and gpl-3.0.md. Upstream source and notice: https://github.com/Questie/QuestieDB . All new runtime behavior still needs live guild acceptance testing.


## 20. Now, ordered routes and launch-day measurements (v0.22)

**Now** is the default page. Its first section follows an imported route when present; optional gear and class checks remain separate suggestions. Six main tabs keep the toolbar readable. **More** opens Inventory, Class quests, Professions, Sell, Group, Preparation, Priorities and Help. Detail pages retain their existing controls; Now shows route actions instead of item/checklist controls. Settings can disable Next action in tracker.

### Import a Factoruide route

1. Generate a **single-character WoW Forever** guide in Factoruide. Use its Share/export option to save a **.fgguide JSON file**. The compressed FGG1 text used by Factoruide's own addon is not accepted by this converter.
2. Open **ROUTE-CONVERTER.html** from this addon folder in your browser. Select the file and copy the converted text. The page runs locally; it uploads nothing and executes no pasted Lua.
3. In WoW, open **/rfp route**, or click **Import route** on Now. Paste the output and click Import / replace route. Invalid input leaves the current route intact. A successful import replaces this character's route; other goals remain saved.
4. The route must match actual class, race and faction, and its starting level must be reached. Unknown race identity pauses instead of guessing. Only file versions / route formats 1 and 2, 1-60 levels, and at most 5,000 steps / 1 MB of converted data are accepted. New upstream formats need a reader update.

**Automatic progress:** accept steps advance when the quest is observed in the log; objectives advance when their imported objective index is reported finished; turn-ins advance only on recorded quest completion. Previously completed quests catch up in bounded batches. Missing/restricted flags and unfinished prerequisites never become completed objectives. An absent quest is not proof it is available or was abandoned intentionally.

**Manual next** acknowledges travel, training and other manual actions. It can also pass a step you decide to skip; it is not proof of completion. **Undo** restores the most recently acknowledged step and pauses automatic progress so you can inspect it. Resume with **Auto progress**. Route progress and marks save per character on normal logout/reload. Clear current route in the import dialog to return to adaptive advice alone.

**Compatibility limits:** the bridge preserves step order, quest IDs, prerequisite/exclusion lists, readable instructions and destination coordinates. It does not reproduce Factoruide's combat/travel simulation, terrain path geometry, group-member ownership, item-buy/held conditions, parallel/background execution, planned time or gameplay automation. Background objectives stay in order and may need manual passing. Unsupported actions remain manual. There is no claim that an imported route is the fastest or safe in the launch client.

### Navigation and gear

**Map waypoint** requests the native map marker when that map, API and map-point helper are available. Otherwise it reports why it could not set one; the map ID and coordinates remain readable. This is a destination marker, not terrain-aware walking guidance. Follow roads, transport and the imported instructions yourself. No flight, movement, purchase, training or quest interaction is automated.

Now checks observed carried items across levels 1-60 for positive weighted-stat comparisons, independently of the level-30 external benchmark. It does not assume the character can equip a different armor/weapon type, score special effects or certify BiS. Inspect training and restrictions yourself. The source index was checked October 30 and still labels the published lists level 30; cached item facts remain October 20 evidence.

A source-backed Druid Cat Form reminder calls out Forever's level-20 quest chain when the spell is not reported known. The other class chains still use QuestieDB categories/prerequisites; a complete verified unlock-to-spell mapping for all classes is not bundled.

### Measure your results on November 4

Start XP sample and Finish sample on Now measure an actual play session of at least one minute. **All XP counts**, including quests, rested bonuses and dungeons; travel and recovery time remain in the denominator. Samples save to the character (up to 20). A reload cancels an active sample, but finished results remain. These samples do not overwrite the separate grinding-only baseline used by Dungeon / XP. A missed or ambiguous level transition invalidates the sample instead of inventing XP.

Open **Launch checks / report** for the acceptance sequence. OFFLINE-RELEASE-REPORT.md describes checks performed and known gaps. Both Lua runtimes and the converter have offline tests, including the upstream 870-step example. That example is not shipped as a route for every character. New behavior remains unverified in the live launch client.
