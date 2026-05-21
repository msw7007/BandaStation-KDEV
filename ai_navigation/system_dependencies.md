# System Dependencies

Generated 2026-05-21. Use this when a change crosses system boundaries — it shows which owners to inspect together so you don't fix one side and break the other.

## Cross-System Flows

| Flow | Hands off / depends on | Runtime owners | Primary paths |
|---|---|---|---|
| Round setup | `SSticker` → `SSdynamic` (antag pick) → `SSjob` (occupations) → character create/equip | `SSticker`, `SSdynamic`, `SSjob` | `code/controllers/subsystem/{ticker,dynamic/dynamic,job}.dm` |
| Map load → atom init | `SSmapping` loads z-levels/templates → `SSatoms` initialises atoms → `SSminor_mapping` decorates | `SSmapping`, `SSatoms`, `SSminor_mapping`, `SSautomapper` | `code/controllers/subsystem/{mapping,atoms,minor_mapping}.dm`, `modular_bandastation/automapper` |
| Player join | `/client/New` → preferences via `SSdbcore` → `/mob/dead/new_player` lobby → `SSjob` slot → mob → `Login()` | `SSdbcore`, `SSjob`, `SSticker` | `code/modules/client/**`, `code/modules/mob/dead/new_player/**`, `code/modules/mob/login.dm` |
| Job spawn | `SSjob` → `/datum/outfit` → item equip → mob HUD/actions | `SSjob` | `code/modules/jobs/**`, `code/datums/outfit.dm`, `modular_bandastation/{jobs,outfits,loadout}` |
| Melee combat | click → item attack chain → `apply_damage` → wounds/bodyparts → death → round-end check | `SSdcs`, mob paths, `SSticker` | `code/_onclick/item_attack.dm`, `code/modules/mob/living/**`, `code/datums/wounds/**` |
| Projectile combat | gun `process_fire` → `/obj/projectile` flight → `bullet_act` → `apply_damage` | `SSprojectiles` | `code/modules/projectiles/**`, `code/modules/mob/living/damage_procs.dm` |
| AI behaviour | `SSai_controllers` registry → `SSai_behaviors` plans → `SSai_movement` moves → `SSmovement` | `SSai_controllers`, `SSai_behaviors`, `SSai_movement`, `SSmovement` | `code/datums/ai/**`, `code/controllers/subsystem/{ai_behaviors,movement/ai_movement}.dm` |
| Reagents | containers/holders → `SSreagents` reactions → effects on mobs | `SSreagents` | `code/modules/reagents/**` |
| Economy / cargo | `SSeconomy` accounts ↔ cargo orders ↔ `SSshuttle` delivery ↔ `SSmarket` | `SSeconomy`, `SSshuttle`, `SSmarket`, `SSstock_market` | `code/modules/{cargo,economy}/**`, `modular_bandastation/orderables` |
| TGUI | host datum `ui_interact` → `SStgui` window → React interface → `ui_act` back to datum | `SStgui` | `code/modules/tgui/**`, `tgui/packages/tgui/interfaces/**` |
| Cross-round persistence | feature read/write ↔ `SSpersistence` ↔ savefiles / DB (`SSdbcore`) | `SSpersistence`, `SSdbcore` | `code/controllers/subsystem/persistence/_persistence.dm`, `SQL/**` |
| Modpack init | `SSmodpacks` runs every `/datum/modpack` pre/init/post before gameplay subsystems | `SSmodpacks` | `modular_bandastation/_modpacks.dm` |
| Machines / power | `SSmachines` `process()` ↔ power net ↔ `SSair` atmospherics | `SSmachines`, `SSair` | `code/game/machinery/**`, `code/modules/power/**` |

## How To Use

1. Identify the system you are changing.
2. Find its row(s) — note every owner in the `Runtime owners` column.
3. Open the source on **both sides** of the handoff before editing.
4. A change at a handoff point is usually medium/high risk — classify with `ai_navigation/human_checking.md`.

## Escalation

- Execution order within a flow → `ai_navigation/runtime_flow.md`.
- A handoff owner stalls → `ai_navigation/processing_hazards.md`.
- Owner files → `ai_navigation/subsystem_map.md`.
