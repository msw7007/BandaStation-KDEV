# CP13 HUD

Production assets used by `overrides/code/human_hud.dm`. Only this `cp13/`
directory is referenced by the game. The obsolete importer, legacy DMI/source
copies, and unused reference catalogues have been removed.

## Style

The source of the visual language is `.StyleGuide` in
`tgui/packages/tgui/styles/interfaces/CyberpunkPanel.scss`, with the client panel
theme in `tgui/packages/tgui-panel/styles/themes/cyberpunk.scss` as a cross-check:
near-black panels, cyan typography, one-pixel boundaries, and small clipped
corners. The supplied Cyberpunk 2077 screenshot further sets the visual hierarchy:
quiet crimson chrome, cyan hover/selection, red combat/danger. The HUD lowers
accent brightness for continuous gameplay use. There is no industrial texture
or baked-in glow.

Generated glyphs and native pixel frames are separate states/files. Text and
held/equipped item appearances are not darkened. Hover changes only the frame;
selected states use cyan and combat states stay red. Existing action buttons use
the same background scheme without replacing their action-specific art.

## Native Actions

The eight small cells beside the hands are the native listed-action group, not
manual copies or a second set of actions. Actions are inserted automatically,
removed when the source item/action is removed, and retain native clicks,
secondary activation, tooltips, key bindings, item overlays, and cooldowns.
Unoccupied cells show only their frame, without placeholder numbers.

Human action groups fit actual action art into 16 x 16 cells. The scale also
accounts for an item-action overlay's source dimensions. Centering is performed
in the transform matrix: BYOND screen objects ignore `pixel_x/y` for positioning.
Item overlays are composed with `KEEP_TOGETHER` before scaling, including items
that carry `RESET_TRANSFORM`. The frame uses `KEEP_APART | RESET_TRANSFORM` and
an explicit HUD plane/layer, preserving its native one-pixel outline at the slot
origin. Glyph controls (hands, movement, equipment toggles, utility buttons)
instead own a registered frame-only screen object behind the glyph. It shares
the control's screen coordinates and HUD visibility group, ignores mouse input,
and is deleted with the control. Empty inventory cells retain their existing
frame-only path. The helper's `in` membership expression must remain parenthesized:
DM otherwise assigns the resource itself to the flag and mistakes glyph files
for frame files, clearing the button icon. The regression test checks actual hand
icon resources/states after repeated inventory updates, not just frame registration.
The human screen factory publishes the HUD only after skinning and registering
the frame, including crafting controls added by the HUD-created signal.
Updates use the existing action
overlay signal; there is no per-tick HUD polling. Other mob HUD groups are not
replaced. Stored custom floating positions remain respected.

The first eight listed actions occupy the lower cells. Listed overflow and
actions deliberately placed in the palette appear in a paged drawer above the
hands, opened with right-click on Memories. The drawer also opens when only
listed overflow exists. Closing it does not remove actions or disable keybinds.

## Files

| File | Width x Height | Purpose |
| --- | --- | --- |
| `glyphs_16x16.dmi` | 16 x 16 | Utility/action glyphs and native flick/throw aliases |
| `glyphs_32x32.dmi` | 32 x 32 | Equipment, underwear, modules, large journal |
| `movement_32x16.dmi` | 32 x 16 | Walk, run, rest; human/anthro state contracts retained |
| `floor_16x32.dmi` | 16 x 32 | Up/down glyphs with the native 16-pixel vertical click split |
| `hands_32x32.dmi` | 32 x 32 | Native hand glyphs and independent selected-hand outlines |
| `frames_16x16.dmi` | 16 x 16 | Small control states |
| `frames_32x16.dmi` | 32 x 16 | Wide control states |
| `frames_32x32.dmi` | 32 x 32 | Inventory/action backgrounds, scroll/landing compatibility |
| `frames_16x32.dmi` | 16 x 32 | Buff/debuff states and separate stacked floor frames |

Every DMI state is also exported to `native/<dmi name>/<state>.png` at its real
size with transparency and is used by the offline regression tests. An optional
`catalogue.png` can be generated with the builder's `--preview` flag; the normal
build does not produce this unused reference image.

## Sources And Prompts

`sources/` contains the selected image-generation outputs and the six native
trial PNGs. `manifest.json` records their hashes, palette, style references, and
the actual states read back from each DMI. No project asset depends on an image
stored only in the Codex image cache.

The built-in image generator was used. Common prompt constraints: one isolated
flat glyph, muted cyan-gray, transparent or pure-black extraction background,
no frame/text/glow/texture/shadow, broad negative spaces for native 16-pixel use.
Subject prompts:

- Language: angular speech balloon with two broad message slits.
- Craft: one open-ended wrench with a large fork opening.
- Navigation: two-part diagonal compass needle, cyan/crimson.
- Area creation: four floor tiles, clear gutters, one create marker.
- Emotes: clipped-corner face with square eyes and a broad smile cutout.
- Resist: two angular chain links with a central break.
- Run: complete leaning running human silhouette with separated limbs.
- Rest: horizontal lying human, separate head/neck, no bed or ground line.
- Underwear: sleeveless tank top, two straps and a broad neck opening.
- Equipment/journal/swap/walk: cropped from the selected earlier style board.
- Throw/drop: separately generated simplified hand silhouettes from the trial.

The builder flattens shading/fringes to a fixed palette, fits with nearest
sampling, removes detached single-pixel fringe, and makes explicit one-pixel
gutter/spine corrections. Up/down use a corrected symmetric native-pixel head
and straight two-pixel stem, not a rotated fragment of the swap glyph. It does not
draw replacement hand/body silhouettes. Frames are rasterized directly from
the existing CSS geometry. Humanoid movement shares a neutral silhouette;
the two species-state sets are aliases, not changes to species mechanics.

## Rebuild And Verify

From the repository root:

```powershell
python modular_bandastation/cyberpunk_modular/cyberpunk/tools/build_cp13_hud.py
python modular_bandastation/cyberpunk_modular/cyberpunk/tools/test_cp13_hud.py
```

The checked-in sources are sufficient; generation/network access is not needed.
The asset builder uses Python with Pillow and NumPy, plus the repository's DMI
writer. It is an offline authoring tool, not a game-server dependency.
The builder reopens all DMI files and checks exact RGBA round trips, dimensions,
state names, frame counts, and directions. A UNIT_TESTS-only DM regression in the
HUD module covers registered control frames and visibility groups, native action insertion/removal, matrix
centering, 64-pixel fitting, and listed overflow. Compile the game separately. Do not
infer runtime/UI verification from a successful asset build or DM compilation.

Body targeting, health/pulse art, gameplay timing, equipment mechanics, and the
approved HUD anchors are not replaced by this asset pass.
