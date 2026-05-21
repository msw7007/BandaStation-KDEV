# Coding Standards

Generated 2026-05-21. Conventions for `BandaStation-Kagelite_DEV`. The linters and CI are authoritative — if this file and tooling disagree, trust the tooling and update this file.

## Quick Decision Table

| Situation | Rule |
|---|---|
| Setting up an atom | use `Initialize()`, not `New()`; return an `INITIALIZE_HINT_*`; call `..()` |
| Deleting anything | `qdel(thing)` — never raw `del()` |
| Writing `Destroy()` | call `..()`, null references, `UnregisterSignal`, `STOP_PROCESSING` |
| Reacting to an event | `RegisterSignal` + a `SIGNAL_HANDLER` proc; do not poll |
| Passing a proc | `PROC_REF()` / `TYPE_PROC_REF()` / `GLOBAL_PROC_REF()` |
| Long loop | `CHECK_TICK` (general) or `MC_TICK_CHECK` (inside `fire()`) |
| New fork feature | a `modular_bandastation/` module (`ai_navigation/modular_guide.md`) |
| Touching `code/**` shared roots | classify risk first (`ai_navigation/human_checking.md`) |

## Style & Formatting

- DM files: **tab** indentation, **LF** line endings, UTF-8 (`.editorconfig`).
- `.dm`, `.json`, `.md` use tab indent; other files space indent — follow `.editorconfig`.
- Naming: `snake_case` for procs and vars; type paths lowercase (`/obj/item/my_thing`).
- Use `var/name` typed declarations; avoid the ambiguous `.` member operator — be explicit with typed vars so DreamChecker can verify.
- `SpacemanDMM.toml` enforces `disallow_relative_type_definitions` and `disallow_relative_proc_definitions` — declare full absolute type/proc paths.

## Lifecycle & GC

- `Initialize(mapload, ...)` is `SHOULD_CALL_PARENT` and `SHOULD_NOT_SLEEP`. Branch on `mapload` only when behaviour genuinely differs map-load vs runtime.
- Return `INITIALIZE_HINT_LATELOAD` when setup depends on other atoms; implement `LateInitialize()`.
- Every `Destroy()` override must call `..()` and release what it acquired (refs, signals, processing membership, timers). Otherwise the object hard-deletes (`ai_navigation/runtime_errors.md`).
- `QDEL_NULL(x)` to delete-and-clear; `QDELETED(x)` / `QDELING(x)` to guard against stale refs.

## Signals, Components, Elements

- `RegisterSignal(target, COMSIG_X, PROC_REF(handler))`; the handler proc **must** be marked `SIGNAL_HANDLER` and must not sleep.
- `SEND_SIGNAL` / `SEND_GLOBAL_SIGNAL` to emit; defines live in `code/__DEFINES/dcs/**`.
- **Component** (`/datum/component`) = per-instance state attached to one datum. **Element** (`/datum/element`) = stateless, shared by argument hash across many datums. Pick element when there is no per-instance state.
- Fork-wide components belong in `modular_bandastation/~components`.

## Performance

- Nothing in a subsystem `fire()`, a `process()`, or a signal handler may block — see `ai_navigation/processing_hazards.md`.
- Use `addtimer()` (owner `SStimer`) for deferred work, not `sleep`.
- Use `START_PROCESSING` / `STOP_PROCESSING` to join a processing SS rather than rolling a custom loop.
- Respect the tick budget (`ai_navigation/engine_limits.md`).

## File Placement

- Upstream-shaped code → `code/**` matching the existing tree.
- Fork features → a `modular_bandastation/<module>/` module; add each file to the module's `_<module>.dme`.
- New compile-time defines → `code/__DEFINES/**` (core) or `_defines220` (fork-wide).
- Adding/removing include lines in `tgstation.dme` or a module `.dme` is a build-graph change — get explicit approval.

## SQL

- All DB access goes through `SSdbcore` (`code/controllers/subsystem/dbcore.dm`).
- Use parameterised queries (`SSdbcore.NewQuery` with `:param` placeholders) — never interpolate user input into SQL.
- Schema changes require a migration under `SQL/**`.

## TGUI

See `ai_navigation/tgui_guide.md`. In short: data via `ui_data`/`ui_static_data`, never trust `ui_act` params (validate server-side), the React component name must match the `.tsx` filename.

## Continuous Integration

CI (`.github/workflows/ci_suite.yml` → `run_linters.yml`) runs, among others:

| Check | What it enforces |
|---|---|
| DreamChecker (SpacemanDMM) | DM static analysis — type/proc-path errors, unused vars |
| OpenDream compile (`--define=CIBUILDING`) | the project compiles under OpenDream |
| `__odlint.dm` / `tools/ci/od_lints.dm` | extra `#pragma` lints under OpenDream |
| define sanity / trait validity | `tools/define_sanity`, `tools/trait_validity` |
| ticked-file enforcement | every `.dm` file is included in the `.dme` |
| grep checks | `tools/ci/check_grep.sh` — banned patterns |
| map / maplint checks | `_maps/**` integrity |
| TGUI checks | `tools/build/build.sh --ci lint tgui-test` (Biome + tests) |
| changelog check | a changelog entry exists |

JS/TS/CSS in `tgui/` is formatted and linted by **Biome** (`biome.json`): tab indent, single quotes, `var` banned, organise-imports on.

Run locally before pushing: `BUILD.cmd` (compile) and the tgui lint via `tools/build`.
