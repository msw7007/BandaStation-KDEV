# Entrypoints

Generated 2026-05-21. Keyword index — match the task to one row, open only the listed paths, escalate only if needed.

## Minimal Route

1. Match the task to one row in the Fast Index.
2. Open the `Open first` path(s). Open `Then check` only if the first is not enough.
3. Always check `modular_bandastation/` for an override (`ai_navigation/modular_guide.md`).
4. Escalate:
   - symptom, not a feature name → `ai_navigation/debug_routes.md`
   - execution order / lifecycle → `ai_navigation/runtime_flow.md`
   - cross-system handoff → `ai_navigation/system_dependencies.md`
   - runtime owner unclear → `ai_navigation/subsystem_map.md`
   - area unclear → `ai_navigation/system_map.md`
   - type path → `ai_navigation/type_index.md`

## Fast Index

| Task or keyword | Open first | Then check | Runtime owner |
|---|---|---|---|
| `job`, `role`, `occupation`, `latejoin`, `outfit`, `loadout` | `code/modules/jobs/**`, `code/datums/outfit.dm` | `modular_bandastation/{jobs,ru_jobs,job_restrictions,outfits,loadout}`, `code/modules/mob/dead/new_player/**` | `SSjob` |
| `mob`, `living`, `carbon`, `human`, `species`, `Life()` | `code/modules/mob/**` | `modular_bandastation/{mobs,species}`, `code/modules/mob/living/**` | `SSmobs` |
| `combat`, `attack`, `melee`, `hit`, `weapon`, `damage` | `code/_onclick/item_attack.dm`, `ai_navigation/combat_signal_map.md` | `code/_onclick/click.dm`, `code/_onclick/other_mobs.dm`, `code/modules/mob/living/damage_procs.dm` | mob/projectile paths, `SSdcs` |
| `projectile`, `bullet`, `gun`, `ranged` | `code/modules/projectiles/projectile.dm`, `code/modules/projectiles/gun.dm` | `code/modules/projectiles/**`, `ai_navigation/combat_signal_map.md` | `SSprojectiles` |
| `movement`, `move`, `Bump`, `pull`, `buckle`, `throw`, `moveloop` | `ai_navigation/movement_signal_map.md`, `code/game/atoms_movable.dm` | `code/game/objects/buckling.dm`, `code/datums/move_manager.dm`, `code/controllers/subsystem/movement/**` | `SSmovement`, `SSthrowing` |
| `spell`, `ability`, `action`, `cooldown`, `magic` | `code/datums/actions/action.dm`, `code/modules/spells/spell.dm` | `code/datums/actions/{cooldown_action,innate_action,item_action}.dm`, `code/modules/spells/spell_types/**`, `ai_navigation/spell_signal_map.md` | self-managed; `SSprocessing` for ticks |
| `status effect`, `buff`, `debuff` | `code/datums/status_effects/**` | `modular_bandastation/status_effects`, `code/controllers/subsystem/processing/priority_effects.dm` | `SSprocessing`, `SSpriority_effects` |
| `ai`, `npc`, `basic mob`, `controller`, `behavior` | `code/datums/ai/**` | `code/controllers/subsystem/{ai_behaviors,ai_idle_behaviors,ai_controllers,movement/ai_movement}.dm` | `SSai_behaviors`, `SSai_movement`, `SSai_controllers` |
| `item`, `obj`, `storage`, `clothing`, `tool` | `code/game/objects/items/**`, `code/datums/storage/**` | `code/modules/clothing/**`, `modular_bandastation/{objects,customization,weapon}` | none dedicated |
| `antag`, `traitor`, `objective`, `uplink` | `code/modules/antagonists/**` | `code/controllers/subsystem/traitor.dm`, `modular_bandastation/antagonists` | `SSdynamic`, `SStraitor` |
| `dynamic`, `game mode`, `ruleset`, `roundstart antag` | `code/controllers/subsystem/dynamic/dynamic.dm` | `code/controllers/subsystem/dynamic/dynamic_ruleset_*.dm`, `modular_bandastation/dynamic` | `SSdynamic`, `SSticker` |
| `event`, `random event` | `code/modules/events/**` | `code/controllers/subsystem/events.dm` | `SSevents` |
| `reagent`, `chemistry`, `reaction`, `holder` | `code/modules/reagents/**` | `modular_bandastation/chemistry`, `code/controllers/subsystem/processing/reagents.dm` | `SSreagents` |
| `food`, `drink`, `cooking`, `recipe`, `hydroponics` | `code/modules/food_and_drinks/**` | `modular_bandastation/{food_and_drinks,hydroponics}`, `code/modules/reagents/**` | `SSrestaurant`, `SSreagents` |
| `economy`, `account`, `payroll`, `cargo`, `bounty`, `market` | `code/modules/cargo/**`, `code/modules/economy/**` | `modular_bandastation/orderables` | `SSeconomy`, `SSmarket`, `SSstock_market` |
| `craft`, `crafting`, `material`, `recipe` | `code/datums/components/crafting/**` | `code/datums/materials/**`, `modular_bandastation/weapon` | `SSmaterials` |
| `surgery`, `wound`, `organ`, `bodypart`, `medical` | `code/modules/surgery/**`, `code/datums/wounds/**` | `modular_bandastation/{medical,species}` | `SSmobs` |
| `quirk`, `preference`, `character setup`, `customization` | `code/modules/client/preferences/**`, `code/datums/quirks/**` | `modular_bandastation/{preferences,customization,quirks,augmentation_preferences}` | `SSpersistence` |
| `map`, `area`, `turf`, `mapgen`, `template`, `ruin` | `code/modules/mapping/**`, `_maps/**` | `code/game/{turfs,area}/**`, `code/datums/mapgen/**`, `modular_bandastation/{mapping,automapper}` | `SSmapping`, `SSautomapper` |
| `machine`, `power`, `apc`, `atmospherics`, `pipe` | `code/game/machinery/**`, `code/modules/power/**`, `code/modules/atmospherics/**` | — | `SSmachines`, `SSair` |
| `tgui`, `ui_interact`, `ui_data`, `ui_act`, `interface` | `ai_navigation/tgui_guide.md`, `code/modules/tgui/**` | `tgui/packages/tgui/interfaces/**` | `SStgui` |
| `hud`, `screen object`, `action button` | `code/_onclick/hud/**` | `modular_bandastation/{hud,gunhud}` | client / mob HUD |
| `admin`, `logging`, `debug`, `ticket` | `code/modules/admin/**`, `code/modules/logging/**` | `modular_bandastation/{admin,ticket_manager,discord}` | `SSblackbox`, `SSdiscord` |
| `overlay`, `plane`, `lighting`, `filter`, `appearance`, `icon smoothing` | `ai_navigation/visuals_guide.md` | `code/modules/lighting/**`, `code/controllers/subsystem/{overlays,vis_overlays,lighting,icon_smooth}.dm` | `SSlighting`, `SSoverlays`, `SSvis_overlays` |
| `signal`, `component`, `element`, `COMSIG`, `RegisterSignal` | `ai_navigation/signal_map.md` | `code/__DEFINES/dcs/**`, `code/datums/{components,elements}/**` | `SSdcs` |
| `subsystem`, `SS*`, `Master`, `tick`, `lag`, `startup` | `ai_navigation/subsystem_map.md` | `code/controllers/master.dm`, `code/controllers/subsystem.dm` | `Master`, target `SS*` |
| `qdel`, `Destroy`, `hard delete`, `ref leak`, `GC` | `ai_navigation/runtime_errors.md` | `code/controllers/subsystem/garbage.dm`, `code/__DEFINES/qdel.dm` | `SSgarbage` |
| `tts`, `text to speech`, `voice` | `modular_bandastation/tts/**` | `code/controllers/subsystem/tts.dm` (core plumbing) | `SStts220`, `SShttp`, `SStts` |
| `modpack`, `modular feature`, `where does fork code go` | `ai_navigation/modular_guide.md` | `modular_bandastation/modular_bandastation.dme` | `SSmodpacks` |
| `CI`, `lint`, `build`, `compile`, `test fails` | `ai_navigation/coding_standards.md` | `.github/workflows/**`, `tools/ci/**` | — |
| BYOND type path `/datum/...`, `/mob/...`, `/obj/...`, `/turf/...` | `ai_navigation/type_index.md` | matching branch in `code/**` and `modular_bandastation/**` | depends on branch |

## Escalation Rules

- If a keyword row matches, do not open `system_map.md` first — go to the listed path.
- If the user gives a symptom rather than a feature, switch to `ai_navigation/debug_routes.md`.
- If the first branch is wrong, switch rows once before a broad repository search.
- If a route returns nothing, search `code/` and `modular_bandastation/` directly and flag the navigation gap (`ai_navigation/update_policy.md`).
