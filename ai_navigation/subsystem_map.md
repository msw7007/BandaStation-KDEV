# Subsystem Map

Generated 2026-05-21. Ownership layer — the single most important file for routing accuracy. Use it to find the **runtime owner** of a system before opening source.

144 subsystems verified against macro declarations in `code/controllers/subsystem/**` and `modular_bandastation/**`. Counts drift — re-verify with the command at the bottom.

## How The MC Works (one paragraph)

`Master` (`code/controllers/master.dm`) initialises subsystems in dependency order (bucketed by `init_stage`, 1–4), then `Loop()` fires each SS every `wait` deciseconds, giving each a slice of the tick proportional to its `priority`. A subsystem's `fire()` may call `MC_TICK_CHECK` to pause and resume next fire. Base class + fields (`init_order`, `wait`, `priority`, `runlevels`, `ss_flags`): `code/controllers/subsystem.dm`. Flags/macros: `code/__DEFINES/MC.dm`, `code/__DEFINES/subsystems.dm`.

## Macro → Type Path

| Macro | Type path base | Global |
|---|---|---|
| `SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/x` | `SSx` |
| `PROCESSING_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/processing/x` | `SSx` |
| `TIMER_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/timer/x` | `SSx` |
| `MOVEMENT_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/movement/x` | `SSx` |
| `FLUID_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/fluids/x` | `SSx` |
| `VERB_MANAGER_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/verb_manager/x` | `SSx` |
| `AI_CONTROLLER_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/ai_controllers/x` | `SSx` |
| `UNPLANNED_CONTROLLER_SUBSYSTEM_DEF(x)` | `/datum/controller/subsystem/unplanned_controllers/x` | `SSx` |

All macros defined in `code/__DEFINES/MC.dm`.

## Atom Lifecycle — `SSatoms`

`SSatoms` (`code/controllers/subsystem/atoms.dm`, `SS_NO_FIRE`) runs `InitializeAtoms()` → `CreateAtoms()` → `InitAtom()` (in `code/game/atom/atoms_initializing_EXPENSIVE.dm`). Each atom's `Initialize(mapload, ...)` returns an `INITIALIZE_HINT_*`; `INITIALIZE_HINT_LATELOAD` defers `LateInitialize()` until after all atoms init. Details: `ai_navigation/runtime_flow.md`.

---

## Category A — Core, `SUBSYSTEM_DEF`

Type path `/datum/controller/subsystem/<name>`; file under `code/controllers/subsystem/`.

