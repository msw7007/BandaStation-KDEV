# Visuals Guide

Generated 2026-05-21. Routing for the rendering systems — layers, planes, overlays, lighting, filters, appearance, icon smoothing. Read this before touching anything visual; rendering bugs rarely sit where they appear.

## Quick Reference

| Topic | Key file(s) | Runtime owner |
|---|---|---|
| Layers & planes | `code/__DEFINES/layers.dm` | — |
| Overlays / underlays | `code/controllers/subsystem/overlays.dm` | `SSoverlays` |
| `vis_contents` overlays | `code/controllers/subsystem/vis_overlays.dm` | `SSvis_overlays` |
| Lighting | `code/modules/lighting/**` | `SSlighting` |
| Icon smoothing | `code/controllers/subsystem/icon_smooth.dm` | `SSicon_smooth` |
| Parallax background | `code/controllers/subsystem/parallax.dm` | `SSparallax` |
| Greyscale recolouring | `code/controllers/subsystem/processing/greyscale.dm` | `SSgreyscale` |

## Layers & Planes

- **Layer** orders atoms within a plane; **plane** is a separate render group, composited in plane order.
- Defines (layer constants, plane constants) live in `code/__DEFINES/layers.dm`.
- If something renders behind/in front of the wrong thing, it is almost always a layer or plane value — not the icon.

## Overlays & Underlays

- Use the managed helpers `add_overlay()` / `cut_overlay()` / `cut_overlays()` — do not assign the raw `overlays` list directly.
- Overlay compositing is deferred and batched through `SSoverlays`.
- An `appearance` is immutable and cached; every overlay change builds a new appearance — heavy per-tick overlay churn is a real cost (`ai_navigation/engine_limits.md`).
- `vis_contents` (one atom rendered inside another) is managed via `SSvis_overlays` for pooled overlays.

## Lighting

- Lighting is its own object/corner system under `code/modules/lighting/**`, updated by `SSlighting`.
- Light emitters use a light component/datum; do not hand-edit lighting overlays.

## Icon Smoothing

- Bitmask smoothing (walls, floors, tables) is driven by `smoothing_flags` and `smoothing_groups` on the atom.
- Recalculation is deferred to `SSicon_smooth`.
- A wall/floor that does not connect to neighbours = wrong `smoothing_flags` / `smoothing_groups`, not a bad sprite.

## Filters & Animation

- `filter` effects (blur, outline, ripple, etc.) are added with the `add_filter()` / `remove_filter()` helpers.
- `animate()` drives smooth transitions; chained `animate()` calls queue.
- Render relays / `render_target` / `render_source` link an atom's render onto another surface — used for screen effects.

## Routing

- A visual bug → check, in order: layer/plane → overlay (managed?) → appearance churn → lighting → smoothing.
- Recolourable sprites → `SSgreyscale` and the greyscale config.
- Performance of visual code → `ai_navigation/engine_limits.md`, `ai_navigation/processing_hazards.md`.
- Confirm current proc/var names with `rg` — rendering APIs are easy to misremember:

```
rg -n "/proc/add_overlay\(|/proc/cut_overlay" code/game -g "*.dm"
rg -n "smoothing_flags|smoothing_groups" code/game -g "*.dm"
rg -n "/proc/add_filter\(" code -g "*.dm"
```
