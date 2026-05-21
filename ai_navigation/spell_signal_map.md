# Spell / Action Signal Map

Generated 2026-05-21. Actions, spells, abilities, cooldowns, and status effects. This system is mostly **proc + cooldown driven** (not heavily signal-driven) — verify exact proc names in source.

## Canonical Entry Files

| Concern | Open first |
|---|---|
| Action base | `code/datums/actions/action.dm` |
| Cooldown action base | `code/datums/actions/cooldown_action.dm` |
| Innate / item actions | `code/datums/actions/innate_action.dm`, `code/datums/actions/item_action.dm` |
| Spells | `code/modules/spells/spell.dm`, `code/modules/spells/spell_types/**` |
| Status effects | `code/datums/status_effects/**` |
| Fork status effects | `modular_bandastation/status_effects/**` |

> There is no `code/datums/actions/cooldowns/` subdirectory and no `code/modules/crafting/`. Actions are the flat files above.

## Action Contract

`/datum/action` (`code/datums/actions/action.dm`):

| Proc | Role |
|---|---|
| `Grant(mob/grant_to)` | attach the action to a mob (adds the HUD button) |
| `Remove(mob/remove_from)` | detach |
| `Trigger(trigger_flags)` | the action fires — main entrypoint |
| `IsAvailable(feedback)` | gate check (alive, conscious, ...) |
| `set_statpanel_format` / `UpdateButtons` | HUD button refresh |

`/datum/action/cooldown` (`cooldown_action.dm`) adds cooldown tracking — `StartCooldown()`, `next_use_time`. Spells subclass it.

## Spell Contract

`/datum/action/cooldown/spell` (`code/modules/spells/spell.dm`) is the spell base. The cast chain is roughly:

`Trigger()` → availability/cost checks → `before_cast(atom/cast_on)` → `cast(atom/cast_on)` → `after_cast(atom/cast_on)` → `StartCooldown()`.

Open `code/modules/spells/spell.dm` to confirm the current proc names and any cast signals — TG renames parts of this chain over time. Concrete spells live in `code/modules/spells/spell_types/**`.

## Status Effects

`/datum/status_effect` (`code/datums/status_effects/**`):

| Proc | Role |
|---|---|
| `on_apply()` | applied to a mob; return `FALSE` to reject |
| `tick(seconds_between_ticks)` | periodic effect |
| `on_remove()` | cleanup |

Apply via `mob.apply_status_effect(/datum/status_effect/...)`. Buffs/debuffs are subdirectories. High-frequency effects route through `SSpriority_effects` / `SSprocessing`.

## Cheap Search Order

```
rg -n "/datum/action/.*/proc/Trigger\(" code/datums/actions -g "*.dm"
rg -n "/proc/(before_cast|cast|after_cast)\(" code/modules/spells -g "*.dm"
rg -n "apply_status_effect\(" code modular_bandastation -g "*.dm"
rg -n "COMSIG_MOB.*SPELL|COMSIG.*CAST" code/__DEFINES/dcs -g "*.dm"
```

## Routing

- A spell that does nothing: check `IsAvailable()` / cost gates and the cooldown, not just `cast()`.
- A new ability: prefer subclassing an existing `spell_type` or `cooldown` action over a bespoke datum (`ai_navigation/human_checking.md` — shared `/datum/action` is a high-risk root).
- Action HUD buttons are screen objects — see `code/_onclick/hud/**`.
