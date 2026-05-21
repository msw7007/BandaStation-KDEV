# TGUI Guide

Generated 2026-05-21. The in-game UI framework — a DM backend talking to a React/TypeScript frontend. Read this before touching any `ui_interact` / interface code.

## Two Sides

| Side | Language | Location |
|---|---|---|
| Backend | DM | `code/modules/tgui/**` + the host datum's `ui_*` procs |
| Frontend | React / TypeScript | `tgui/packages/tgui/interfaces/**` |
| Subsystem | — | `SStgui` (`code/controllers/subsystem/tgui.dm`) — window + update management |

## Backend (DM)

Any datum can host a UI by implementing procs from `code/modules/tgui/external.dm`:

| Proc | Role |
|---|---|
| `ui_interact(mob/user, datum/tgui/ui)` | opens / re-uses the UI window |
| `ui_data(mob/user)` | dynamic state, sent every update |
| `ui_static_data(mob/user)` | constant data, sent once |
| `ui_act(action, list/params, ...)` | handles a frontend action — **the trust boundary** |
| `ui_state(mob/user)` / `ui_status(...)` | who may see/interact (`code/modules/tgui/states.dm`) |
| `ui_host`, `ui_assets` | UI owner atom, extra assets |

`ui_interact` typically does: `ui = SStgui.try_update_ui(user, src, ui_key, ui, ...)` then `ui = new(user, src, "InterfaceName", title)` and `ui.open()` — see `code/modules/tgui/tgui.dm`.

> The `"InterfaceName"` string passed to `/datum/tgui/New` **must exactly match** a `.tsx` filename in `tgui/packages/tgui/interfaces/`.

## Frontend (React)

| Package | Role |
|---|---|
| `tgui/packages/tgui` | framework + all interface components (`interfaces/**`) |
| `tgui/packages/tgui-panel` | the chat panel |
| `tgui/packages/tgui-say` | the say/radio input |
| `tgui/packages/common` | shared utilities |
| `tgui/packages/tgfont` | icon font |
| `tgui/packages/tgui-dev-server` | hot-reload dev server |

An interface is a `.tsx` file exporting a component; complex ones get a folder (e.g. `interfaces/Cargo/`). It reads `data` from `useBackend()` (the `ui_data` payload) and calls `act("action", params)` to invoke `ui_act`.

## Build Pipeline

- Package manager: **Bun**; bundler: **rspack** (`tgui/rspack.config.ts`).
- `tgui/package.json` scripts: `tgui:build`, `tgui:dev`, `tgui:test`, `tgui:tsc`.
- Output bundles land in `tgui/public/**` (`tgui.bundle.js`, etc.).
- The DM build (`BUILD.cmd` → `tools/build/`) runs the tgui build as a step. CI lints tgui with Biome (`biome.json`).

## Rules

- **Never trust `ui_act` params.** Validate type, range, and permission server-side — the client can send anything.
- Put unchanging data in `ui_static_data`, changing data in `ui_data`, to keep updates cheap.
- A new interface needs both: a `.tsx` in `interfaces/` and the matching DM `ui_interact`.
- After editing `.tsx`, the tgui bundle must be rebuilt for the change to appear in-game.
- Fork interfaces are often suffixed `220` (e.g. `CameraConsole220.tsx`, `Jukebox220.tsx`). UI-related modpacks: `modular_bandastation/{hud,nanomap,navigator,tgui_who,ticket_manager}`.

## Routing

- UI broken / blank / not updating → `ai_navigation/debug_routes.md` (TGUI rows).
- HUD screen objects (action buttons, alerts) are not TGUI — see `code/_onclick/hud/**`.
