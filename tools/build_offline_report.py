from pathlib import Path
import json,re
version=json.loads(Path('release.json').read_text())['version']
results=Path('output/test-results.txt').read_text(encoding='utf-8-sig')
assert 'ordered-route, Now UI' in results and 'data-only route converter assertions' in results
report=f'''# Ruinous Forever Planner {version} - offline release report

Built October 30, 2026 for launch-day testing on November 4.

## What changed
- Now is the default page. Six main tabs replace the crowded twelve-tab row; More contains advanced views.
- Import ordered single-character Forever routes from Factoruide .fgguide JSON files using ROUTE-CONVERTER.html.
- Quest acceptance, indexed objective completion and recorded turn-ins advance supported route steps automatically.
- Manual next, Undo/pause, saved per-character progress, native waypoint requests and readable coordinate fallback.
- Carried upgrades can be flagged across levels 1-60 from scanned item stats, even without an external BiS benchmark.
- Source-backed Druid Cat Form reminder distinguishes Forever's quest chain from Classic assumptions.
- Session XP samples count all XP and save up to 20 observations, separate from grinding-only estimates.

## Validation performed
- All shipped addon modules parse as Lua 5.1.
- Existing and new behavioral suites execute in Fengari and native Lua 5.1; WoW APIs are mocked.
- Tests cover step transitions, wrong class/race/faction, prerequisites, bounded catch-up, malformed inputs, manual undo, unavailable navigation, high-level bag upgrades and XP rollover.
- Data-only browser converter unit tests reject unsupported files and preserve objective indexing/coordinate units.
- The actual upstream 870-step Factoruide example converts and parses in the offline harness when the cached research fixture is present. It is not bundled as a universally valid player route.
- ZIP byte/hash checks and TOC checks are recorded in validation-manifest.json / release-audit.json in the output folder.

## What remains unverified
No live-client acceptance was performed. The launch client can change APIs, UI behavior, quest data, maps or item requirements. Native map-point helpers and pasted large edit-box input require live QA.

This is an ordered advice-only route bridge, not Factoruide's simulator or its automation. Group routes, travel path geometry, item-buy conditions and upstream parallel/background execution are not reproduced. Background steps remain visible in order and can require manual acknowledgement.

Published external gear lists remain level-30 references; no complete level-60 BiS or class-unlock certification is claimed. Cached item facts were reviewed October 20; the source index was checked October 30 and still labels the lists level 30. Remaining class/quest/profession gaps are labeled.

## November 4 acceptance
1. Close the game before installing. Copy the planner folder; install bundled QuestieDB only if needed, retaining a newer working copy.
2. Open /rfp. Verify class/spec, scan bags, and check Now before using detail pages in More.
3. Generate/share a single-character Forever guide in Factoruide. Open ROUTE-CONVERTER.html locally, select the .fgguide file and paste the output into /rfp route.
4. Confirm the first quest, race/faction and coordinates. Accept, finish one objective, and turn in a quest; ensure only the correct steps advance.
5. Test Manual next, Undo and Resume. Check a native waypoint; if unavailable, use readable coordinates without assuming a safe path.
6. Check an unequipped bag upgrade, a class quest and a profession milestone. Reload normally and verify progress persists.
7. Record an XP session including travel/recovery. Compare observed results across sessions; do not treat simulated or mocked results as measured leveling speed.
8. Use /rfp doctor and retain any first error. Synthetic UI failure messages in the offline test transcript are deliberate test fixtures, not client observations.
'''
Path('RuinousForeverPlanner/OFFLINE-RELEASE-REPORT.md').write_text(report,encoding='utf8')
print('Built offline release report and launch checklist')
