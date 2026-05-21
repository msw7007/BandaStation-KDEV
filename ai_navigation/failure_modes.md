# Failure Modes

Generated 2026-05-21. Use this **after** the owner subsystem / datum is roughly known but the break mode is still unclear. It separates "where it breaks" from "how it breaks".

## Use This Helper When

- A route or symptom already pointed at a system, but the cause is not obvious.
- There is no runtime error, or the runtime points at a symptom rather than a cause.
- You are about to guess — classify the failure mode first instead.

## Scale First

Before classifying, ask how many things are affected. The mode is usually different at each scale:

| Scale | Typical mode |
|---|---|
| One specific instance | bad var / missing override / stale ref on that datum |
| One whole type family | wrong base proc, missing `..()`, wrong `Initialize` hint |
| A whole subsystem | `fire()` blocked, processing list corrupted, MC starvation |
| The whole round | boot-order / runlevel / config issue |

## Common Failure Modes

**Whole subsystem freezes (no runtime).** `fire()` or a `process()` it calls hit a blocking call and never yielded. → `ai_navigation/processing_hazards.md`.

**Single datum stuck while siblings work.** That instance has a bad var, an unfired timer, or a signal it is waiting on that never sends. Inspect the instance, not the type.

**Processing list issue.** A datum was added to a processing SS but never removed (or vice-versa): leaks, double-processing, or never-processing. Check `START_PROCESSING` / `STOP_PROCESSING` pairing and `Destroy()`.

**Cleanup not called.** `Destroy()` missing, not calling `..()`, or not nulling refs / unregistering signals → hard delete, ghost behaviour, or ref leak. → `ai_navigation/runtime_errors.md`.

**Timer issue.** `addtimer()` with the wrong flags, a `TIMER_UNIQUE`/`TIMER_OVERRIDE` collision, or a timer firing on a qdeleted datum. Owner: `SStimer`.

**Silent proc abort / too many iterations.** A loop without `CHECK_TICK` is killed by the "infinite loop" watchdog, or a proc returns early on a guard clause. No runtime, just nothing happens. Add logging at the suspected branch.

**Stale references.** A var still points at a qdeleted datum (`QDELETED()` true) or a `weakref` resolved to null. Behaviour looks "frozen" or throws null-deref later.

**Signal listener not firing.** Either the signal is never `SEND_SIGNAL`-ed, `RegisterSignal` targeted the wrong datum, the handler lacks `SIGNAL_HANDLER`, or the registration was lost on element re-attach. → `ai_navigation/signal_map.md`.

**Missing parent call.** An override does not call `..()`, so base setup/teardown/behaviour is skipped. Extremely common cause of "half-working" features.

**Mapload-only assumption.** Code assumes `mapload == TRUE` (or `FALSE`) and breaks for runtime-spawned (or map-placed) atoms. Check the `Initialize(mapload, ...)` branches.

## Cheap Distinguishers

| Question | If yes |
|---|---|
| Does it break for *every* instance of the type? | base proc / missing `..()` / wrong hint |
| Only after a while / under load? | processing-list leak or timer accumulation |
| Only for spawned (not map-placed) atoms, or vice-versa? | mapload assumption |
| Frozen with no runtime at all? | blocking call → `processing_hazards.md` |
| Null-deref some time *after* the real bug? | stale ref / cleanup not called |

## Cheap Search Patterns

```
rg -n "START_PROCESSING\(|STOP_PROCESSING\(" code modular_bandastation -g "*.dm"
rg -n "/proc/Destroy\(" code/<area> -g "*.dm"          # check for ..() and ref cleanup
rg -n "addtimer\(" code/<area> -g "*.dm"
rg -n "SIGNAL_HANDLER" code/<area> -g "*.dm"
```

## Rule Of Thumb

1. Establish scale (one / family / subsystem / round).
2. Classify into one mode above before reading more code.
3. Confirm with a targeted grep or a single log line — do not guess a fix.
