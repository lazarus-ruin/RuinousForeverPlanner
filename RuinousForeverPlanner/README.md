# Ruinous Forever Planner 0.22 prototype

An offline progression planner for WoW Forever. All nine classes and their talent specs have planning profiles, with extra source roles for Feral tank, Shockadin and Hemo Subtlety. **30 profiles / 60 PvE-PvP combinations** map to 38 published ForeverChanges lists. This does not claim complete verified BiS at every level.

## Install and open

Close the game. Extract the ZIP and copy **RuinousForeverPlanner** into the Forever client's `Interface/AddOns` directory. Enable **Ruinous Forever Planner**, then log in and use `/rfp` or the **RFP** minimap button. Right-click the minimap button for Settings. Recovery commands: `/rfpsettings`, `/rfptargets`, `/rfp doctor`.

This version is a complete rename: folder, TOCs, globals, commands and SavedVariables (`RuinousForeverPlannerDB`). The local installer archives the previous `ForeverPlanner` folder outside AddOns. The user explicitly requested no settings migration. Do not load both addon folders.

## Class and spec support

Choose Class and Spec from the dropdowns, and PvE/PvP and Solo/Group from their buttons. These are planning selections, not talent changes. The crawler reviewed all 38 lists linked by https://foreverchanges.pro/bis and followed 634 item pages and 111 linked quest URLs. 110 quest pages were accessible; 621 item pages labeled their items beta-confirmed. Unconfirmed records remain references. Random-suffix variants are never treated as owned from item ID alone.

Some spec/context combinations have no dedicated list. Discipline PvE explicitly uses the published Holy healer list as a shared role reference; generic Warrior, Hunter and Warlock lists serve their respective specs. Other shared combinations are labeled in the UI. They are not presented as verified spec-specific rankings.

The imported lists describe the **level-30 beta**. Known wear levels support earlier planning; unknown wear levels remain level-30 references. Levels 31-60 have general leveling guidance but no inferred item database. A missing bracket is not evidence that no upgrades exist.

## Gear and objective tracker

Gear is paginated; Page -/+ and Previous/Next item navigate. Track targets opens a paginated profile-specific catalogue. Track/Untrack a candidate to pin it to the movable tracker. Prep is a manual readiness assessment. Equipped/carried ownership is scanned, with incomplete/stale reads kept unknown. Never automatically equips, vendors, crafts, accepts or completes quests.

Settings control the minimap button, tracker, automatic scans, leveling/gear views, quest suggestions, compact mode and position lock. Drag the tracker header to move it. Dialogs have opaque backgrounds and hide underlying planner/tracker text. Full stage details are in Guide.

## Questie baseline

The addon reads the installed **QuestieDB contract 4** public API through an optional dependency. This client has QuestieDB 1.0.6, Forever flavor, whose baked numeric ID registry contains **5,226 quests** (audited locally). The addon enumerates every ID the live provider exposes and indexes metadata in batches of 20, outside combat. Questie/QuestieDB source code and full copyrighted quest narratives are not copied or redistributed.

Open **Quest catalogue** to search quest name or ID, choose Nearby/All levels, page through class/race-filtered results, and Track a quest. Every provider ID is indexable; the visible result list intentionally excludes other-class/race entries. Completed flags and active-log flags come from the client. Source-linked reward quests use known AND/OR prerequisites, class/race masks and completion state. Skill/reputation/other eligibility remains a live check. No claim is made that every Classic quest exists unchanged in Forever, or that the provider knows every newly added server quest.

With QuestieDB disabled/unavailable, only the bundled 110 source-linked quest records and audited curated chains remain available, and the UI says so. Keep QuestieDB enabled for full baseline access. Existing Questie remains responsible for its own map pins; this addon does not replace its map system.

## Upgrade estimate and level-first policy

Percent = `(target weighted slot score / equipped weighted slot score - 1) * 100`. Role presets cover healer, spell caster, strength, agility, ranged damage and tanks; weights are editable per class/spec/context. These are subjective planning weights, **not** source-validated simulation weights or healing/DPS gains. Resolved permanent enchant stats count once; unmodeled proc/utility effects, sets and unweighted stats stay explicitly outside the stat model. A cached client comparison is preferred; confirmed source numeric stats may be used when the client item is pending, with a known source wear level. Main-hand/off-hand sets and ranged item stats now enter comparisons; two-hand replacements remove the off hand. Random suffix uncertainty remains unscored for catalogue targets. This does not simulate weapon damage. Empty or zero-score baselines do not produce fictional percentages.

Below 55, a costly current dungeon/craft goal gives way to level-first advice when a supported better same-slot candidate is within three levels and comparable stats exist. Missing future data never triggers the rule. At 55+ it does not apply. Source availability, professions and training remain separate checks.

