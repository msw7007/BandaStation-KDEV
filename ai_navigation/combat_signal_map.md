# Combat Signal Map

Generated 2026-05-21. The attack chain — proc order, key files, and signals. Use it before touching melee, item-on-atom, projectile, or damage code.

This codebase uses the **modern TG attack chain** (`attack_modifiers` + `interact_with_atom`), not legacy `afterattack(proximity)`.

## Canonical Entry Files

| Flow | Open first |
|---|---|
| Click → attack dispatch | `code/_onclick/click.dm` |
| Item attack chain | `code/_onclick/item_attack.dm` |
| Empty-hand / mob-on-mob | `code/_onclick/other_mobs.dm` |
| Non-combat tool use | `code/game/atom/atom_tool_acts.dm` |
| Damage application | `code/modules/mob/living/damage_procs.dm`, `code/game/atom/atom_defense.dm` |
| Projectiles | `code/modules/projectiles/projectile.dm`, `code/modules/projectiles/gun.dm` |

## Click Dispatch

`/atom/Click()` → `/mob/proc/ClickOn(atom, params)` (`code/_onclick/click.dm`). `ClickOn` routes to one of:

| In hand | In reach | Result |
|---|---|---|
| item | yes | `melee_attack_chain` |
| empty | yes | `UnarmedAttack` → `attack_hand` |
| item / empty | no | `RangedAttack` / `base_ranged_item_interaction` |

## Melee Attack Chain (in order)

`melee_attack_chain(mob/user, atom/target, list/modifiers, list/attack_modifiers)` — all in `code/_onclick/item_attack.dm`:

1. `base_item_interaction` — non-combat interaction first (`code/game/atom/atom_tool_acts.dm`).
2. `pre_attack(target, user, modifiers, attack_modifiers)` — veto point.
3. `attackby(attacking_item, user, modifiers, attack_modifiers)` — on the target atom.
4. `attack(mob/living/target, user, ...)` if the target is a mob, else `attack_atom(atom, user, ...)`.
5. `attacked_by(attacking_item, user, ...)` — `/mob/living/attacked_by` does the armor check and calls `apply_damage`.
6. `afterattack(target, user, ...)` — `PROTECTED_PROC`, post-hit effects.

Right-click variants exist as `_secondary` procs (`pre_attack_secondary`, `attackby_secondary`, `attack_secondary`) returning `SECONDARY_ATTACK_*`.

## Damage Application

| Proc | File | Notes |
|---|---|---|
| `/mob/living/proc/apply_damage(...)` | `code/modules/mob/living/damage_procs.dm` | emits `COMSIG_MOB_APPLY_DAMAGE`, then `COMSIG_MOB_AFTER_APPLY_DAMAGE` |
| `/mob/living/proc/apply_damages(...)` | `code/modules/mob/living/damage_procs.dm` | several damage types at once |
| `/atom/proc/take_damage(...)` | `code/game/atom/atom_defense.dm` | requires `uses_integrity = TRUE` |
| `/atom/proc/bullet_act(obj/projectile, ...)` | `code/game/atom/atom_act.dm` | projectile impact |
| bodypart `receive_damage(brute, burn, ...)` | `code/modules/mob/living/...bodypart` | called by `apply_damage` for limb hits |

## Projectiles

| Proc | File |
|---|---|
| `/obj/projectile/proc/fire(angle, direct_target)` | `code/modules/projectiles/projectile.dm` |
| `/obj/projectile/proc/on_hit(target, blocked, pierce_hit)` | `code/modules/projectiles/projectile.dm` |
| `/obj/item/gun/proc/process_fire(target, user, ...)` | `code/modules/projectiles/gun.dm` |

`SSprojectiles` (`code/controllers/subsystem/processing/projectiles.dm`) processes in-flight projectiles.

## Fork Notes

- `attack_modifiers` is threaded through the whole chain alongside `modifiers`; force/damtype/sharpness are computed lazily (`CALCULATE_FORCE` macro). Treat `attack_modifiers` as first-class.
- A stamina cost (`spend_stamina(STAMINA_COST_ATTACK, ...)`) is charged inside `melee_attack_chain`.
- Combat tweaks live in `modular_bandastation/{weapon,martial_arts,balance}` — check there for fork overrides.
- User-facing attack messages use a Russian grammar/declension system — expect localised strings in these procs.

## Cheap Search Order

```
rg -n "/proc/melee_attack_chain\(|/proc/attackby\(|/proc/attacked_by\(" code -g "*.dm"
rg -n "COMSIG_MOB_APPLY_DAMAGE|COMSIG_MOB_AFTER_APPLY_DAMAGE" code -g "*.dm"
rg -n "/proc/attack\(|/proc/attack_atom\(" code/_onclick -g "*.dm"
```