| SS | File | Purpose |
|---|---|---|
| `SSair` | `air.dm` | Atmospherics: pipenets, turfs, hotspots |
| `SSachievements` | `achievements.dm` | Achievement / medal DB sync |
| `SSadmin_verbs` | `admin_verbs.dm` | Lazy-loads admin verb panels |
| `SSambience` | `ambience.dm` | Per-player ambient sound scheduling |
| `SSarea_contents` | `area_contents.dm` | Deferred area-contents bookkeeping |
| `SSassets` | `assets.dm` | Browser asset cache |
| `SSasset_loading` | `asset_loading.dm` | Generates spritesheet assets over time |
| `SSatoms` | `atoms.dm` | Atom `Initialize()` / `LateInitialize()` |
| `SSaugury` | `augury.dm` | Death / observation watchers |
| `SSai_controllers` | `ai_controllers.dm` | Registry of basic-mob AI controllers |
| `SSban_cache` | `ban_cache.dm` | Per-player ban data cache |
| `SSblackbox` | `blackbox.dm` | Round telemetry / feedback recording |
| `SScameras` | `cameras.dm` | Camera network registry |
| `SSchat` | `chat.dm` | Batched async chat delivery |
| `SSdbcore` | `dbcore.dm` | MySQL/MariaDB connection + query pool |
| `SSdisease` | `disease.dm` | Disease / virus advancement |
| `SSdiscord` | `discord.dm` | Discord bot link / verification |
| `SSdynamic` | `dynamic/dynamic.dm` | Dynamic game-mode / ruleset engine |
| `SSearly_assets` | `early_assets.dm` | Assets needed before main init |
| `SSeconomy` | `economy.dm` | Station accounts, payroll, price drift |
| `SSevents` | `events.dm` | Random event scheduling |
| `SSexplosions` | `explosions.dm` | Queued explosion processing |
| `SSfluids` | `fluids.dm` | Fluid-spread base subsystem |
| `SSgarbage` | `garbage.dm` | `qdel` queue + hard-delete handling |
| `SSgreyscale_previews` | `greyscale_previews.dm` | Greyscale config preview rendering |
| `SSicon_smooth` | `icon_smooth.dm` | Deferred icon smoothing |
| `SSinit_profiler` | `init_profiler.dm` | Profiles subsystem init cost |
| `SSipintel` | `ipintel.dm` | VPN/proxy IP intelligence lookups |
| `SSjob` | `job.dm` | Job definitions, occupation division |
| `SSlag_switch` | `lag_switch.dm` | Auto/manual anti-lag toggles |
| `SSlibrary` | `library.dm` | Book DB / library catalog |
| `SSlighting` | `lighting.dm` | Lighting object / corner updates |
| `SSlua` | `lua.dm` | Lua scripting (auxtools) |
| `SSmachines` | `machines.dm` | Machinery `process()`, APC power phases |
| `SSmapping` | `mapping.dm` | Z-level / map loading, station map config |
| `SSmap_vote` | `map_vote.dm` | Next-map voting |
| `SSmarket` | `market.dm` | Black / supply market items |
| `SSmaterials` | `materials.dm` | Material datum registry |
| `SSminor_mapping` | `minor_mapping.dm` | Post-init minor map decorations |
| `SSmobs` | `mobs.dm` | Mob `Life()` processing |
| `SSmouse_entered` | `mouse_entered.dm` | Batches mouse-hover events |
| `SSnpcpool` | `npcpool.dm` | Legacy simple-mob automated actions |
| `SSore_generation` | `ore_generation.dm` | Procedural ore vein placement |
| `SSoverlays` | `overlays.dm` | Queued atom overlay compositing |
| `SSpai` | `pai.dm` | pAI card candidate pool |
| `SSparallax` | `parallax.dm` | Parallax background animation |
| `SSpathfinder` | `pathfinder.dm` | JPS pathfinding worker pool |
| `SSpersistence` | `persistence/_persistence.dm` | Cross-round persistence loader/saver |
| `SSpersistent_paintings` | `persistent_paintings.dm` | Cross-round painting persistence |
| `SSping` | `ping.dm` | Client ping measurement |
| `SSpoints_of_interest` | `points_of_interest.dm` | Orbit / jump POI registry |
| `SSpolling` | `polling.dm` | Ghost-role candidate polls |
| `SSprofiler` | `profiler.dm` | World profiler auto-dump |
| `SSqueuelinks` | `queuelinks.dm` | Generic two-party matchmaking queues |
| `SSradiation` | `radiation.dm` | Radiation pulse / insulation |
| `SSradioactive_nebula` | `radioactive_nebula.dm` | Radioactive nebula z-level effect |
| `SSrestaurant` | `restaurant.dm` | Venue / order management |
| `SSsecurity_level` | `security_level.dm` | Station alert level (green/red) |
| `SSserver_maint` | `server_maint.dm` | Periodic server housekeeping |
| `SSshuttle` | `shuttle.dm` | Shuttle movement, emergency shuttle |
| `SSskills` | `skills.dm` | Skill / experience definitions |
| `SSsounds` | `sounds.dm` | Sound channel allocation |
| `SSspatial_grid` | `spatial_gridmap.dm` | Spatial index for fast proximity queries |
| `SSsprite_accessories` (`SSaccessories`) | `sprite_accessories.dm` | Sprite-accessory (hair etc.) registry |
| `SSstatpanels` | `statpanel.dm` | Player stat-panel data feed |
| `SSstickyban` | `stickyban.dm` | Sticky ban enforcement |
| `SSstock_market` | `stock_market.dm` | Stock / share price simulation |
| `SSsun` | `sun.dm` | Solar angle for solar panels |
| `SStgui` | `tgui.dm` | TGUI window / update management |
| `SSthrowing` | `throwing.dm` | In-flight thrown-atom processing |
| `SSticker` | `ticker.dm` | Round lifecycle controller |
| `SStime_track` | `time_track.dm` | Game/real time + DB query stats |
| `SStitle` | `title.dm` | HTML title screen (fork addition) |
| `SStrading_card_game` | `tcgsetup.dm` | TCG card definition setup |
| `SStraitor` | `traitor.dm` | Traitor objective / uplink categories |
| `SStts` | `tts.dm` | Core TTS plumbing (≠ modular `SStts220`) |
| `SStutorials` | `tutorials.dm` | Interactive tutorial instances |
| `SSunplanned_controllers` | `unplanned_controllers.dm` | Base for unplanned AI controller SSs |
| `SSverb_manager` | `verb_manager.dm` | Base: defers verbs out of tick |
| `SSvis_overlays` | `vis_overlays.dm` | Pooled `vis_contents` overlays |
| `SSvote` | `vote.dm` | Generic player voting |
| `SSwardrobe` | `wardrobe.dm` | Pre-warms clothing object stock |
| `SSweather` | `weather.dm` | Weather event lifecycle |
| `SSprocessing` | `processing/processing.dm` | Generic `process()` list base SS |
| `SSmovement` | `movement/movement.dm` | Base movement-loop subsystem |

