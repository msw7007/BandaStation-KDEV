# System Map

Generated 2026-05-21. Coarse map of major directories and systems — use it to decide **which area to open first** when the task does not match an `entrypoints.md` keyword row.

For exact runtime owners use `ai_navigation/subsystem_map.md`. For keyword routing use `ai_navigation/entrypoints.md`.

## Repository Top Level

| Path | Contains |
|---|---|
| `code/**` | Core game code (upstream TG + in-place fork edits) |
| `modular_bandastation/**` | Fork overlay — ~91 modpack modules (`ai_navigation/modular_guide.md`) |
| `tgui/**` | React/TypeScript in-game UI (`ai_navigation/tgui_guide.md`) |
| `interface/**` | BYOND client skin (`skin.dmf`) |
| `_maps/**` | `.dmm` map files + map JSON configs |
| `config/**` | Runtime server configuration |
| `SQL/**` | Database schema + migrations |
| `tools/**` | Build pipeline, CI scripts, linters, content generators |
| `.github/workflows/**` | CI definitions (`ai_navigation/coding_standards.md`) |
| `strings/`, `icons/`, `sound/`, `html/` | Localisation strings, sprites, audio, browser assets |
| `lua/` | Lua scripts for `SSlua` |
| `tgstation.dme` | Project root manifest |

## Major Systems

`code` paths are core; `modular` names are folders under `modular_bandastation/`.

| System | Core directories | Modular extension | Runtime owner |
|---|---|---|---|
| Runtime / scheduler | `code/controllers/**` | `_modpacks` | `Master`, all `SS*` |
| Signals / DCS | `code/__DEFINES/dcs/**`, `code/datums/components/**`, `code/datums/elements/**` | `~components`, `_signals220` | `SSdcs` |
| Atoms / objects | `code/game/atom/**`, `code/game/objects/**` | `objects` | `SSatoms` |
| Mobs / living | `code/modules/mob/**` | `mobs`, `species` | `SSmobs` |
| Combat | `code/_onclick/**`, `code/modules/mob/living/**`, `code/modules/projectiles/**` | `weapon`, `martial_arts`, `balance` | `SSprojectiles`, mob paths |
| Movement | `code/game/atoms_movable.dm`, `code/controllers/subsystem/movement/**`, `code/datums/move_manager.dm` | `pixel_shift`, `movespeed_limit` | `SSmovement`, `SSthrowing` |
| Jobs / roles | `code/modules/jobs/**` | `jobs`, `ru_jobs`, `job_restrictions`, `outfits`, `loadout` | `SSjob` |
| Antagonists / mode | `code/modules/antagonists/**`, `code/controllers/subsystem/dynamic/**` | `dynamic`, `antagonists`, `cult_overhaul`, `revolution_overhaul`, `ert` | `SSdynamic`, `SSticker` |
| Events | `code/modules/events/**` | — | `SSevents` |
| Spells / actions | `code/datums/actions/**`, `code/modules/spells/**`, `code/datums/status_effects/**` | `status_effects` | self-managed cooldowns |
| AI / NPC | `code/datums/ai/**`, `code/controllers/subsystem/ai_*` | — | `SSai_behaviors`, `SSai_movement`, `SSai_controllers` |
| Reagents / chem / food | `code/modules/reagents/**`, `code/modules/food_and_drinks/**` | `chemistry`, `food_and_drinks`, `hydroponics` | `SSreagents` |
| Economy / cargo | `code/modules/cargo/**`, `code/modules/economy/**` | `orderables` | `SSeconomy`, `SSmarket`, `SSshuttle` |
| Crafting / materials | `code/datums/components/crafting/**`, `code/datums/materials/**` | `weapon` | `SSmaterials` |
| Medical / surgery | `code/modules/surgery/**`, `code/datums/wounds/**` | `medical` | `SSmobs` (life ticks) |
| Mapping / turfs | `code/modules/mapping/**`, `code/game/turfs/**`, `code/game/area/**`, `code/datums/mapgen/**` | `mapping`, `automapper`, `turfs`, `domains` | `SSmapping`, `SSautomapper` |
| Machines / power | `code/game/machinery/**`, `code/modules/power/**` | — | `SSmachines`, `SSair` |
| UI (TGUI) | `code/modules/tgui/**`, `tgui/packages/tgui/interfaces/**` | `hud`, `nanomap`, `navigator`, panels | `SStgui` |
| Admin / logging | `code/modules/admin/**`, `code/modules/logging/**` | `admin`, `ticket_manager`, `discord` | `SSblackbox`, `SSdiscord` |
| Preferences | `code/modules/client/preferences/**`, `code/datums/quirks/**` | `preferences`, `customization`, `quirks` | `SSpersistence` |
| Rendering / visuals | `code/modules/lighting/**`, `code/__DEFINES/layers.dm` | `aesthetics` | `SSlighting`, `SSoverlays`, `SSvis_overlays` |

## Path Discrepancies (verified — do not assume)

| Expected (TG-style) | Reality in this repo |
|---|---|
| `code/modules/dynamic/` | Does NOT exist — dynamic mode is the subsystem `code/controllers/subsystem/dynamic/` |
| `code/modules/crafting/` | Does NOT exist — crafting is `code/datums/components/crafting/` |
| `code/game/gamemodes/` | Exists but nearly empty (`events.dm`, `objective.dm`, `objective_items.dm`); no classic gamemode tree — this codebase is dynamic-only |

## Dependency Awareness

- After finding a path in `code/`, always check `modular_bandastation/` for an override of the same type — the overlay loads last.
- Several domains (items, spells/actions, surgery, crafting) have **no dedicated subsystem**; they are component/datum-driven and tick via `SSprocessing` or are event-driven.
- Cross-system flows: `ai_navigation/system_dependencies.md`.
