# Modular Guide

Generated 2026-05-21. Read this when the task touches `modular_bandastation/**`, when deciding **where new fork code belongs**, or when a core proc seems to behave differently than upstream TG.

## What The Modular Layer Is

`modular_bandastation/` is the BandaStation fork's **late-included overlay**. It is the final `#include` in `tgstation.dme` (line 6961, manually appended after `// END_INCLUDE` at line 6958 — outside the generated include block), so its definitions compile **after** all of `code/**` and can override upstream TG behaviour by re-opening core types.

Each feature is a **modpack**: a `/datum/modpack/<name>` subtype. `SSmodpacks` instantiates every modpack at boot and runs `pre_initialize()` / `initialize()` / `post_initialize()`.

| Item | File |
|---|---|
| Modpack base datum | `modular_bandastation/_modpack.dm` |
| Modpack controller | `modular_bandastation/_modpacks.dm` (`SUBSYSTEM_DEF(modpacks)`, `INITSTAGE_FIRST`, `SS_NO_FIRE`) |
| Aggregator | `modular_bandastation/modular_bandastation.dme` |

## Module Layout

The aggregator `modular_bandastation.dme` has three blocks:

1. `_modpack.dm`, `_modpacks.dm` — base datum + controller.
2. `// --- MODULES ---` — one `#include "<folder>/_<folder>.dme"` per module.
3. `// --- PRIME ---` — `prime_only/_prime_only.dme`, gated behind `#ifndef DISABLE_PRIME_MODPACKS`.

A typical module folder `modular_bandastation/<name>/` contains:

| File / dir | Role |
|---|---|
| `_<name>.dme` | mini-aggregator: `#include`s the head file then every `code/...` file — **read this first** for any module |
| `_<name>.dm` | head file: declares `/datum/modpack/<name>` (`name`, `desc`, `author`) |
| `code/**` | the actual logic, mirroring TG's path structure under the module root |
| `icons/`, `sound/` | optional assets |

## Infrastructure Modules (included first)

These five `_`/`~`-prefixed modules load before gameplay modules so their defines/signals/components exist at compile time:

| Module | Role |
|---|---|
| `_defines220` | compile-time `#define`s (combat, jobs, mobs, preferences, roles, ...) |
| `_signals220` | signal-name `#define`s (`code/signals_*`) |
| `_helpers220` | misc global helper procs |
| `_singletons` | singleton / repository pattern infrastructure |
| `~components` | DCS `/datum/component` subtypes (`~` forces early alphabetical sort) |

Also infrastructure: `overrides` (direct upstream behaviour overrides), `datums` (small shared datums), `database220`, `world_topics`, `translations`.

> The `220` suffix marks the SS220/BandaStation lineage. `prime_only` reaches across module boundaries with relative `#include`s to assemble a server-variant bundle.

## Where New Fork Code Belongs

| You are adding... | Put it in... |
|---|---|
| A new self-contained fork feature | a new `modular_bandastation/<name>/` module (folder + `_<name>.dm` + `_<name>.dme` + `code/`, plus a line in the aggregator's MODULES block) |
| Code into an existing fork feature | that module's `code/` tree; add the file to its `_<name>.dme` |
| A define / signal used fork-wide | `_defines220` / `_signals220` |
| A component reused fork-wide | `~components` |
| A deliberate override of upstream TG | `overrides`, or re-open the type inside the relevant module |
| A change to genuinely shared core mechanics | `code/**` — but classify risk first (`ai_navigation/human_checking.md`) |

## Key Rules

- Adding a module **requires** a new include line in `modular_bandastation/modular_bandastation.dme`. Editing the aggregator counts as a `.dme`/include change — get explicit approval (`ai_navigation/human_checking.md`).
- When mapping any core proc, also grep `modular_bandastation/` — the overlay frequently re-opens core types. A behaviour that contradicts upstream TG is usually a modular override.
- `example` and `emojis220` exist on disk but are **not** wired into the aggregator.
- Prefer the narrowest module. Do not widen a feature into core `code/**` unless it is genuinely shared.

## Verify

```
rg -n "modular_bandastation" tgstation.dme        # confirm aggregator wiring
Get-Content modular_bandastation/modular_bandastation.dme   # current module list
rg -n "/datum/modpack/" modular_bandastation -g "_*.dm"     # all declared modpacks
```
