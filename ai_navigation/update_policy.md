# Update & Migration Policy

Generated 2026-05-21. This is the **Maintenance Start** entrypoint — for refreshing this navigation layer after the codebase drifts, or migrating the methodology elsewhere.

## Terminology

- "navigation layer" / "AI mapping" = the docs in `ai_navigation/`.
- It does **not** mean in-game maps (`_maps/**`, `code/modules/mapping/**`, `SSmapping`).

For ordinary feature work, do not start here — use `ai_navigation/router.md`.

## Ground Rules

- Source files (`code/**`, `modular_bandastation/**`) are the authority. These docs are hints.
- Never treat a navigation doc as ground truth during a refresh.
- If a doc and the code disagree, update the doc to match the code.
- Refreshing is **docs-only** — do not modify game code, `tgstation.dme`, or its include lines.

## Navigation Miss Protocol (applies during ALL work, not just refreshes)

A missing or wrong entry does not mean the thing does not exist.

1. Do not conclude absence. Say "navigation may be stale here" and verify directly.
2. Grep the source:
   ```
   rg -n "SUBSYSTEM_DEF\(materials\)" code/controllers/subsystem -g "*.dm"
   rg -n "/obj/item/<thing>" code modular_bandastation -g "*.dm"
   rg -n "<keyword>" code modular_bandastation -g "*.dm"
   ```
3. If grep confirms it exists, use the real file — not the navigation entry.
4. Tell the user the navigation was stale and what you found.
5. Propose a fix to the relevant doc so the miss does not recur.

## When To Update

| Trigger | Refresh |
|---|---|
| New subsystem(s) added/removed | `subsystem_map.md`, `entrypoints.md`, `system_map.md` |
| New `modular_bandastation/` module(s) | `modular_guide.md`, `system_map.md`, `entrypoints.md` |
| Combat / movement / signal contract changed | the relevant signal map, `core_procs.md` |
| Directory restructure / `.dme` reorder | `architecture.md`, then everything downstream |
| CI / tooling changed | `coding_standards.md` |
| Routine drift check | quarterly, or when routes start missing |

## What Drifts First

| Speed | Files | Why |
|---|---|---|
| Fast | `entrypoints.md`, `subsystem_map.md`, `system_map.md` | new systems, new `SS*`, renamed paths |
| Medium | `signal_map.md`, `combat_signal_map.md`, `movement_signal_map.md`, `spell_signal_map.md`, `runtime_flow.md`, `core_procs.md` | contracts change with features |
| Slow | `architecture.md`, `router.md`, `processing_hazards.md`, `type_index.md` | structural changes are rare |
| Rarely | root `AGENTS.md`, `ai_navigation/AGENTS.md`, `human_checking.md`, `coding_standards.md`, `task_templates.md`, `update_policy.md` | policy files, not derived from code |

Minimal refresh: rebuild the ownership layer (`subsystem_map.md`) and the routing layer (`system_map.md`, `entrypoints.md`, `router.md`) — that covers most routing value.

## Rebuild Order

1. **Shape** — verify top-level dirs, the `.dme` invariants, that `modular_bandastation/` still loads last. Skip if no structural change.
2. **Ownership** — rebuild `subsystem_map.md` from real declarations (command below). The most important file.
3. **Routing** — refresh `system_map.md`, `entrypoints.md`, then verify every `router.md` target exists.
4. **Reasoning** — re-check `runtime_flow.md`, `system_dependencies.md`, `debug_routes.md`.
5. **Contracts** — re-check the signal maps, `core_procs.md`, `processing_hazards.md`, `failure_modes.md` against current procs.
6. **Workflow** — `human_checking.md`, `coding_standards.md`, `task_templates.md` only if policy/tooling changed.
7. **Entry files** — final pass on `router.md`, `ai_navigation/AGENTS.md`, and the root `AGENTS.md` (project entry — keep its index and routes in sync).

## Rebuild Commands

```
# subsystems
rg -n "(SUBSYSTEM_DEF|PROCESSING_SUBSYSTEM_DEF|TIMER_SUBSYSTEM_DEF|MOVEMENT_SUBSYSTEM_DEF|FLUID_SUBSYSTEM_DEF|VERB_MANAGER_SUBSYSTEM_DEF|AI_CONTROLLER_SUBSYSTEM_DEF|UNPLANNED_CONTROLLER_SUBSYSTEM_DEF)\(" code/controllers/subsystem modular_bandastation -g "*.dm"

# signal defines
rg -n "#define COMSIG_" code/__DEFINES/dcs modular_bandastation -g "*.dm"

# signal call sites
rg -c "SEND_SIGNAL\(" code modular_bandastation -g "*.dm"
rg -c "RegisterSignal\(" code modular_bandastation -g "*.dm"

# modular module list
Get-Content modular_bandastation/modular_bandastation.dme

# .dme invariants
rg -n "genesis_call|modular_bandastation" tgstation.dme
```

## Validation Checklist

Run before closing a refresh:

- [ ] every file referenced in `router.md` and the root `AGENTS.md` index exists
- [ ] every `Open first` path in `entrypoints.md` resolves
- [ ] every `SS*` in `subsystem_map.md` maps to a real file
- [ ] `architecture.md` runtime backbone matches the current `SS*` set
- [ ] no source files, `tgstation.dme`, or `.dme` includes were modified
- [ ] no stale paths from other codebases remain in routes (see below)
- [ ] uncertain areas are explicitly flagged in the doc

```
# path existence sweep
Get-ChildItem ai_navigation -File | ForEach-Object { $_.Name }
# stale foreign-codebase paths must NOT appear in routes:
rg -n "Azure-Peak|roguetown\.dme|modular/Neu_|familytree|Twilight" ai_navigation
```

## Conflict Resolution (docs vs code)

| Situation | Action |
|---|---|
| Doc names a file that no longer exists | grep for the renamed/moved file, update the route |
| Doc says a system is absent, code has it | use the code, add the system to the map, flag the gap |
| Code has a system not in any doc | add it to `entrypoints.md` / `system_map.md` |
| Doc and code describe different behaviour | trust the code, rewrite the doc |
| Area genuinely uncertain | leave it, but mark it explicitly as `UNCERTAIN — verify in source` |

## Migration Note

This layer's *methodology* (three Start Modes; cheap routing → deep reference → contracts; "open first / then check / owner" tables; risk tiers; "docs may be stale, source wins") was migrated from an earlier navigation layer on a different codebase. When migrating it again: preserve the **reasoning model**, regenerate every path, subsystem name, and contract from the target repo. Build only the contract helpers the target actually has — a signal map is worthless for a codebase without signals.
