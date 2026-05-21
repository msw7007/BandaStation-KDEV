# Movement Signal Map

Generated 2026-05-21. Movement chain — procs, files, signals. Use it before touching `Move`, collisions, pulling, buckling, throwing, or move loops.

## Canonical Entry Files

| Flow | Open first |
|---|---|
| Movable movement core | `code/game/atoms_movable.dm` |
| Turf pass logic | `code/game/atom/_atom.dm` (`CanPass`), `code/game/turfs/**` |
| Move loops | `code/datums/move_manager.dm`, `code/controllers/subsystem/movement/movement_types.dm` |
| Buckling | `code/game/objects/buckling.dm` |
| Move-force defines | `code/__DEFINES/move_force.dm` |
| Move-loop signals | `code/__DEFINES/dcs/signals/signals_moveloop.dm` |

## Core Movement Procs (`code/game/atoms_movable.dm`)

| Proc | Role |
|---|---|
| `/atom/movable/Move(newloc, dir, ...)` | public move — handles diagonal split, glide, pulled atoms |
| `/atom/movable/Move(...)` (internal) | single cardinal step; fires `COMSIG_MOVABLE_PRE_MOVE` |
| `/atom/movable/proc/Moved(old_loc, dir, forced, ...)` | post-move; fires `COMSIG_MOVABLE_MOVED` |
| `/atom/movable/proc/forceMove(destination)` → `doMove()` | move with no step, no `Bump` |
| `/atom/movable/proc/abstract_move(new_loc)` | move with no side effects |
| `/atom/movable/proc/moveToNullspace()` | move out of the world |
| `/atom/movable/Bump(bumped_atom)` | collision with a dense atom |
| `/atom/movable/Cross` / `Crossed` / `Uncross` / `Uncrossed` | enter/leave a turf shared with another movable |

Turf-level gate: `/atom/proc/CanPass(atom/movable/mover, border_dir)` and `Enter`/`Exit`/`Entered`/`Exited`.

## Key Signals

| Signal | When |
|---|---|
| `COMSIG_MOVABLE_PRE_MOVE` | before a step — listeners can react/veto |
| `COMSIG_MOVABLE_MOVED` | after a successful move (the most-used movement signal) |
| `COMSIG_MOVABLE_BUMP` | on collision |
| move-loop signals | in `code/__DEFINES/dcs/signals/signals_moveloop.dm` |

Confirm exact signal names with `rg` — see commands below.

## Move Loops

Automated/scripted movement does not call `Move` directly — it uses move loops:

| Item | File |
|---|---|
| `GLOB.move_manager` (`/datum/move_manager`), `/datum/movement_packet` | `code/datums/move_manager.dm` |
| `/datum/move_loop` + helpers (`move`, `move_to`, `move_away`, `jps_move`, `force_move`, `freeze`, `move_rand`, `home_onto`, `smooth_move`, ...) | `code/controllers/subsystem/movement/movement_types.dm` |
| Owner subsystem | `SSmovement` (and `SSai_movement` for AI-controlled mobs) |

Use `GLOB.move_manager.<helper>(...)` for scripted movement — do **not** use BYOND `walk()` (`ai_navigation/processing_hazards.md`).

## Pulling / Buckling / Throwing

| Concern | Proc / File |
|---|---|
| Pulling | `start_pulling` / `stop_pulling` / `check_pulling` in `code/game/atoms_movable.dm`; `/mob/living/proc/grab` in `code/modules/mob/living/living_defense.dm` |
| Buckling | `/atom/movable/proc/buckle_mob(mob/living/M, force, ...)` in `code/game/objects/buckling.dm` |
| Throwing | `/atom/movable/proc/throw_at(target, range, speed, thrower, ...)` in `code/game/atoms_movable.dm`; thrown object is a `/datum/thrownthing`; owner `SSthrowing` |

## Cheap Search Order

```
rg -n "/atom/movable/proc/Moved\(|/atom/movable/Move\(" code/game -g "*.dm"
rg -n "COMSIG_MOVABLE_" code/__DEFINES/dcs -g "*.dm"
rg -n "RegisterSignal\(.*COMSIG_MOVABLE_MOVED" code modular_bandastation -g "*.dm"
rg -n "GLOB.move_manager\." code modular_bandastation -g "*.dm"
```

## Routing

- Most "react when something moves" code listens for `COMSIG_MOVABLE_MOVED` — start there.
- Special subsystem-driven movement (`SSnewtonian_movement`, `SScliff_falling`, `SSconveyors`, `SShyperspace_drift`): see `ai_navigation/subsystem_map.md` category D.