## QA checklist

1. Restart the client, enable Ruinous Forever Planner and QuestieDB; open `/rfp`.
2. Select your actual class/spec and context. Confirm Gear shows the source-list label and candidates at level 30. Shared lists must be labeled.
3. Inspect the equipped item baseline, track/untrack targets, switch profile and return; targets/weights should stay independent.
4. Open Settings over planner/tracker, change a switch and close it; no underlying text should bleed through.
5. Allow the QuestieDB index to finish, then open Quest catalogue, search a known ID/name, compare class/race/level filters and live quest flags, and track an unfinished quest.
6. Change equipped/bag gear; verify ownership/estimates refresh. With automatic scans disabled, gear changes should become stale until a manual scan.
7. Reload/logout normally to persist settings. `/rfp doctor` reports API/scan failures; it does not certify visual correctness.

Lua syntax, offline data invariants and mocked behavior are checked under native Lua 5.1 and Fengari. Prior builds were loaded by the user; **this expanded renamed build still needs in-game QA**.


## Optimization rating and usage guide

Open **START-HERE.html** in this folder for the complete offline usage guide, or read USAGE_GUIDE.md. It covers every feature, settings, practical routines, commands and troubleshooting.

The Rating tab estimates current gear optimization against confirmed wearable source benchmarks. It displays evaluated-slot coverage, per-slot ratios and recommendations sorted by potential rating-point gain. Track top upgrade pins a recommendation. Unknown slots never masquerade as optimized, bags do not count as equipped, and activity/skip filters cannot shrink the denominator to inflate the number. Equal-weight slot averages and editable role weights are estimates, not simulation.

Positive upgrade estimates are green; negative estimates are red. Neutral and unavailable values stay uncolored.

Full BiS is separately gated by a complete certified item+enchant set for the exact profile/level. A rounded or partial 100% score cannot qualify. A fully certified level-60 set unlocks the requested easter egg. No complete certified level-60 dataset is currently bundled, so that unlock remains unavailable until such data is added. The current imported lists are level-30 references.

Ten-level efficiency plan: open Guide. Dungeon / XP compares one prepared five-player run with grinding using accepted-quest beta XP, editable overhead and an optional measured grinding sample. Review gear separately from uncertain drops. Full instructions are in START-HERE.html. This feature has offline tests only; live client QA is pending.

Enchants and off-hands: scan gear after changing an enchant. Rating and Guide expose counted/missing/unscored effects. Published level-30 numeric enchant targets can affect the benchmark; other levels do not inherit an invented target. Track top upgrade pins an enchant recommendation as an enchant goal, or both items of a weapon set as appropriate. See USAGE_GUIDE.md for limits and test steps.

0.19 alt/window fix: login uses actual class and live level, preserves class-specific saved specs, and clears level preview. /rfp current exits manual preview. The level-10 Mage view explicitly reports missing current-level targets and shows future Mage references. The planner uses an opaque DIALOG layer above normal game action bars. Guild users reported v0.18 working on Priest and Druid; these new fixes still need live QA.


0.22 adds profession skill/cap scanning, 12 attributed guides, next-ten-level XP integration and per-character craft checklists. Open Professions or /rfp professions; Profession v chooses a guide. Recipe coverage is partial, and later untested ranges are labeled. Settings can disable profession recommendations. Login selects actual class and attempts the active client spec; unavailable specs use a labeled class-specific fallback. Direct loot/bag tooltip hooks and short pending-item retries supplement the shared item hook. See USAGE_GUIDE.md for source limits and guild QA. Offline tests pass; live acceptance remains pending.


0.22: Class Qs adds actual-class Questie chains to leveling and existing quest tracking. Sell adds merchant visit history and transparent vendor/AH/disenchant comparisons using manual net market estimates. The with-QuestieDB ZIP installs both folders and includes unchanged upstream runtime, notices and matching source. Read USAGE_GUIDE.md sections 17-19 for data limits and QA. No full Questie UI, reward-spell certification, automatic selling or disenchant yield prediction is claimed.


## v0.22 offline launch candidate
Now is the default view with six main tabs and More. Import ordered single-character Factoruide .fgguide routes through the bundled local ROUTE-CONVERTER.html and /rfp route; quest progress can advance supported steps automatically. Manual next/Undo, destination waypoint requests and all-level carried-gear checks are available on Now. Session XP samples provide observed results after launch. Read usage section 20 and OFFLINE-RELEASE-REPORT.md before November 4 testing. No live acceptance, terrain pathfinder, complete late-level BiS or full Factoruide simulation/automation is claimed.