## Category B — Core, scheduler-class macros

| SS | Macro / type path | File | Purpose |
|---|---|---|---|
| `SSdcs` | `PROCESSING_SUBSYSTEM_DEF` `/processing/dcs` | `dcs.dm` | **Signals / DCS global element host** |
| `SSblood_drying` | `PROCESSING_SUBSYSTEM_DEF` `/processing/blood_drying` | `blood_drying.dm` | Dries blood decals over time |
| `SSmood` | `PROCESSING_SUBSYSTEM_DEF` `/processing/mood` | `moods.dm` | Mob mood processing |
| `SStransport` | `PROCESSING_SUBSYSTEM_DEF` `/processing/transport` | `transport.dm` | Tram / lift transport movement |
| `SSinput` | `VERB_MANAGER_SUBSYSTEM_DEF` `/verb_manager/input` | `input.dm` | Player keyboard input (highest priority) |
| `SSspeech_controller` | `VERB_MANAGER_SUBSYSTEM_DEF` `/verb_manager/speech_controller` | `speech_controller.dm` | Defers speech processing |
| `SSai_idle_controllers` | `AI_CONTROLLER_SUBSYSTEM_DEF` `/ai_controllers/ai_idle_controllers` | `ai_idle_controllers.dm` | Planned idle AI controller ticking |
| `SSidle_unplanned_controllers` | `UNPLANNED_CONTROLLER_SUBSYSTEM_DEF` | `unplanned_ai_idle_controllers.dm` | Unplanned idle AI controllers |
| `SSrunechat` | `TIMER_SUBSYSTEM_DEF` `/timer/runechat` | `runechat.dm` | Floating runechat message timers |
| `SSsound_loops` | `TIMER_SUBSYSTEM_DEF` `/timer/sound_loops` | `sound_loops.dm` | Looping sound timers |
| `SSsmoke` | `FLUID_SUBSYSTEM_DEF` `/fluids/smoke` | `fluids.dm` | Smoke cloud spread |
| `SSfoam` | `FLUID_SUBSYSTEM_DEF` `/fluids/foam` | `fluids.dm` | Foam spread |
| `SStimer` | `SUBSYSTEM_DEF` (in dir) | `timer.dm` | `addtimer()` bucketed timer engine |

## Category C — `code/controllers/subsystem/processing/`

`PROCESSING_SUBSYSTEM_DEF` → `/datum/controller/subsystem/processing/<name>` unless noted.

| SS | File (`processing/`) | Purpose |
|---|---|---|
| `SSprojectiles` | `projectiles.dm` | **Bullet / projectile flight** |
| `SSreagents` | `reagents.dm` | Reagent reaction processing |
| `SSacid` | `acid.dm` | Acid damage-over-time |
| `SSantag_hud` | `antag_hud.dm` | Antag HUD refresh |
| `SSaura` | `aura.dm` | Aura effects processing |
| `SSbasic_avoidance` | `ai_basic_avoidance.dm` | Basic-mob avoidance recalculation |
| `SSai_behaviors` | `ai_behaviors.dm` | Active (planned) AI behavior execution |
| `SSidle_ai_behaviors` | `ai_idle_behaviors.dm` | Idle AI behavior execution |
| `SSburning` | `fire_burning.dm` | On-fire damage processing |
| `SSclock_component` | `clock_component.dm` | Circuit clock components |
| `SSconveyors` | `conveyors.dm` (`MOVEMENT_SUBSYSTEM_DEF`) | Conveyor belt movement |
| `SSdigital_clock` | `digital_clock.dm` | Digital wall-clock displays |
| `SSfastprocess` | `fastprocess.dm` | High-frequency (2-tick) `process()` |
| `SSfishing` | `fishing.dm` | Fishing minigame processing |
| `SSgreyscale` | `greyscale.dm` | Greyscale icon generation |
| `SSinstruments` | `instruments.dm` | Musical instrument playback |
| `SSmanufacturing` | `manufacturing.dm` | Manufacturing / autolathe queues |
| `SSnewplayer_info` | `newplayer.dm` | New-player lobby info refresh |
| `SSobj` | `obj.dm` | Generic obj `process()` |
| `SSpersonalities` | `personality.dm` | Personality (quirk-mood) processing |
| `SSplumbing` | `plumbing.dm` | Plumbing fluid network |
| `SSpriority_effects` | `priority_effects.dm` | Priority status effect processing |
| `SSquirks` | `quirks.dm` | Quirk definitions + assignment |
| `SSsinguloprocess` | `singulo.dm` | Singularity movement / effects |
| `SSstation` | `station.dm` | Station traits, announcer |
| `SSsupermatter_cascade` | `supermatter_cascade.dm` | Supermatter cascade end-state |
| `SSturrets` | `turrets.dm` | Turret targeting / firing |
| `SSwet_floors` | `wet_floors.dm` | Wet floor drying |

