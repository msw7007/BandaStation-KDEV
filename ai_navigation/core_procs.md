# Core Procs

Generated 2026-05-21. Main proc entrypoints to hold in mind **before** a broad source search. File:line anchors drift — use them as hints, confirm with `rg`.

## Lifecycle

| Proc | File | Notes |
|---|---|---|
| `/atom/New(loc, ...)` | `code/game/atom/atoms_initializing_EXPENSIVE.dm` | calls `InitAtom()` if `SSatoms` is past init |
| `/atom/proc/Initialize(mapload, ...)` | `code/game/atom/atoms_initializing_EXPENSIVE.dm` | `SHOULD_CALL_PARENT`, `SHOULD_NOT_SLEEP`; must return `INITIALIZE_HINT_*` |
| `/atom/proc/LateInitialize()` | same | runs after all atoms init, if `Initialize` returned `INITIALIZE_HINT_LATELOAD` |
| `/datum/proc/Destroy(force)` | `code/datums/datum.dm` | base; must call `..()` |
| `/atom/Destroy(force)` | `code/game/atom/_atom.dm` | atom override |
| `qdel(datum, force)` | `code/controllers/subsystem/garbage.dm` | the only correct way to delete |

Use `Initialize()`, never `New()`, for atom setup. See `ai_navigation/runtime_flow.md` §2.

## Interaction

| Proc | File | Triggered by |
|---|---|---|
| `/obj/item/proc/attack_self(mob/user, modifiers)` | `code/_onclick/item_attack.dm` | clicking with item in hand, no target |
| `/atom/proc/attackby(obj/item/attacking_item, mob/user, ...)` | `code/_onclick/item_attack.dm` | hitting an atom with an item |
| `/atom/proc/attack_hand(mob/user, list/modifiers)` | `code/_onclick/other_mobs.dm` | empty-hand click |
| `/atom/proc/base_item_interaction(mob/living/user, obj/item/tool, modifiers)` | `code/game/atom/atom_tool_acts.dm` | non-combat tool use dispatch |
| `/obj/item/proc/interact_with_atom(atom/interacting_with, mob/living/user, modifiers)` | `code/game/atom/atom_tool_acts.dm` | modern item→atom interaction |
| `/datum/proc/ui_interact(mob/user, datum/tgui/ui)` | `code/modules/tgui/external.dm` | opening a TGUI |

## Combat Hooks

Full chain order in `ai_navigation/combat_signal_map.md`. Entrypoints:

| Proc | File |
|---|---|
| `/obj/item/proc/melee_attack_chain(mob/user, atom/target, modifiers, attack_modifiers)` | `code/_onclick/item_attack.dm` |
| `/obj/item/proc/pre_attack(...)`, `/obj/item/proc/attack(mob/living/target, ...)`, `/obj/item/proc/attack_atom(...)` | `code/_onclick/item_attack.dm` |
| `/atom/proc/attacked_by(...)`, `/mob/living/attacked_by(...)` | `code/_onclick/item_attack.dm` |
| `/obj/item/proc/afterattack(...)` | `code/_onclick/item_attack.dm` (`PROTECTED_PROC`) |
| `/mob/living/proc/apply_damage(...)` | `code/modules/mob/living/damage_procs.dm` |
| `/atom/proc/take_damage(...)` | `code/game/atom/atom_defense.dm` (needs `uses_integrity`) |
| `/atom/proc/bullet_act(obj/projectile/...)` | `code/game/atom/atom_act.dm` |

> `attack_modifiers` is threaded through the whole chain alongside `modifiers` — treat it as first-class.

## Movement Hooks

Full detail in `ai_navigation/movement_signal_map.md`. Most live in `code/game/atoms_movable.dm`:

| Proc | Notes |
|---|---|
| `/atom/movable/Move(newloc, dir, ...)` | public move; handles diagonal split + pull |
| `/atom/movable/proc/Moved(old_loc, dir, ...)` | fires `COMSIG_MOVABLE_MOVED` |
| `/atom/movable/proc/forceMove(destination)` | teleport without a step |
| `/atom/movable/Bump(bumped_atom)` | collision |
| `/atom/Crossed` / `Uncrossed` / `CanPass` | turf-level pass logic (`CanPass` in `code/game/atom/_atom.dm`) |
| `/atom/movable/proc/throw_at(...)` | throwing |
| `/atom/movable/proc/start_pulling(...)` | pulling |
| `/atom/movable/proc/buckle_mob(...)` | `code/game/objects/buckling.dm` |

## Timed / Status Hooks

| Proc / call | Owner |
|---|---|
| `/datum/proc/process(seconds_per_tick)` | `SSprocessing` and other processing SSs |
| `addtimer(callback, wait, flags)` | `SStimer` |
| `apply_status_effect(type)` / `/datum/status_effect/proc/tick()` | `code/datums/status_effects/**` |
| `/datum/action/proc/Trigger(...)` | `code/datums/actions/action.dm` |

## Scheduler Hooks

| Proc | Owner |
|---|---|
| `/datum/controller/subsystem/proc/Initialize()` | the MC, at boot |
| `/datum/controller/subsystem/proc/fire(resumed)` | the MC, every `wait` |
| `START_PROCESSING(SS, datum)` / `STOP_PROCESSING(SS, datum)` | adds/removes from a processing SS |

## DCS / Signal Hooks

| Item | File |
|---|---|
| `RegisterSignal(target, sig, PROC_REF(handler))` | `code/datums/signals.dm` (a proc, not a macro) |
| `SEND_SIGNAL(target, sig, args...)` | `code/__DEFINES/dcs/helpers.dm` |
| `SIGNAL_HANDLER` (required on every registered proc) | `code/__DEFINES/dcs/helpers.dm` |
| `AddComponent` / `AddElement` | `code/__DEFINES/dcs/helpers.dm` |

See `ai_navigation/signal_map.md`.

## Fast Search Patterns

```
rg -n "/proc/Initialize\(mapload" code modular_bandastation -g "*.dm"
rg -n "^\s*attackby\(|/proc/attackby\(" code -g "*.dm"
rg -n "/proc/melee_attack_chain\(" code -g "*.dm"
rg -n "RegisterSignal\(.*COMSIG_MOVABLE_MOVED" code modular_bandastation -g "*.dm"
rg -n "/datum/controller/subsystem/.*/fire\(" code/controllers -g "*.dm"
```

## Rule Of Thumb

Find the proc family first, then the specific override. A behaviour change is usually in a subtype's override or a registered signal handler — not the base proc.
