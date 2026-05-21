# Runtime Flow

Generated 2026-05-21. Use this when the question is about **order of execution / lifecycle**, not just file location. Line numbers drift — treat them as hints.

## 1. World Boot → MC Init

**Chain:** `/world/proc/Genesis()` (`code/game/world.dm`) — pre-MC init (tracy, debugger, logger), then `Master = new` → `/world/New()` → `InitTgs()` → `config.Load()` → `ConfigLoaded()` (`SSdbcore.InitializeRound()`, logs, admins) → `Master.Initialize()` (`code/controllers/master.dm`).
**Then:** `Master.Initialize()` builds a dependency graph from each SS's `dependencies`, topologically sorts, buckets by `init_stage` (1–4), and calls `subsystem.Initialize()` per stage. Earlier stages may fire while later stages still init.
**Open first:** `code/game/world.dm`, `code/controllers/master.dm`.
**Key facts:** `code/world.dm` holds only the `/world` datum vars. `genesis_call.dme` runs before everything. `SSdbcore` initialises in `ConfigLoaded()` *before* the MC.

## 2. Atom Initialization

**Chain:** `SSatoms/Initialize()` → `InitializeAtoms()` → `CreateAtoms()` → `InitAtom()` → `atom.Initialize(mapload, ...)` → (return hint) → `LateInitialize()`.
**Runtime owner:** `SSatoms` (`code/controllers/subsystem/atoms.dm`, `SS_NO_FIRE`).
**Open first:** `code/controllers/subsystem/atoms.dm`, `code/game/atom/atoms_initializing_EXPENSIVE.dm`.
**Key facts:**
- `Initialize()` must return an `INITIALIZE_HINT_*` (`code/__DEFINES/subsystems.dm`). `INITIALIZE_HINT_LATELOAD` defers `LateInitialize()` until after every atom has initialised; `INITIALIZE_HINT_QDEL` deletes the atom.
- The `mapload` argument is `TRUE` during SSatoms init and map-template loading, `FALSE` for atoms created at runtime.
- Atoms created before `SSatoms` finishes are initialised immediately by `/atom/New()`.

## 3. Round Lifecycle

**Chain:** `SSticker` state machine: `GAME_STATE_STARTUP` → `PREGAME` (lobby countdown) → `SETTING_UP` → `PLAYING` → `FINISHED` (reboot countdown).
**Setup:** `SSticker/setup()` → `SSdynamic.select_roundstart_antagonists()` → `SSjob.divide_occupations()` → `create_characters()` / `equip_characters()` / `transfer_characters()` → `PostSetup()` (runs queued `SSdynamic` rulesets).
**Runtime owners:** `SSticker` (`code/controllers/subsystem/ticker.dm`), `SSdynamic` (`code/controllers/subsystem/dynamic/dynamic.dm`), `SSjob` (`code/controllers/subsystem/job.dm`).
**Key facts:** runlevel transitions (`RUNLEVEL_LOBBY/SETUP/GAME/POSTGAME`) gate which subsystems fire. `SSdynamic` (`SS_NO_INIT`, `wait = 5 MINUTES`) drives midround / latejoin rulesets after roundstart.

## 4. Player Connect → Spawn

**Chain:** `/client/New()` (`code/modules/client/client_procs.dm`) — build/ban/IP checks, preferences load, `COMSIG_GLOB_CLIENT_CONNECT` → connecting mob is `/mob/dead/new_player` → lobby (`code/modules/mob/dead/new_player/**`, `SSnewplayer_info`) → job join → character created/equipped → `/mob/Login()` (`code/modules/mob/login.dm`).
**Runtime owners:** `SSdbcore` (preferences/DB), `SSjob` (slot assignment), `SSticker` (roundstart spawn).
**Open first:** `code/modules/client/client_procs.dm`, `code/modules/mob/dead/new_player/**`, `code/modules/mob/login.dm`.

## 5. Latejoin

**Chain:** player in lobby picks a job mid-round → `SSjob` checks slot availability → spawn at arrivals → `SSdynamic` may apply a latejoin ruleset.
**Runtime owners:** `SSjob`, `SSdynamic`.
**Open first:** `code/modules/jobs/**`, `code/modules/mob/dead/new_player/**`, `code/controllers/subsystem/dynamic/dynamic_ruleset_latejoin.dm`.

## 6. qdel / Garbage Collection

**Chain:** `qdel(thing)` → `thing.Destroy(force)` → returns a `QDEL_HINT_*` → `SSgarbage` queues the ref → if still referenced after the GC delay, hard delete (`del`).
**Runtime owner:** `SSgarbage` (`code/controllers/subsystem/garbage.dm`).
**Open first:** `code/controllers/subsystem/garbage.dm`, `code/__DEFINES/qdel.dm`, `ai_navigation/runtime_errors.md`.
**Key facts:** `Destroy()` must call `..()` and null out references / unregister signals or the object hard-deletes. Reference-tracking diagnostics (`QDEL_HINT_FINDREFERENCE`) only compile under `#ifdef REFERENCE_TRACKING`.

## 7. Reboot

**Chain:** `/world/Reboot()` (`code/game/world.dm`) → `Master.Shutdown()` → `check_hard_reboot()` → `shutdown_logging()` → `TgsReboot()`.
**Open first:** `code/game/world.dm`.

## Escalation

- Cross-system handoffs → `ai_navigation/system_dependencies.md`.
- A subsystem stalls during a flow → `ai_navigation/processing_hazards.md`, then `ai_navigation/failure_modes.md`.
- Subsystem ownership / file → `ai_navigation/subsystem_map.md`.
