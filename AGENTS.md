# AGENTS.md

**This file is the primary local instruction source for AI agents working in the `BandaStation-Kagelite_DEV` repository.** Together with the `ai_navigation/` directory it is the complete, self-contained, and authoritative set of working rules for this project. An agent that has read this file and uses `ai_navigation/` needs no external or global instructions.

If you have just opened this repository: read this file, then go to `ai_navigation/router.md`.

## Project

- Space Station 13 server codebase. Engine: BYOND / Dream Maker (DM language).
- tgstation-derived ("TG codebase"); the **BandaStation** fork (ss220club). Russian-localised.
- Project file: `tgstation.dme` (repo root). Core code: `code/**`. Fork overlay: `modular_bandastation/**` (compiled last, overrides core). In-game UI: `tgui/**` (React/TypeScript).

## How To Work In This Repo

`ai_navigation/` is a routing layer purpose-built for agents. It localises any task to the right files in 1-2 hops — use it instead of scanning the repository.

| Situation | Start at |
|---|---|
| ordinary task — bug, feature, question, known keyword/symptom | `ai_navigation/router.md` |
| broad / risky / multi-system / human-guided work | `ai_navigation/AGENTS.md` |
| refreshing or migrating the `ai_navigation/` layer itself | `ai_navigation/update_policy.md` |

Default path: open `ai_navigation/router.md` → pick one helper from its Dispatch table → open 1-3 source files. Do not begin with a full-repository scan.

> `ai_navigation/AGENTS.md` is a separate, detailed **Guided Start** document *inside* the layer. This root `AGENTS.md` is the repository entry point and takes precedence; the two are consistent.

## Rules (apply to every task)

1. **`ai_navigation/` is a routing aid, not a source of truth.** The truth is the live code in `code/**` and `modular_bandastation/**`. If a doc disagrees with the code, trust the code and report the mismatch.
2. **Never conclude something is absent** because a doc or route omitted it — search the source directly (`rg`) first.
3. **Check the overlay.** After finding code in `code/`, check `modular_bandastation/` for an override of the same type (it loads last and overrides core).
4. **Classify risk before editing** with `ai_navigation/human_checking.md`. Stop and get human approval for medium-risk, high-risk, or unclear-scope changes before you edit.
5. **Do not change the build graph** — `tgstation.dme`, any module `.dme`, or `#include` lines — without explicit approval.
6. **Do not run the game or start a server** unless explicitly asked.
7. **Stay in scope.** No broad refactors or drive-by cleanup unless that is the task.

"AI navigation" / "navigation layer" means the `ai_navigation/` docs — it is **not** the in-game map (`_maps/`, `SSmapping`, `code/modules/mapping/`).

## Build & Check

- Compile: `BUILD.cmd` (repo root) — wraps the `tools/build` pipeline.
- Build + run a local server: `RUN_SERVER.cmd`.
- CI: `.github/workflows/ci_suite.yml` — SpacemanDMM / DreamChecker, OpenDream compile, linters, tgui (Biome). Conventions: `ai_navigation/coding_standards.md`.

## `ai_navigation/` Contents

- Entry: `router.md`, `AGENTS.md`, `entrypoints.md`
- Orientation: `architecture.md`, `system_map.md`, `modular_guide.md`
- Runtime & ownership: `subsystem_map.md`, `runtime_flow.md`, `system_dependencies.md`, `core_procs.md`
- Debugging: `debug_routes.md`, `failure_modes.md`, `processing_hazards.md`, `runtime_errors.md`, `engine_limits.md`
- Contracts: `signal_map.md`, `combat_signal_map.md`, `movement_signal_map.md`, `spell_signal_map.md`
- Domain guides: `tgui_guide.md`, `visuals_guide.md`, `type_index.md`
- Process & policy: `coding_standards.md`, `human_checking.md`, `task_templates.md`, `update_policy.md`, `DEVELOPER_GUIDE.md`

When the codebase or this layer drifts, refresh per `ai_navigation/update_policy.md`.
