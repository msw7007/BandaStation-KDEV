# CP13 HUD

Production assets used by `overrides/code/human_hud.dm`. Only this `cp13/`
directory is referenced by the game. The obsolete importer, legacy DMI/source
copies, and unused reference catalogues have been removed.

## Style

The visual base is TG's default Midnight HUD, `icons/hud/screen_midnight.dmi`:
filled pixel sprites, broad shaded planes, recognizable silhouettes and dark
edges. Cyberpunk details add palm plates, a wrist coupler, reinforced clothing
and a wrist module without replacing that construction with wireframe icons.
The existing clipped frames retain their geometry from the TGUI CyberpunkPanel
StyleGuide and the restrained crimson/cyan state hierarchy.

Empty slots must be barely visible. The fourteen stock TG purpose sprites retain
their exact native pixel masks and tonal ordering, without enlargement or a bright
outline. Their five original ink levels are mapped to `#0d1217`, `#10171d`,
`#141d24`, `#18232b`, `#1c2932`. Additional CP13 slots use the same dim filled
construction, dark seams and broad planes. Real equipped items hide these markers
and retain their own appearance. Frame opacity remains unchanged.

Working controls are more visible than empty slots. Their common five-ink ramp is
`#17222b`, `#2c3e4d`, `#445a6c`, `#5f798c`, `#8198aa`. The perimeter is a shadow,
not a continuous pale rim. Language, crafting, navigation, area creation and
memories use the original TG controls. Resist uses the TG handcuff item sprite.
Remaining native controls use the same lit upper face and dark lower edge.
Combat/active aliases retain this shading in a muted red ramp.

Empty hands use the same dim five-ink ramp as pockets and other empty slots.
Only the hand backplate is darkened; held items and the selected-hand border retain
their normal appearance. The hand uses a filled palm, restrained knuckle/palm plates and a wrist coupler.
Thumbs face the center; the short little-finger edge is compact. It has no split
through the palm or wrist. Equipment, accessories and underwear retain their
recognizable filled artwork and use the same material ramp. Walking also follows
that ramp. RUN, REST and FIGHT are native square pixel lettering with a lit face
and a dark offset edge; no italic shear, system font or maptext is used.

The limit is five opaque colors per individual image, not across the entire set.
Final glyph alpha is binary. No glow, blended edge, dithering or microtexture is
allowed. Inventory/control anchors stay fixed. Action cards are 24x16 and status
cards are 24x32, both with two-pixel gutters. Review
at native 1x and the client's usual 2x scale; enlarged source artwork is not proof
of in-game readability. Rejected variants and temporary review files are not
part of the source assets.

## Native Actions

The eight small cells beside the hands are the native listed-action group, not
manual copies or a second set of actions. Actions are inserted automatically,
removed when the source item/action is removed, and retain native clicks,
secondary activation, tooltips, key bindings, item overlays, and cooldowns.
No action means no button or placeholder frame. The old eight permanent quick-slot
objects have been removed; the native action group owns every visible action card.

Human action groups fit actual action art into the 16-pixel height of 24x16 cards,
centering it horizontally without stretching. Two-pixel gutters separate cards;
the two groups extend outward from the pockets without moving the inventory. The scale also
accounts for an item-action overlay's source dimensions. Centering is performed
in the transform matrix: BYOND screen objects ignore `pixel_x/y` for positioning.
Item overlays are composed with `KEEP_TOGETHER` before scaling, including items
that carry `RESET_TRANSFORM`. The frame uses `KEEP_APART | RESET_TRANSFORM` and
an explicit HUD plane/layer, preserving its native one-pixel outline at the slot
origin. Glyph controls (hands, movement, equipment toggles, utility buttons)
instead own a registered frame-only screen object behind the glyph. It shares
the control's screen coordinates and HUD visibility group, ignores mouse input,
and is deleted with the control. Inventory cells also use these registered frames.
Every empty slot has a purpose silhouette; occupied cells select a fully transparent
glyph state and display the real item via the existing `vis_contents` path. The
frame is retained across equip/unequip. Optional underwear slots hide/show both
the control and its frame. The helper's `in` membership expression must remain parenthesized:
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

## Status Cards

