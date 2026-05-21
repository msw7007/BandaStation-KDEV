# Debug Routes

Generated 2026-05-21. Use this when the user reports a **symptom** rather than a feature name. Match the symptom, open the listed files, escalate per the last column.

## Symptom Table

| Symptom | Open first | Then check | Likely owner |
|---|---|---|---|
| Runtime on world boot / before round | `code/game/world.dm`, `code/controllers/master.dm` | `code/controllers/subsystem/<the SS named in the runtime>.dm` | `Master`, the failing `SS*` |
| Runtime during mapload / `Initialize` / `LateInitialize` | `code/controllers/subsystem/atoms.dm`, `code/game/atom/atoms_initializing_EXPENSIVE.dm` | the atom's `Initialize()`; did it return a hint and call `..()`? | `SSatoms` |
| Atom exists but never set up / `LateInitialize` not running | `code/__DEFINES/subsystems.dm` (`INITIALIZE_HINT_*`) | `Initialize()` return value of that atom type | `SSatoms` |
| TGUI window blank / won't open / not updating | `code/modules/tgui/tgui.dm`, the datum's `ui_interact`/`ui_data` | `tgui/packages/tgui/interfaces/<Name>.tsx`; name must match the DM `interface` string | `SStgui` |
| TGUI action does nothing | the datum's `ui_act()` | `ui_status()` / `ui_state` (is the UI interactive?) | `SStgui` |
| Combat: hit does nothing / wrong damage | `code/_onclick/item_attack.dm`, `ai_navigation/combat_signal_map.md` | `code/modules/mob/living/damage_procs.dm`, armor/`attack_modifiers` | mob paths, `SSdcs` |
| Combat: projectile misses / no impact | `code/modules/projectiles/projectile.dm` | `bullet_act` on the target, `code/modules/projectiles/gun.dm` | `SSprojectiles` |
| Movement: can't move / wrong collisions | `code/game/atoms_movable.dm` (`Move`, `Bump`) | `CanPass` / `Cross` on the turf or blocker, `ai_navigation/movement_signal_map.md` | `SSmovement` |
| Movement: pull / buckle / throw broken | `code/game/atoms_movable.dm`, `code/game/objects/buckling.dm` | `code/datums/move_manager.dm`, `code/controllers/subsystem/movement/**` | `SSmovement`, `SSthrowing` |
| Job / role: wrong slots, no spawn, bad loadout | `code/modules/jobs/**`, `code/datums/outfit.dm` | `modular_bandastation/{jobs,ru_jobs,job_restrictions,outfits}`, `SSticker.setup()` | `SSjob`, `SSticker` |
| Roundstart antag wrong / not assigned | `code/controllers/subsystem/dynamic/dynamic.dm` | `dynamic_ruleset_roundstart.dm`, `modular_bandastation/{dynamic,antagonists}` | `SSdynamic` |
| Spell / action / ability misbehaving | `code/datums/actions/action.dm`, `code/modules/spells/spell.dm` | `code/datums/status_effects/**`, `ai_navigation/spell_signal_map.md` | self-managed cooldowns |
| Whole subsystem / process loop freezes, no runtime | `ai_navigation/processing_hazards.md` | the SS `fire()` and any `process()` for blocking calls | the frozen `SS*` |
| `qdel` / hard delete / ref leak / GC spam | `ai_navigation/runtime_errors.md`, `code/controllers/subsystem/garbage.dm` | the type's `Destroy()` — does it `..()` and clear refs? | `SSgarbage` |
| Signal handler not firing | `code/datums/signals.dm`, `ai_navigation/signal_map.md` | is the signal `SEND_SIGNAL`-ed? is `RegisterSignal` on the right target? `SIGNAL_HANDLER` present? | `SSdcs` |
| Map: object missing / wrong place / mapgen | `code/modules/mapping/**`, `_maps/**` | `code/datums/mapgen/**`, `modular_bandastation/automapper` | `SSmapping`, `SSautomapper` |
| Persistence: save/load wrong across rounds | `code/controllers/subsystem/persistence/_persistence.dm` | the feature's persistence read/write procs | `SSpersistence` |
| Server lag / tick budget exceeded | `ai_navigation/engine_limits.md`, `ai_navigation/processing_hazards.md` | the SS profiler / `SSinit_profiler` output | `Master`, the heavy `SS*` |
| Behaviour differs from upstream TG | `modular_bandastation/**` for an override of the type | `modular_bandastation/overrides`, `ai_navigation/modular_guide.md` | the overriding modpack |
| Sound / TTS not playing | `code/controllers/subsystem/sounds.dm` | `modular_bandastation/tts/**`, `SStts220` / `SShttp` | `SSsounds`, `SStts220` |

## Escalation

- Owner found, break mode unclear → `ai_navigation/failure_modes.md`.
- Need execution order → `ai_navigation/runtime_flow.md`.
- Crosses systems → `ai_navigation/system_dependencies.md`.
- Reading a runtime error line → `ai_navigation/runtime_errors.md`.

## Always

Reproduce the symptom against source before trusting a route here. If a route leads nowhere, grep `code/` and `modular_bandastation/` directly and flag the navigation gap (`ai_navigation/update_policy.md`).
