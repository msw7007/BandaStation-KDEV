# Engine Limits

Generated 2026-05-21. Hard constraints of the BYOND / Dream Daemon runtime and the Master Controller — these are not project conventions, they are limits you cannot edit around. Reference when a task touches performance, timing, or tick budget.

## Tick System

- The world runs at `world.fps = 20` (set in `code/world.dm`). One tick is the scheduling unit for everything.
- The Master Controller (`code/controllers/master.dm`) gives each subsystem a slice of each tick, weighted by `priority`. A subsystem must finish or yield within its slice.
- `TICK_USAGE` is the percentage of the current tick consumed. `Master.current_ticklimit` is the soft cap for the current run.
- Overrunning the tick = "overtime"; the MC throttles and lag accumulates.

## Yielding (the only safe way to do long work)

| Macro | Use inside | Effect | Defined in |
|---|---|---|---|
| `MC_TICK_CHECK` | a subsystem `fire()` | pause the SS, resume next fire | `code/__DEFINES/MC.dm` |
| `CHECK_TICK` | any long loop (init, non-SS proc) | sleep until the next tick | `code/__DEFINES/_tick.dm` |
| `CHECK_TICK_HIGH_PRIORITY` | loop allowed to use more budget | yields at ~95% | `code/__DEFINES/_tick.dm` |

## Threading Model

- DM is **cooperatively single-threaded**. There are no real threads for game code; a proc runs until it returns or sleeps.
- A blocking call freezes everything until it returns (`ai_navigation/processing_hazards.md`).
- Native offload exists only via `rust_g.dll`, `dreamluau.dll`, `librust_utils.dll` and auxtools — not general game code.

## Numeric Limits

- Numbers are 32-bit floats. Integers are exact only up to `16777216` (2^24); beyond that, precision is lost.
- This matters for counters, money totals, IDs, and bitfields near 24 bits.

## Lists & Strings

- Lists are 1-indexed. Large list reads/copies/`in` checks cost real time inside the tick.
- Strings are interned; building strings in a hot loop allocates.
- Associative list lookups are fast; linear `for` scans of big lists are not — yield with `CHECK_TICK`.

## Object Lifecycle

- Creating/deleting atoms is expensive; both run `Initialize()` / `Destroy()` chains.
- Deletion goes through `SSgarbage`; a missed reference forces a slow hard delete (`ai_navigation/runtime_errors.md`).
- Pre-warming pools (e.g. `SSwardrobe`) exists because object creation cost is real.

## Appearance & Rendering

- An `appearance` is immutable and cached/shared — changing an overlay rebuilds appearance.
- Overlay/vis_overlay compositing is deferred to `SSoverlays` / `SSvis_overlays`.
- Heavy per-atom overlay churn is a known cost — see `ai_navigation/visuals_guide.md`.

## Rule Of Thumb

If a task adds per-tick, per-step, or per-atom work across a large population, it is a tick-budget risk → classify as high risk (`ai_navigation/human_checking.md`) and prefer event-driven signals over polling.
