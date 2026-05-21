# Task Templates

Generated 2026-05-21. Copy-paste prompt templates for **humans** briefing an agent on `BandaStation-Kagelite_DEV`. Not for agents to read mid-task.

## Default Routing Rule

Every template assumes the agent starts at `ai_navigation/router.md` (Fast Start). For broad/risky work, point it at `ai_navigation/AGENTS.md` (Guided Start). For navigation-layer refreshes, `ai_navigation/update_policy.md` (Maintenance Start).

## 1. Minimal Fast Task

```
Task: <one concrete change>.
Start at ai_navigation/router.md. Open at most 3 source files.
Verify against code before editing. No broad refactor.
```

## 2. Bugfix

```
Bug: <symptom + how to reproduce>.
Start at ai_navigation/debug_routes.md, match the symptom.
Find the runtime owner, then the failing proc/override.
If owner is known but cause unclear, use ai_navigation/failure_modes.md.
Fix the root cause only. Show the diff before applying.
```

## 3. New Feature

```
Feature: <what it does, who uses it, how often>.
Start at ai_navigation/router.md, then ai_navigation/entrypoints.md for the area.
Classify risk with ai_navigation/human_checking.md before editing.
Prefer a new modular_bandastation/ module (ai_navigation/modular_guide.md).
Do not widen into shared code/** roots without approval.
```

## 4. Refactor / Cleanup

```
Refactor: <what, and why it is safe>.
This is medium/high risk by default — classify with ai_navigation/human_checking.md
and get approval on blast radius before editing.
Keep behaviour identical unless told otherwise. No drive-by changes.
```

## 5. Architecture Investigation

```
Question: <architecture / "how does X work" question>.
Start at ai_navigation/architecture.md and ai_navigation/runtime_flow.md.
Use ai_navigation/subsystem_map.md for ownership.
Answer with real file paths. Do not edit anything.
```

## 6. Code Review

```
Review: <branch / PR / changeset>.
Check against ai_navigation/coding_standards.md.
Flag: missing ..(), GC contract gaps, blocking calls in hot paths,
unguarded ui_act params, .dme/include changes, oversized blast radius.
```

## 7. Runtime / Performance

```
Symptom: <lag / freeze / tick budget>.
Start at ai_navigation/processing_hazards.md.
Identify the SS* via ai_navigation/subsystem_map.md.
Rule out blocking calls before blaming load. Reference ai_navigation/engine_limits.md.
```

## 8. Content / Data

```
Content: <new item/mob/recipe/job/etc.>.
Start at ai_navigation/entrypoints.md for the domain.
Prefer the narrowest existing subtype/host. Cosmetic-only = no risk.
Check modular_bandastation/ for an existing extension of the same area first.
```

## 9. Navigation Refresh / Migration

```
Task: refresh (or migrate) the ai_navigation layer.
Start at ai_navigation/update_policy.md (Maintenance Start).
Source code is the authority; regenerate maps from the current repo.
Docs-only — do not modify game code or tgstation.dme.
```

## Recommended Human Workflow

1. Send the goal first, in its own message.
2. Then point the agent at this repo and the right start mode.
3. For anything broad or risky, require a risk classification + approval before edits.
4. Ask the agent to show diffs before applying non-trivial changes.
