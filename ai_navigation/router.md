# Router

Generated 2026-05-21 for `BandaStation-Kagelite_DEV`. Primary **Fast Start** entrypoint for normal tasks. Pick one helper, open up to 2-3 source files, escalate only if unresolved.

## Always

| When | Action |
|---|---|
| before any medium / high / unclear-scope edit | open `ai_navigation/human_checking.md` first |
| docs say something does not exist | do not conclude it is absent — verify with `rg` / file search |
| a route returns nothing | search `code/` and `modular_bandastation/` directly; if found, use it and flag the navigation gap |
| docs and code disagree | trust the code; say navigation may be stale |
| editing a core `code/` proc | also grep `modular_bandastation/` for an override of the same type |

## Dispatch

| Task | Helper |
|---|---|
| keyword / feature-name routing | `ai_navigation/entrypoints.md` |
| symptom-first bug report | `ai_navigation/debug_routes.md` |
| planned change may be broad, risky, or needs approval | `ai_navigation/human_checking.md` |
| refresh or migrate this navigation layer | `ai_navigation/update_policy.md` |
| explicit subsystem, `SS*`, `Master`, tick scheduling | `ai_navigation/subsystem_map.md` |
| main proc entrypoints before searching source | `ai_navigation/core_procs.md` |
| lifecycle, round flow, `Initialize()`, boot order | `ai_navigation/runtime_flow.md` |
| signal, component, element, `COMSIG_*` behavior | `ai_navigation/signal_map.md` |
| melee / projectile / attack chain | `ai_navigation/combat_signal_map.md` |
| movement, pull, buckle, throw, moveloop | `ai_navigation/movement_signal_map.md` |
| spell, action, ability, cooldown, status effect | `ai_navigation/spell_signal_map.md` |
| whole process loop or subsystem freezes without runtimes | `ai_navigation/processing_hazards.md` |
| failure-mode analysis after the owner is known | `ai_navigation/failure_modes.md` |
| runtime error, `qdel`, `Destroy()`, ref leak, hard delete | `ai_navigation/runtime_errors.md` |
| performance, tick budget, BYOND/MC engine limit | `ai_navigation/engine_limits.md` |
| TGUI, `ui_interact`, `ui_data`, `ui_act`, React interface | `ai_navigation/tgui_guide.md` |
| overlays, planes, lighting, filters, appearance, icon smoothing | `ai_navigation/visuals_guide.md` |
| modular overlay, modpack, where fork code belongs | `ai_navigation/modular_guide.md` |
| cross-system handoff or dependency | `ai_navigation/system_dependencies.md` |
| BYOND type path `/datum/...` `/mob/...` `/obj/...` `/turf/...` | `ai_navigation/type_index.md` |
| code style, signal pattern, GC, macros, CI | `ai_navigation/coding_standards.md` |
| unknown area or architecture | `ai_navigation/system_map.md`, then `ai_navigation/architecture.md` |
| task framing / prompt templates (for humans) | `ai_navigation/task_templates.md` |

Escalation: if the dispatch row does not resolve the task, open `ai_navigation/entrypoints.md` for keyword routing, then `ai_navigation/system_map.md` for the coarse area.