## Category D — `code/controllers/subsystem/movement/`

`MOVEMENT_SUBSYSTEM_DEF` → `/datum/controller/subsystem/movement/<name>` unless noted.

| SS | File (`movement/`) | Purpose |
|---|---|---|
| `SSmovement` | `movement.dm` (`SUBSYSTEM_DEF`) | Base movement-loop subsystem |
| `SSai_movement` | `ai_movement.dm` | AI-controller mob movement loops |
| `SScliff_falling` | `cliff_falling.dm` | Falling-off-cliff movement |
| `SShyperspace_drift` | `hyperspace_drift.dm` | Hyperspace shuttle parallax drift |
| `SSnewtonian_movement` | `newtonian_movement.dm` | Inertia / space drift movement |

## Category E — `code/controllers/subsystem/networks/`

`SUBSYSTEM_DEF` → `/datum/controller/subsystem/<name>`.

| SS | File (`networks/`) | Purpose |
|---|---|---|
| `SScircuit_component` | `circuit_component.dm` | Integrated-circuit component registry |
| `SSid_access` | `id_access.dm` | ID card access / job trim singletons |
| `SSbitrunning` | `bitrunning.dm` | Bitrunning VR domain management |
| `SSresearch` | `research.dm` | R&D tech tree / techweb |
| `SSmodular_computers` | `modular_computers.dm` | NTNet modular computer / file network |
| `SSwiremod_composite` | `wiremod_composite.dm` | Composite (wiremod) circuit templates |
| `SSradio` | `radio.dm` | Radio frequency / channel registry |

## Category F — Modular (`modular_bandastation/**`)

Fork-added subsystems. See `ai_navigation/modular_guide.md`.

| SS | Type path | File | Purpose |
|---|---|---|---|
| `SSmodpacks` | `/subsystem/modpacks` | `modular_bandastation/_modpacks.dm` | Loads/registers modpacks; `INITSTAGE_FIRST`, `SS_NO_FIRE` |
| `SSautomatic_transfer` | `/subsystem/automatic_transfer` | `modular_bandastation/automatic_crew_transfer/code/automatic_transfer_subsystem.dm` | Auto crew-transfer vote scheduler |
| `SSautomapper` | `/subsystem/automapper` | `modular_bandastation/automapper/code/automapper_subsystem.dm` | Modular map-template injection at world load |
| `SSarea_spawn` | `/subsystem/area_spawn` | `modular_bandastation/automapper/code/area_spawn_subsystem.dm` | Area-based item spawning |
| `SScentral` | `/subsystem/central` | `modular_bandastation/metaserver/code/ss_central.dm` | Metaserver ("SS Central") integration |
| `SStts220` | `/subsystem/tts220` | `modular_bandastation/tts/code/tts_subsystem.dm` | BandaStation TTS engine (≠ core `SStts`) |
| `SShttp` | `/subsystem/http` | `modular_bandastation/tts/code/SSHttp.dm` | Async HTTP request pump |

## Verify (rebuild the list)

```
rg -n "(SUBSYSTEM_DEF|PROCESSING_SUBSYSTEM_DEF|TIMER_SUBSYSTEM_DEF|MOVEMENT_SUBSYSTEM_DEF|FLUID_SUBSYSTEM_DEF|VERB_MANAGER_SUBSYSTEM_DEF|AI_CONTROLLER_SUBSYSTEM_DEF|UNPLANNED_CONTROLLER_SUBSYSTEM_DEF)\(" code/controllers/subsystem modular_bandastation -g "*.dm"
```

If a lookup here fails or looks stale, do not assume the SS is absent — grep the source directly and flag the gap (`ai_navigation/update_policy.md`).
