# Processing Hazards

Generated 2026-05-21. Use this when a **process / fire / tick hot path** stalls, lags, or freezes — especially when a whole loop or subsystem stops with no runtime error.

## Use This Helper When

- A subsystem's `fire()` or a `/datum/proc/process()` seems to stop running.
- Server lag spikes without an obvious heavy operation.
- A loop "never finishes" or a feature silently stops updating.

## The Core Rule

Subsystem `fire()` and any `process()` it calls run **inside the tick**. They must never block. Blocking starves the Master Controller and can freeze the whole loop with no runtime.

## Red Flags In A Hot Path

A `fire()`, `process()`, or signal handler must not contain:

| Hazard | Why it is bad |
|---|---|
| `sleep()` / `sleep(0)` | yields the proc mid-fire; the SS loses its slot or double-fires |
| `do_after(...)` | sleeps for seconds |
| `input()` / `alert()` / `tgui_*` blocking prompts | waits on a player indefinitely |
| `browse()` to a slow client, blocking RSC ops | network stall inside the tick |
| `walk()` / `walk_to()` / `walk_towards()` | engine-managed movement; conflicts with move loops, hard to stop |
| `for()` over a large list with no `CHECK_TICK` | one tick eats the whole budget; watchdog may kill the proc |
| `set waitfor = FALSE` misuse | proc returns early; caller assumes it finished |
| `addtimer()` storms | thousands of timers overwhelm `SStimer` |

Any registered signal handler must carry `SIGNAL_HANDLER` and obey `SHOULD_NOT_SLEEP`.

## Yield Correctly Instead

| Mechanism | Where | Use |
|---|---|---|
| `MC_TICK_CHECK` | inside a subsystem `fire()` | pause the SS, resume next fire (`code/__DEFINES/MC.dm`) |
| `CHECK_TICK` | inside any long loop (non-SS, init) | sleep until next tick (`code/__DEFINES/_tick.dm`) |
| `START_PROCESSING(SS, datum)` / `STOP_PROCESSING(SS, datum)` | datum lifecycle | join/leave a processing SS instead of a custom loop |
| `addtimer(CALLBACK(...), wait)` | one-shot deferred work | instead of `sleep` |
| `SSfastprocess` vs `SSprocessing` vs `SSobj` | pick the right cadence | do not over-schedule |

A processing SS that supports `MC_TICK_CHECK`-style resumption keeps `resumed` state — handle the `fire(resumed)` argument.

## Debug Order

1. Identify the frozen `SS*` (`ai_navigation/subsystem_map.md`).
2. Read its `fire()` and every `process()` it iterates — look for the Red Flags above.
3. Check whether a long loop has `CHECK_TICK` / `MC_TICK_CHECK`.
4. Check `START_PROCESSING` / `STOP_PROCESSING` pairing — a corrupted processing list stalls iteration.
5. Only after ruling out blocking calls, consider genuine CPU load (`ai_navigation/engine_limits.md`).

## Cheap Search Patterns

```
rg -n "sleep\(|do_after\(|input\(|walk\(|walk_to\(" code/<area> -g "*.dm"
rg -n "/proc/process\(|/proc/fire\(" code/<area> -g "*.dm"
rg -n "CHECK_TICK|MC_TICK_CHECK" code/<area> -g "*.dm"
rg -n "START_PROCESSING\(|STOP_PROCESSING\(" code modular_bandastation -g "*.dm"
```

## Interpretation

- Freeze with **no runtime** → almost always a blocking call in a hot path, not load.
- Lag with the SS still firing → genuine cost; profile and reduce work per fire.
- If the owner is known but the mode is unclear → `ai_navigation/failure_modes.md`.
