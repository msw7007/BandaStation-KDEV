# Repository Agent Guide

This is the **Guided Start** mode document of the `ai_navigation/` layer — not the cheapest default. For ordinary work, `ai_navigation/router.md` is cheaper.

The repository's auto-discovered entry file is the root `AGENTS.md`; it establishes the project rules and routes here for Guided Start. This file and the root `AGENTS.md` are consistent.

## Terminology

- "AI navigation", "navigation layer", "AI mapping" = the routing docs in `ai_navigation/` (this folder).
- It does **not** mean in-game maps: `_maps/**`, `code/modules/mapping/**`, or `SSmapping`. Those are game content, not this layer.

## What This Layer Is

`ai_navigation/` is a routing aid, **not** a source of truth. It helps an agent localise work quickly, then verify against source. It may lag the codebase by one refresh cycle. If the layer and the code disagree, **trust the code** and report the mismatch (`ai_navigation/update_policy.md` → Navigation Miss Protocol).

Source of truth is always `code/**` and `modular_bandastation/**`.

## Start Modes

| Situation | Mode | Entrypoint |
|---|---|---|
| ordinary task with a known keyword, type path, or symptom | Fast Start | `ai_navigation/router.md` |
| broad, risky, multi-system, or explicitly human-guided | Guided Start | this file → `ai_navigation/router.md` |
| refresh or migration of the navigation layer itself | Maintenance Start | `ai_navigation/update_policy.md` |

When in doubt, use Fast Start and escalate only if unresolved.

## Guided Start Bootstrap

1. Open `ai_navigation/router.md`.
2. Choose exactly one helper from the dispatch table.
3. Open up to 2-3 source files — do not start with a full repository scan if the layer narrows the task.
4. Check `modular_bandastation/` for an override of the same type (overlay loads last).
5. Before edits, classify the change with `ai_navigation/human_checking.md`. Do **not** make medium-risk, high-risk, or ambiguous-scope edits until the human approves the blast radius.
6. If the owner is known but the cause is unclear, use `ai_navigation/failure_modes.md`.
7. If a whole process loop freezes without runtimes, sweep for blocking calls (`ai_navigation/processing_hazards.md`) before blaming load.

## Project Facts

- Project file: `tgstation.dme` (repo root). Family: tgstation-derived BYOND/DM, BandaStation fork.
- Overlay layer: `modular_bandastation/` — loaded last; see `ai_navigation/modular_guide.md`.
- This navigation layer is **docs-only**. Do not edit game code, `tgstation.dme`, or its include lines without explicit approval.

## If You Need More

| Need | Open |
|---|---|
| specific routing | `ai_navigation/router.md` |
| human onboarding / handoff pattern | `ai_navigation/DEVELOPER_GUIDE.md` |
| task framing / prompt templates | `ai_navigation/task_templates.md` |
| architecture overview | `ai_navigation/architecture.md` |
