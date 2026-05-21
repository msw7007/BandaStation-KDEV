# Type Index

Generated 2026-05-21. Cheapest route when a task gives a BYOND **type path**. Maps root branches to their source directory so you can jump straight in without scanning.

DM has a single-inheritance type tree. A path like `/obj/item/clothing/suit/armor` is found by walking the branch from its root.

## Major Roots

| Root | Usually means | Open first |
|---|---|---|
| `/datum` | non-visual logic object | `code/datums/**` |
| `/datum/component` | per-instance attachable behaviour | `code/datums/components/**`, `modular_bandastation/~components/**` |
| `/datum/element` | stateless shared behaviour | `code/datums/elements/**` |
| `/datum/controller/subsystem` | a subsystem | `code/controllers/subsystem/**` (`ai_navigation/subsystem_map.md`) |
| `/datum/action` | clickable action / ability | `code/datums/actions/**` |
| `/datum/status_effect` | timed buff/debuff | `code/datums/status_effects/**` |
| `/datum/wound` | injury | `code/datums/wounds/**` |
| `/atom` | base of everything visible | `code/game/atom/**` |
| `/atom/movable` | can move / be moved | `code/game/atoms_movable.dm` |
| `/turf` | a map tile | `code/game/turfs/**` |
| `/area` | a region of the map | `code/game/area/**` |
| `/obj` | a non-mob movable object | `code/game/objects/**` |
| `/obj/item` | a pick-up-able item | `code/game/objects/items/**`, `code/modules/clothing/**` |
| `/obj/machinery` | a machine | `code/game/machinery/**` |
| `/obj/structure` | a fixed structure | `code/game/objects/structures/**` |
| `/obj/projectile` | a bullet / beam | `code/modules/projectiles/**` |
| `/obj/effect` | transient/visual effect | `code/game/objects/effects/**` |
| `/mob` | a controllable / living entity base | `code/modules/mob/**` |
| `/mob/living` | anything alive | `code/modules/mob/living/**` |
| `/mob/living/carbon/human` | a human | `code/modules/mob/living/carbon/human/**`, `modular_bandastation/species/**` |
| `/mob/living/basic`, `/mob/living/simple_animal` | NPC creatures | `code/modules/mob/living/basic/**`, `code/modules/mob/living/simple_animal/**` |
| `/mob/dead` | ghost / observer / new-player | `code/modules/mob/dead/**` |
| `/client` | a connected player's client | `code/modules/client/**` |
| `/datum/job` | a job definition | `code/modules/jobs/**`, `modular_bandastation/{jobs,ru_jobs}` |
| `/datum/reagent` | a chemical | `code/modules/reagents/**` |

## Cheap Rules

1. Search for the **exact full path** first: `rg -n "<full/type/path>" code modular_bandastation -g "*.dm"`.
2. If not found at that exact path, walk up one branch and search the parent — the leaf may be defined in the same file as a sibling.
3. Always check `modular_bandastation/**` — the overlay re-opens core types to override or extend them.
4. The branch root tells you the directory; the deeper segments narrow the file.

## No Full Type-Tree Dump

This layer deliberately does not ship a generated `type_tree.md`. A flat dump of thousands of paths is unreadable and stale on arrival. Use `rg` against source for inheritance questions; the type tree is in the code, accurately, already.

```
# definition of a type
rg -n "^/obj/item/clothing/suit/armor" code modular_bandastation -g "*.dm"
# direct children of a type
rg -n "^/obj/item/clothing/suit/armor/" code modular_bandastation -g "*.dm"
```
