# Ruinous Forever Planner

A gear-aware progression planner for WoW Forever, built for the Ruinous guild.

**Current version: 0.22.0 - offline-tested launch candidate.** Live-client acceptance of this version is pending. Prior guild testing does not certify the newer features.

## What it does

- Provides a **Now** view with current-character next actions and a movable objective tracker.
- Scans equipped and carried gear, estimates weighted-stat upgrades, and displays a partial optimization rating.
- Connects leveling priorities, class quest chains, professions and dungeon-versus-grinding decisions.
- Imports ordered single-character Factoruide `.fgguide` routes through a local data-only converter.
- Advances supported imported quest steps from observed acceptance, objective and completion state.
- Records vendor observations and compares sell options using transparent manual market estimates.
- Measures actual session XP separately from the grinding baseline.

## Install

1. Close WoW.
2. Copy the **RuinousForeverPlanner** folder into your Forever client's `Interface/AddOns` directory.
3. Enable the addon and a compatible **QuestieDB** installation for the full installed quest catalogue.
4. Open `/rfp`, verify your character profile, and scan gear.

Read the [usage guide](RuinousForeverPlanner/USAGE_GUIDE.md) or open [START-HERE.html](RuinousForeverPlanner/START-HERE.html) locally. Route imports use [ROUTE-CONVERTER.html](RuinousForeverPlanner/ROUTE-CONVERTER.html). The [offline release report](RuinousForeverPlanner/OFFLINE-RELEASE-REPORT.md) includes launch acceptance checks.

## Important limits

External BiS references concentrate on level 30; complete level-60 BiS and all-class unlock mappings are not bundled. Ratings are partial stat estimates, not combat simulations. Imported routes preserve ordered advice, not Factoruide's simulator, pathfinding or automation. Unavailable data remains explicit. The addon does not automatically move, equip, accept quests, sell or disenchant items.

## Development

The addon targets the reviewed Forever interface `16001` and Lua 5.1. Runtime guards do not establish compatibility with an untested client build.

```sh
cd tools
npm install
cd ..
node tools/test.js
```

For the independent native Lua suite, install `tools/requirements-dev.txt` into your Python environment, then run `python tools/test_lua51.py`.

Generated addon data and structured research inputs are included. Local dependency folders, cached web pages, original private document inputs, installation backups and large third-party archives are excluded. The complete document/release pipeline additionally requires those local inputs and the matching QuestieDB source/runtime described in `third_party/manifest.json`.

## Sources and third-party projects

See [SOURCES.md](RuinousForeverPlanner/SOURCES.md) and the upstream notices in [third_party](third_party). QuestieDB and Factoruide are independent projects; their names, data and code retain their respective ownership and licensing. This repository is not an official Blizzard product.
