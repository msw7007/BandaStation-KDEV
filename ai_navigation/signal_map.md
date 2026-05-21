# Signal Map

Generated 2026-05-21. Routing doc for the DCS (Dynamic Component System) — signals, components, elements. Use it when behaviour is indirect, event-driven, or "something reacts but I can't find the caller".

This is **not** an exhaustive signal list (~2950 `COMSIG_*` defines exist). It tells you where signals live and how to find the specific one.

## Where Things Live

| Item | Location |
|---|---|
| `COMSIG_*` defines | `code/__DEFINES/dcs/**` (subdirs `signals_atom/`, `signals_mob/`, ...) + `code/__DEFINES/dcs/declarations.dm` |
| Fork signal defines | `modular_bandastation/_signals220/code/**` |
| `SEND_SIGNAL`, `SEND_GLOBAL_SIGNAL`, `SIGNAL_HANDLER`, `AddComponent`, `AddElement` macros | `code/__DEFINES/dcs/helpers.dm` |
| `RegisterSignal`, `RegisterSignals`, `UnregisterSignal` (procs) | `code/datums/signals.dm` |
| `SSdcs` (global signal host, element registry) | `code/controllers/subsystem/dcs.dm` |
| `/datum/component` base | `code/datums/components/_component.dm` |
| `/datum/element` base | `code/datums/elements/_element.dm` |
| Component implementations | `code/datums/components/**`, `modular_bandastation/~components/**` |
| Element implementations | `code/datums/elements/**` |

## How It Works

- `RegisterSignal(target, COMSIG_X, PROC_REF(handler))` subscribes; the handler must be marked `SIGNAL_HANDLER` and must not sleep.
- `SEND_SIGNAL(target, COMSIG_X, args...)` emits to that target's subscribers; `SEND_GLOBAL_SIGNAL` = `SEND_SIGNAL(SSdcs, ...)`.
- Handlers return a bitfield; some signals use the return to veto/modify the caller.
- A **component** is per-instance state attached to one datum. An **element** is stateless behaviour shared by argument hash. `SSdcs` hosts shared elements.

## Usage Scale (`code` + `modular_bandastation`, `.dm`)

| Pattern | Count (approx) |
|---|---|
| `RegisterSignal(` | ~6680 |
| `RegisterSignals(` | ~310 |
| `SEND_SIGNAL(` | ~1490 |
| `AddComponent` | ~1740 |
| `AddElement` | ~1890 |

## Major Signal Families (by prefix)

| Prefix | Domain | Focused map |
|---|---|---|
| `COMSIG_ATOM_*` | any atom (init, examine, entered/exited) | — |
| `COMSIG_MOVABLE_*` | movement, pre-move, moved, z-change | `ai_navigation/movement_signal_map.md` |
| `COMSIG_MOB_*`, `COMSIG_LIVING_*`, `COMSIG_CARBON_*`, `COMSIG_HUMAN_*` | mob lifecycle, damage, life | `ai_navigation/combat_signal_map.md` |
| `COMSIG_ITEM_*`, `COMSIG_OBJ_*` | item interaction, equipment | `ai_navigation/combat_signal_map.md` |
| `COMSIG_*_moveloop_*` (`signals_moveloop.dm`) | move loops | `ai_navigation/movement_signal_map.md` |
| `COMSIG_GLOB_*` | global events (sent on `SSdcs`) | — |
| `COMSIG_QDELETING` | datum about to be deleted | `ai_navigation/runtime_errors.md` |

## Find A Specific Signal

```
# the define
rg -n "#define COMSIG_MOB_APPLY_DAMAGE" code/__DEFINES/dcs modular_bandastation -g "*.dm"
# who emits it
rg -n "SEND_SIGNAL\([^,]+, ?COMSIG_MOB_APPLY_DAMAGE" code modular_bandastation -g "*.dm"
# who listens
rg -n "RegisterSignal\(.*COMSIG_MOB_APPLY_DAMAGE" code modular_bandastation -g "*.dm"
```

## Routing

- If a signal is defined but nothing `SEND_SIGNAL`s it, the behaviour it implies does not happen — verify the sender exists.
- If a handler does not fire, check: signal emitted? `RegisterSignal` on the correct target datum? handler marked `SIGNAL_HANDLER`? See `ai_navigation/failure_modes.md`.
- Implementing a component/element → `ai_navigation/coding_standards.md` (component vs element choice).
