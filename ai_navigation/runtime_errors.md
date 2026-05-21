# Runtime Errors

Generated 2026-05-21. How to read BYOND runtime errors in this codebase, the common error types, and the `qdel` / garbage-collection contract.

## Reading A Runtime Error

A runtime line names the proc, the source file:line, and `usr`/`src` where available. Read it as:

- **What** failed (the message) → **where** (file:line) → **on what** (`src` type).
- The first runtime in a cascade is usually the real cause; later ones are fallout.
- Boot/init runtimes name a subsystem — start at that `SS*` (`ai_navigation/subsystem_map.md`).

Logs are under the round's `data/logs/**`. `SSblackbox` records telemetry; reference-tracking output (if enabled) appears in the runtime log.

## Common Errors

| Error | Most likely cause | First check |
|---|---|---|
| `Cannot read null.<var>` | a var/ref is null — datum was never set, or was `qdel`-ed | guard with `QDELETED()`; check `Initialize()` set it |
| `Cannot execute null.<proc>()` | calling a proc on a null ref | same — null/stale reference |
| `undefined proc or verb` | typo, wrong type path, or proc not on that type | verify the type actually defines/inherits the proc |
| `Cannot modify null.<var>` | writing to a null ref | initialisation order — see `ai_navigation/runtime_flow.md` |
| `too many iterations` / proc killed | a loop with no `CHECK_TICK` hit the watchdog | add `CHECK_TICK` / `MC_TICK_CHECK` (`ai_navigation/processing_hazards.md`) |
| `deleting <X>` / hard-delete spam | `Destroy()` did not clear refs / unregister signals | see GC contract below |
| Signal handler runtime | handler sleeps or touches a freed datum | mark `SIGNAL_HANDLER`, do not sleep |
| Init runtime, no `INITIALIZE_HINT` | `Initialize()` returned nothing or didn't `..()` | return a valid `INITIALIZE_HINT_*`, call parent |

## qdel vs del

- Always delete with `qdel(thing)` — never raw `del()`. `qdel` runs `Destroy()` and routes through `SSgarbage` (`code/controllers/subsystem/garbage.dm`).
- `del()` skips cleanup, breaks signal/component teardown, and stalls the server while it scans every reference.

## The GC Contract

`qdel(X)` → `X.Destroy(force)` → returns a `QDEL_HINT_*` → `SSgarbage` queues the ref → if it is still referenced after the GC delay, **hard delete** (a slow `del`, logged as a failure).

Every `Destroy()` override must:

1. Call `..()` — the parent chain releases base resources.
2. Null out vars that hold references to other datums.
3. `UnregisterSignal()` everything it registered.
4. `STOP_PROCESSING()` if it joined a processing subsystem.
5. `qdel` or release owned sub-datums (components clean up via their own `Destroy`).

Helpers (`code/__DEFINES/qdel.dm`): `QDEL_NULL(x)` (delete + null), `QDEL_LIST(L)`, `QDEL_IN(x, time)`, and the guards `QDELETED(x)` / `QDELING(x)` / `QDESTROYING(x)`.

## Finding A Leak

If something hard-deletes, something still holds a reference to it. Reference tracking only compiles under `#ifdef REFERENCE_TRACKING` (`QDEL_HINT_FINDREFERENCE`). To investigate:

```
rg -n "/proc/Destroy\(" code/<area> -g "*.dm"        # does it ..() and clear refs?
rg -n "RegisterSignal\(" code/<area> -g "*.dm"        # paired UnregisterSignal / cleared on Destroy?
rg -n "START_PROCESSING\(" code/<area> -g "*.dm"      # paired STOP_PROCESSING?
```

## Escalation

- Owner known, break mode unclear → `ai_navigation/failure_modes.md`.
- Freeze with no runtime → `ai_navigation/processing_hazards.md`.
- Lifecycle ordering → `ai_navigation/runtime_flow.md`.
