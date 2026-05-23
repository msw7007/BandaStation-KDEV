# Architecture

Generated 2026-05-21 for `BandaStation-Kagelite_DEV`. Orientation layer — read this when the architecture, build composition, or "which layer owns this" is unclear.

`ai_navigation/` is a routing aid, not a source of truth (see `ai_navigation/AGENTS.md`). Verify every path against the live tree before concluding or editing.

## Project File

| Item | Value |
|---|---|
| Active project file | `tgstation.dme` (repo root) — build this only |
| First include (must stay first) | `code/genesis_call.dme` (`tgstation.dme:6`) |
| Last include (modular overlay) | `modular_bandastation/modular_bandastation.dme` (`tgstation.dme:6961`, manually appended after `// END_INCLUDE`) |
| Lint shim | `__odlint.dm` (`tgstation.dme:21`; OpenDream-only `#pragma` lints) |
| Static analysis config | `SpacemanDMM.toml` (`environment = "tgstation.dme"`) |

Other `.dme` files exist (`modular_bandastation/**/_*.dme`, `tools/**/*.dme`) — those are module sub-manifests and standalone tools, **not** the project root.

## Codebase Family

- Engine: BYOND / Dream Maker (DM language).
- Lineage: tgstation-derived ("TG codebase"). This repo is the **BandaStation** fork (ss220club), a "Kagelite" variant. Russian-localized strings throughout.
- Present: Master Controller + subsystem scheduler, DCS signals / components / elements, TGUI (React) frontend, a late-included modular overlay, full GitHub CI.

## Composition Model

Two layers compiled into one server binary:

| Layer | Path | Role |
|---|---|---|
| Core | `code/**` | Upstream TG code plus in-place fork edits |
| Modular overlay | `modular_bandastation/**` | Fork features packaged as "modpacks"; included LAST so it can override core |

The overlay model is detailed in `ai_navigation/modular_guide.md`.

## Include Order (invariants)

`tgstation.dme` is a generated include manifest (~6961 lines). Do **not** hand-edit include lines without explicit approval (`ai_navigation/human_checking.md`). Stable invariants:

1. `code/genesis_call.dme` is the FIRST include — guarantees earliest-executing code. Never let another `#include` precede it.
2. `__odlint.dm`, `_maps/_basemap.dm`, byond-compat, `_compile_options.dm`, `_experiments.dm`, `code/world.dm` follow.
3. `code/__DEFINES/**` — compile-time defines (must precede code that uses them).
4. Core `code/**` — controllers, datums, game, modules, `_onclick`, etc.
5. `interface/**` — BYOND skin (`tgstation.dme:6949-6957`), then `// END_INCLUDE` at line 6958.
6. `modular_bandastation/modular_bandastation.dme` is the LAST include.

## Runtime Backbone

| Stage | Owner | File |
|---|---|---|
| `/world` datum | `/world` | `code/world.dm` (vars only) |
| World boot + reboot | `/world/New()`, `/world/proc/Genesis()`, `/world/Reboot()` | `code/game/world.dm` |
| Master Controller | `Master` (`/datum/controller/master`) | `code/controllers/master.dm` |
| Subsystem base | `/datum/controller/subsystem` | `code/controllers/subsystem.dm` |
| MC / tick macros | `MC_TICK_CHECK`, `CHECK_TICK` | `code/__DEFINES/MC.dm`, `code/__DEFINES/_tick.dm` |
| Atom init | `SSatoms` | `code/controllers/subsystem/atoms.dm` |
| Round lifecycle | `SSticker` | `code/controllers/subsystem/ticker.dm` |
| Game-mode engine | `SSdynamic` | `code/controllers/subsystem/dynamic/dynamic.dm` |
| GC / hard-delete | `SSgarbage` | `code/controllers/subsystem/garbage.dm` |
| Signals / DCS host | `SSdcs` | `code/controllers/subsystem/dcs.dm` |

Full boot→round→teardown lifecycle: `ai_navigation/runtime_flow.md`. All 144 subsystems: `ai_navigation/subsystem_map.md`.

## Domain Layers (core `code/`)

| Layer | Path | What lives here |
|---|---|---|
| Defines | `code/__DEFINES/**` | `#define`s, macros, signal names, flags, `dcs/` signal defines |
| Helpers | `code/__HELPERS/**` | global helper procs |
| Controllers | `code/controllers/**` | Master + every subsystem |
| Datums | `code/datums/**` | components, elements, actions, status effects, wounds, AI, materials, storage |
| Game | `code/game/**` | atoms, objects, items, turfs, areas, machinery |
| Modules | `code/modules/**` | mobs, jobs, reagents, surgery, projectiles, spells, tgui, admin, antagonists, ... |
| Click / combat | `code/_onclick/**` | click + attack pipeline, HUD screen objects |

## Frontend & External Integration

| Concern | Path | Notes |
|---|---|---|
| In-game UI (TGUI) | `tgui/**` (React/TS, Bun + rspack) | `ai_navigation/tgui_guide.md` |
| BYOND skin | `interface/skin.dmf`, `interface/*.dm` | native client window chrome |
| Browser assets | `html/**`; built bundles → `tgui/public/**` | |
| Database | `SQL/**`, `SSdbcore` (`code/controllers/subsystem/dbcore.dm`) | MySQL/MariaDB |
| Config | `config/**` | runtime server configuration |
| Maps | `_maps/**` | `.dmm` map files + map JSON configs (NOT this navigation layer) |
| Tooling / CI | `tools/**`, `.github/workflows/**` | `ai_navigation/coding_standards.md` |

## Source Of Truth

`code/**` and `modular_bandastation/**` are authoritative. If this navigation layer disagrees with the code, trust the code and flag the gap (`ai_navigation/update_policy.md` → Navigation Miss Protocol).
