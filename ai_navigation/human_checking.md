# Human Checking

Generated 2026-05-21. Use this **before edits** when the change may have a wide blast radius, an uncertain audience, or non-trivial server cost. It forces a human approval checkpoint.

## Goal

Stop and get human approval before medium-risk, high-risk, or ambiguous-scope work. This is a station codebase — many shared roots are reached by hundreds of objects/mobs per round.

## Risk Tiers

### No Risk — proceed

- Cosmetic variant of an existing item/mob (icon state, name, description).
- A one-off subtype that reuses existing behaviour unchanged.
- This navigation layer (`ai_navigation/**`) — docs-only edits.

### Low Risk — state the scope, then proceed

- A unique object/mob on an isolated branch with a small known audience.
- A localised proc override for one narrow type family.
- A self-contained new `modular_bandastation/` module that touches nothing shared.

### Medium Risk — ask for approval before editing

- A shared mechanic reachable by a broad family (a common item type, a large mob population).
- A new component/element intended for multiple real users.
- Changes to a shared status effect, action, job, or AI behaviour that many actors reach.
- Editing a widely-included define in `code/__DEFINES/**` or `_defines220`.

### High Risk — ask for approval AND give a blast-radius + server-cost summary

- `code/controllers/**` — `Master`, any `SS*` subsystem, `code/game/world.dm`.
- Base roots: `/atom`, `/atom/movable`, `/datum`, `/mob`, `/mob/living`, `/obj`, `/obj/item`, `/turf`, `/area`.
- Shared abstractions: `/datum/component`, `/datum/element`, `/datum/status_effect`, `/datum/action`.
- Per-tick / per-step / per-fire hooks, or always-on signal handlers across a large population.
- Roundstart ownership: `SSticker` setup, `SSjob` division, `SSdynamic` rulesets.
- Economy, mapgen / `SSmapping`, persistence / `SSpersistence` (cross-round save data).
- Broad NPC / AI population changes.
- Any change to `tgstation.dme` or a module `.dme` (include graph / build order).

## Default Rule

If scope is unclear, treat it as **at least medium** until the user clarifies the intended audience and blast radius.

## Approval Gates

| Tier | Gate |
|---|---|
| no risk | proceed |
| low risk | state the local scope, proceed |
| medium risk | ask for approval before editing |
| high risk | ask for approval, state blast radius + server-cost risk; if it creates/destroys objects, re-check the GC contract (`ai_navigation/runtime_errors.md`, `ai_navigation/coding_standards.md`) |
| unknown risk | ask for clarification before editing |

## Questions To Ask The Human

Ask only what constrains the blast radius:

1. Who uses this now, and who realistically will later?
2. Is touching a shared root acceptable, or should this stay in a `modular_bandastation/` module?
3. Is per-tick / per-step behaviour acceptable, or must it stay event-driven (signals)?
4. Is minimum server cost more important than future reuse here?
5. Does this need cross-round persistence, roundstart wiring, or a `.dme` change?

## Rule Of Thumb

- Unique cosmetic / content variant → usually no risk.
- Unique isolated gameplay object → usually low risk.
- Shared mechanic with many real users → usually medium risk.
- Subsystems, shared roots, hot paths, roundstart/economy/persistence → usually high risk.