The old CBT sample counters have been removed. The human HUD creates cards only
for actual native buff/debuff alerts, with up to eight cards in each row. Cards
are 24x32 (50% wider than the old samples), with a 26-pixel horizontal stride.
Buffs grow right from the top-left corner; debuffs grow left from the top-right.
Native alert creation/removal and HUD refresh drive synchronization. Icon-update
and deletion signals refresh or remove each card; no processing loop is added.

Cards use the real alert artwork and tooltip text. Hover reads remaining duration
from the linked effect, and clicks are forwarded to the native alert for its owner.
HUD hiding and observers use the same visibility rules as native alerts. A static
presentation-only type map identifies known positive/negative alerts; neutral or
unclassified alerts, and overflow beyond eight, retain ordinary alert placement.
No status-effect gameplay, duration, application or removal behavior is changed.

## Files

| File | Width x Height | Purpose |
| --- | --- | --- |
| `glyphs_16x16.dmi` | 16 x 16 | Utility/action glyphs and native flick/throw aliases |
| `glyphs_32x32.dmi` | 32 x 32 | Equipment, underwear, modules, large journal |
| `movement_32x16.dmi` | 32 x 16 | Walk silhouette, drawn RUN/REST/FIGHT; human/anthro aliases and fight states |
| `floor_16x32.dmi` | 16 x 32 | Up/down glyphs with the native 16-pixel vertical click split |
| `hands_32x32.dmi` | 32 x 32 | Mirrored filled hand glyphs and independent selected-hand outlines |
| `inventory_32x32.dmi` | 32 x 32 | Twenty dim purpose silhouettes plus a transparent occupied state |
| `frames_16x16.dmi` | 16 x 16 | Small control states |
| `frames_32x16.dmi` | 32 x 16 | Wide control states |
| `frames_32x32.dmi` | 32 x 32 | Inventory/action backgrounds, scroll/landing compatibility |
| `frames_16x32.dmi` | 16 x 32 | Buff/debuff states and separate stacked floor frames |
| `frames_24x16.dmi` | 24 x 16 | Real action cards, without empty placeholders |
| `frames_24x32.dmi` | 24 x 32 | Real buff/debuff cards |

The DMI files contain all runtime frames; duplicate per-state PNGs are not kept
in the repository. Offline tests check each frame against its RGBA checksum in
`manifest.json`. Optional `--export-pngs` and `--preview` flags write individual
frames and a catalogue to the ignored `build/cp13-hud/` directory. The normal
build creates neither.

## Sources And Prompts

`sources/contour/inventory_base.dmi` is the preserved TG Midnight HUD source.
The builder extracts its purpose sprites and controls while excluding the stock
frame. `tg/handcuff.png` is the unmodified handcuff state from
`icons/obj/weapons/restraints.dmi`.

`grid.json` selects the large artwork and its native footprint. Current hand art
is `palette/hand_tg.png`; `palette/hand_tg_generation.json` stores its built-in
ImageGen prompt and references. Its style reference is the actual TG sprite sheet.
Hands map the same source tonal levels into the dim inventory ramp. Equipment,
accessories, underwear and walking retain their prior generated source
images, now reduced with the TG material ramp and dark perimeter. Original prompts
are in `palette/generation.json` and the parent `generation.json`.

`lettering.json` holds the drawn native capitals used for RUN, REST and FIGHT.
The builder adds their shaded faces directly on the target grid. Only current
source images and their generation prompts are retained. The four small contour
sources supply swap, throw, drop and sleep masks, with TG shading applied afterward.

`manifest.json` records source hashes, current palettes and DMI states. All project
inputs are saved in the repository; generation/network access is not required to
rebuild. State names, frame counts, directions and RGBA checksums are verified
against the reopened DMI files. Frame palettes and their alpha are independent of the
five-color glyph budget.

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
centering, 64-pixel fitting, listed overflow, empty-action removal, pocket gutters,
8+8 live status cards, source deletion and overflow promotion. Compile the game separately. Do not
infer runtime/UI verification from a successful asset build or DM compilation.

Body targeting, health/pulse art, gameplay timing, equipment mechanics, and the
approved HUD anchors are not replaced by this asset pass.
