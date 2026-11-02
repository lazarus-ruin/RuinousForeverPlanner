# Ruinous Forever Planner - build checkpoint

Current candidate: **0.15.0**. This is the complete rename requested by the user; they explicitly said no saved settings require migration. Addon folder/TOCs, SavedVariables, globals and commands use RuinousForeverPlanner / `/rfp`.

## Current scope

The 38 English class/role variants linked by ForeverChanges /bis were crawled. 541 distinct item pages were parsed; 532 labeled beta-confirmed. 100 linked quest URLs were attempted; 99 were accessible. Sources, suffix variants, wear-level evidence and confirmation status are retained. Thirty planning profiles across 60 PvE/PvP combinations map all nine classes and specs/extra roles. Shared class/role mappings are explicit, including Discipline PvE to the published Holy healer reference. No unverified spec-specific ranking is claimed.

The installed QuestieDB 1.0.6 Forever provider exposes contract 4 and a baked registry of 5,226 quest IDs. Public GetAllIds/GetAll/RequireContract signatures were reviewed. The addon indexes every live provider ID in batches of 20 outside combat and offers a name/ID-searchable, class/race-filtered quest catalogue with tracking. It reads prerequisite groups/alternatives and active/completion flags; exclusive completed choices block acquisition advice. Provider absent/incompatible states remain explicit. No Questie source/database is redistributed.

The source lists describe level 30. Earlier candidates use known wear requirements or retained audited acquisition windows. Unknown wear levels are level-30 references. General 1-60 Classic-derived stage guidance remains available; gear for uncovered 31-60 brackets is not fabricated.

## Implementation

Equipped/carried scans, role-specific editable stat weights, guarded percentages, source fallback for confirmed known-level items, random-suffix safeguards, per-profile goals, short objective tracker, isolated opaque settings dialogs, Class/Spec dropdowns, paginated gear/targets, QuestieDB browser, and conservative below-55 three-level lookahead policy. Weapon/off-hand/wand comparisons remain unscored. No automatic gameplay, messaging, equipping or quest actions.

## Verification and limits

167 curated fallback regression assertions plus 4,659 imported catalogue/provider assertions under Fengari and native Lua 5.1; all 60 source profile/context mappings have nonempty level-30 candidate lists in mocks. Source facts, TOCs and package contents checked. Earlier versions were loaded by the user and screenshot evidence proves equipped-item scanning in 0.13. The new full import/provider integration and renamed UI await live QA. Do not claim a client test based on these mocks.

## Rebuild

Run tools/build-release.ps1 with the bundled Python. It regenerates curated content and compiles cached source facts, validates Lua and data, builds/renders the updated PRD and packages addon/developer ZIPs. Inspect rendered PDF pages. Then run tools/install-local.ps1 with the game closed, repackage and run tools/audit_release.py. The installer backs up/moves the legacy ForeverPlanner folder out of AddOns after verifying the new files.

Source crawl: tools/crawl_sources.py, with bounded concurrency and cached responses. Compiler: tools/compile_catalogue.py. Numeric installed baseline audit: research/questie/installed-baseline-ids.json. No upstream Questie code is included in deliverable archives.

## 0.15 optimization, color and usage guide

Added estimated per-slot/overall weighted benchmark rating with evaluated coverage, potential point-gain recommendations and a Track top upgrade action. Filtering/skips cannot inflate the denominator; paired ring references are distinct and slot-order invariant. Full BiS is a separate complete item+enchant certification for the exact profile/level. No current certified level-60 sets exist; the easter egg is implemented and tested with synthetic data, not falsely unlocked from a level-30 score. Green/red upgrade text retains explicit signs; unknown/neutral text stays plain. Bundled START-HERE.html and USAGE_GUIDE.md cover all features. New engine has 23 meaningful boundary/color/certification assertions. Live client QA is still required.

0.16.0: shared item tooltip comparisons added, with Settings toggle, signed stat changes and partial-model rating impact. Offline tests only; Auction House and loot client QA pending. No gameplay actions performed.

0.17.0: ten-level efficiency plan, 34 five-player reference records (nine new Forever dungeons), 331 quest rows, 2,040 reward/drop rows. Accepted/uncompleted beta quest XP; editable one-run XP/time tradeoff; break-even wait and next-level comparison; grinding XP sample; guarded same-type weapon base DPS; stage/local-quest integration; goal pinning and settings. No certified fastest route, drop odds or future minutes saved from gear. New release awaits live client QA.

0.18.0: fixed missing held/shield/two-hand/relic source sections; 634 imported items, 621 source-confirmed, 110 accessible linked quest records. Added 165 enchant references (103 static effects), exact-link enchant normalization without double counting, combined main/off-hand stat ratings/comparisons, conditional level-30 numeric enchant benchmarks, same-ID enchant downgrade handling and complete weapon-pair guide goals. Preserves base stats for unscored proc/utility effects. Includes regression checks; new release still requires live client QA.

0.19.0 (October 21): guild bugfix for action-bar overlap and low-level Mage / alt profile confusion. Main panel is opaque DIALOG, menus/settings above it. Login selects actual class/live level and retains saved per-class specs; /rfp current exits previews. Inventory snapshot isolated by identity. Missing catalogue cannot return Priest sample for Mage. Low-level Gear reports incomplete data and future-only correct-class references; early stage tasks use class guidance. New regression cases pass offline; this release awaits live visual/client QA. User-reported v0.18 Priest and Druid success remains historical evidence, not a test of v0.19.


## v0.20.0
Profession guides/skill scans/checklists, active-spec startup detection, and direct world-loot/bag tooltip hooks with pending-item retries. See usage guide for coverage and QA. No author-run live acceptance claimed.


## v0.21.0
Class quest priorities from QuestieDB, vendor observations and manual net sell advisor; combined dependency bundle with provenance and source. New paths pass offline tests; no live client acceptance claimed.


## v0.22.0 - October 30
Offline launch candidate: Now UI, Factoruide JSON route converter/follower, automatic supported quest progress, manual undo, guarded native waypoints, all-level carried comparisons and observed XP sessions. Native/Fengari/JS tests and ZIP audits required. Live November 4 acceptance pending.
