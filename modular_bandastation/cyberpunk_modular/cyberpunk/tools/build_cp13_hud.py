"""Build native CP13 HUD states from project art, pixel lettering and TGUI frames."""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = next(path for path in Path(__file__).resolve().parents if (path / "tgstation.dme").is_file())
sys.path.insert(0, str(ROOT))
from tools.dmi import Dmi

OUTPUT = Path(__file__).resolve().parents[1] / "icons/hud/cp13"
REVIEW_OUTPUT = ROOT / "build/cp13-hud"
GLYPH = (155, 191, 201, 255)
ACCENT = (190, 72, 91, 255)
UTILITY = (118, 151, 163, 255)
SLOT_PALETTE = ((13,18,23,255), (16,23,29,255), (20,29,36,255), (24,35,43,255), (28,41,50,255))
TG_PALETTE = ((23,34,43,255), (44,62,77,255), (68,90,108,255), (95,121,140,255), (129,152,170,255))
COMBAT_PALETTE = ((36,15,24,255),(65,26,38,255),(109,43,58,255),(156,62,79,255),(190,84,100,255))
HAND_PALETTE = (*SLOT_PALETTE[:4], SLOT_PALETTE[3])  # Pockets do not use the fifth highlight.
GLYPH_PALETTE = (
    (28, 53, 64, 255),    # quiet surface
    (66, 97, 110, 255),   # broad structural planes
    (109, 144, 156, 255), # secondary divisions
    GLYPH,               # one-pixel silhouette boundary
    ACCENT,              # active/combat states only
)


def write_dmi(output, name, size, frames):
    dmi = Dmi(*size)
    for state, image in frames.items():
        dmi.state(state).frame(image)
    target = output / f"{name}.dmi"
    dmi.to_file(target)
    reopened = Dmi.from_file(target)
    assert (reopened.width, reopened.height) == size
    assert [state.name for state in reopened.states] == list(frames)
    for state in reopened.states:
        assert state.framecount == 1 and state.dirs == 1
        assert state.get_frame().tobytes() == frames[state.name].tobytes(), state.name


def contour_glyph(source_dir, settings):
    """Fit the selected generated contour without losing thin native-pixel strokes."""
    if settings.get("render") == "palette":
        return palette_glyph(source_dir, settings)
    pixels = np.asarray(Image.open(source_dir / settings["source"]).convert("RGBA"), dtype=np.int16)
    r, g, b, a = (pixels[:, :, i] for i in range(4))
    cyan = (a >= 200) & (r >= 60) & (g-r >= 8) & (b-r >= 8) & (g-r < 100)
    coverage = Image.fromarray((cyan * 255).astype(np.uint8))
    if not coverage.getbbox():
        raise ValueError(f"No usable cyan contour in {settings['source']}")
    coverage = coverage.crop(coverage.getbbox())
    canvas = tuple(settings["canvas"])
    width, height = settings["width"], settings["height"]
    sx, sy = coverage.width/width, coverage.height/height
    padx, pady = int(canvas[0]*sx), int(canvas[1]*sy)
    padded = Image.new("L", (coverage.width+2*padx, coverage.height+2*pady))
    padded.paste(coverage, (padx, pady))
    box = (padx-((canvas[0]-width)/2+settings["dx"])*sx,
           pady-((canvas[1]-height)/2+settings["dy"])*sy)
    box += (box[0]+canvas[0]*sx, box[1]+canvas[1]*sy)
    sampled = np.asarray(padded.resize(canvas, Image.Resampling.BOX, box=box))
    mask = sampled >= settings["threshold"]
    if not mask.any() or mask[0].any() or mask[-1].any() or mask[:, 0].any() or mask[:, -1].any():
        raise ValueError(f"Contour must leave a transparent margin: {settings['source']}")
    result = np.zeros((canvas[1], canvas[0], 4), dtype=np.uint8)
    result[mask] = UTILITY if canvas == (16,16) else GLYPH
    return Image.fromarray(result)


def palette_glyph(source_dir, settings):
    """Reduce sparse source planes to exact inks and an opaque native-pixel edge."""
    pixels = np.asarray(Image.open(source_dir / settings["source"]).convert("RGBA"), dtype=np.int16)
    r, g, b, a = (pixels[:, :, i] for i in range(4))
    cyan = (a >= 224) & (r >= 12) & (g-r >= 4) & (b-r >= 8) & (g-r < 110)
    body = cyan
    bbox = Image.fromarray(body.astype(np.uint8)*255).getbbox()
    if not bbox:
        raise ValueError(f"No usable artwork in {settings['source']}")
    canvas, size = tuple(settings["canvas"]), tuple(settings["size"])
    if any(content <= 0 or content > cell-2 for content, cell in zip(size, canvas)):
        raise ValueError(f"Artwork must leave a transparent margin: {settings['source']}")

    def sample(values):
        image = Image.fromarray(values.astype(np.uint8)).crop(bbox).resize(size, Image.Resampling.BOX)
        return np.asarray(image, dtype=float)

    coverage = sample(body*255)/255
    occupied = coverage >= settings.get("coverage_threshold", .45)
    tone = sample(np.where(body, g, 0))/np.maximum(coverage, 1/255) + settings.get("tone_bias", 0)
    # Quantize after reduction: never leave blended colors, alpha fringes or dither.
    tg_material = settings.get("ink_palette") in ("tg", "hand")
    ink = np.digitize(tone, (39, 70, 104, 137) if tg_material else (73, 113))
    padded = np.pad(occupied, 1)
    interior = (padded[1:-1, :-2] & padded[1:-1, 2:]
                & padded[:-2, 1:-1] & padded[2:, 1:-1])
    ink[occupied & ~interior] = settings.get("boundary_ink", 0 if tg_material else 3)
    rgba = np.zeros((size[1], size[0], 4), dtype=np.uint8)
    palette = HAND_PALETTE if settings.get("ink_palette") == "hand" else TG_PALETTE if tg_material else GLYPH_PALETTE
    rgba[occupied] = np.asarray(palette, dtype=np.uint8)[ink[occupied]]
    result = Image.new("RGBA", canvas)
    result.alpha_composite(Image.fromarray(rgba), ((canvas[0]-size[0])//2, (canvas[1]-size[1])//2))
    return result


def fit(image, size, bounds=None):
    bounds = bounds or (size[0]-4, size[1]-4)
    ratio = min(bounds[0]/image.width, bounds[1]/image.height)
    resized = image.resize((max(1, round(image.width*ratio)), max(1, round(image.height*ratio))), Image.Resampling.NEAREST)
    result = Image.new("RGBA", size)
    result.paste(resized, ((size[0]-resized.width)//2, (size[1]-resized.height)//2))
    return result


def clean_pixels(image):
    """Drop detached one-pixel fringe without rounding connected stair-steps."""
    pixels = np.array(image)
    occupied = pixels[:,:,3] > 0
    padded = np.pad(occupied, 1)
    neighbors = np.zeros(occupied.shape, dtype=np.uint8)
    for dy in range(3):
        for dx in range(3):
            if dx != 1 or dy != 1:
                neighbors += padded[dy:dy+image.height,dx:dx+image.width]
    pixels[occupied & (neighbors == 0)] = (0,0,0,0)
    return Image.fromarray(pixels)


def vertical_arrow():
    """Native 16-pixel correction: symmetric head, straight two-pixel stem."""
    image = Image.new("RGBA", (16,16))
    rows = {3: range(7,9), 4: range(6,10), 5: range(5,11), 6: range(4,12)}
    rows.update({y: range(7,9) for y in range(7,13)})
    for y, xs in rows.items():
        for x in xs:
            image.putpixel((x,y), TG_PALETTE[4 if y <= 4 else 3 if y <= 6 else 2])
    return image


def wordmark(text, lettering, color=GLYPH):
    """Native square lettering with the same shadow and lit face as TG sprites."""
    letters = [lettering["letters"][character] for character in text]
    spacing = lettering["spacing"]
    width = sum(len(rows[0]) for rows in letters) + spacing*(len(letters)-1)
    height = len(letters[0])
    if width > 30 or height > 14:
        raise ValueError(f"Wordmark must leave a transparent margin: {text}")
    mask = Image.new("L", (32,16))
    x, top = (32-width)//2, (16-height)//2
    for rows in letters:
        if len(rows) != height or any(len(row) != len(rows[0]) for row in rows):
            raise ValueError(f"Inconsistent lettering grid: {text}")
        for y, row in enumerate(rows):
            for dx, pixel in enumerate(row):
                if pixel == "1":
                    mask.putpixel((x+dx, top+y), 255)
        x += len(rows[0]) + spacing
    inks = TG_PALETTE if color != ACCENT else COMBAT_PALETTE
    return relief(mask, inks)


def relief(mask, inks=TG_PALETTE):
    """Give a native filled pixel mask a dark lower edge and an upper lit face."""
    occupied = np.asarray(mask) > 0
    above = np.zeros_like(occupied)
    above[1:] = occupied[:-1]
    image = np.zeros((*occupied.shape,4), dtype=np.uint8)
    shadow = np.zeros_like(occupied)
    shadow[1:,1:] = occupied[:-1,:-1]
    image[shadow] = inks[0]
    image[occupied] = inks[2]
    image[occupied & ~above] = inks[4]
    return Image.fromarray(image)


def tg_extract(image, palette=TG_PALETTE, include_shadows=False):
    """Keep TG glyph pixels and their tonal ordering; discard the stock frame."""
    p = np.asarray(image.convert("RGBA"), dtype=np.int16)
    r,g,b,a = (p[:,:,i] for i in range(4))
    mask = (a > 0) & (g-r >= 8) & (b-r >= 16)
    if include_shadows:
        mask |= (a == 255)
    tones = np.digitize(g, (85,99,114,145))
    out = np.zeros(p.shape, dtype=np.uint8)
    out[mask] = np.asarray(palette, dtype=np.uint8)[tones[mask]]
    return Image.fromarray(out)


def center_native(image, canvas):
    image = image.crop(image.getbbox())
    if image.width > canvas[0]-2 or image.height > canvas[1]-2:
        return fit(image, canvas, (canvas[0]-2,canvas[1]-2))
    out = Image.new("RGBA", canvas)
    out.paste(image, ((canvas[0]-image.width)//2,(canvas[1]-image.height)//2))
    return out


def tg_item(image, canvas, palette=TG_PALETTE):
    """Recolour an original filled TG item sprite without tracing its outline."""
    image = center_native(image.convert("RGBA"), canvas)
    p = np.asarray(image,dtype=np.int16)
    values = p[:,:,:3].mean(axis=2)
    visible = p[:,:,3] >= 128
    low,high = np.percentile(values[visible], (5,95))
    tones = np.clip(((values-low)/max(1,high-low)*4).round(),0,4).astype(int)
    out = np.zeros(p.shape,dtype=np.uint8)
    out[visible] = np.asarray(palette,dtype=np.uint8)[tones[visible]]
    return Image.fromarray(out)


def combat_tint(image):
    pixels = np.array(image)
    visible = pixels[:,:,3] > 0
    tones = np.digitize(pixels[:,:,1], (48,76,106,137))
    pixels[visible] = np.asarray(COMBAT_PALETTE,dtype=np.uint8)[tones[visible]]
    return Image.fromarray(pixels)


def frame_axis(original, target):
    """Resize the middle of a frame and preserve its corners at native size."""
    edge = 5
    middle = np.linspace(edge, original - edge - 1, target - 2 * edge)
    return np.r_[np.arange(edge), middle.round().astype(int), np.arange(original - edge, original)]


def frame(art, size, state, outline_only=False):
    """Use the supplied UI frame and keep hover, active and disabled distinct."""
    width, height = size
    tile = 16 if min(size) == 16 else 32
    source = art[tile, state == "combat"]
    pixels = np.array(source)[np.ix_(frame_axis(tile, height), frame_axis(tile, width))]
    cut = 2 if min(size) == 16 else 3
    palette = {
        "hover": ((24, 34, 42), (88, 151, 173)),
        "active": ((23, 39, 49), (106, 218, 234)),
        "disabled": ((14, 17, 23), (63, 66, 77)),
    }
    if state in palette:
        dark, light = map(np.array, palette[state])
        intensity = np.clip((pixels[:, :, :1].astype(float) - 28) / 227, 0, 1)
        pixels[:, :, :3] = (dark + intensity * (light - dark)).round()
    if outline_only:
        pixels[cut+1:-(cut+1), cut+1:-(cut+1), 3] = 0
    return Image.fromarray(pixels)


def compose(frame_image, glyph):
    image = frame_image.copy()
    image.alpha_composite(glyph)
    return image


def inventory_glyphs(source_dir):
    """Keep familiar inventory silhouettes, independently of frames and items."""
    source = Dmi.from_file(source_dir / "inventory_base.dmi")
    states = {s.name: s.get_frame().convert("RGBA") for s in source.states}
    glyphs = {}
    for name in ("uniform", "suit", "back", "id", "belt", "mask", "glasses", "ears", "head", "suit_storage", "pocket", "gloves", "shoes", "neck"):
        glyphs[name] = tg_extract(states[name], SLOT_PALETTE)

    # Native CP13-only slots have no corresponding core HUD silhouette.
    shapes = {
        "pants": [(9,5),(22,5),(24,27),(17,27),(16,16),(14,27),(7,27)],
        "undershirt": [(10,5),(13,5),(13,10),(18,10),(18,5),(21,5),(23,14),(21,18),(22,27),(9,27),(10,18),(8,14)],
        "underwear": [(7,9),(24,9),(23,16),(19,22),(12,22),(8,16)],
        "tights": [(10,4),(21,4),(22,24),(26,25),(26,28),(19,28),(16,14),(14,27),(6,27),(6,24),(10,23)],
        "shoulder_left": [(5,11),(9,7),(21,7),(26,12),(24,21),(17,23),(8,20)],
    }
    for name, points in shapes.items():
        mask = Image.new("L", (32,32))
        ImageDraw.Draw(mask).polygon(points, fill=255)
        image = relief(mask, SLOT_PALETTE)
        draw = ImageDraw.Draw(image)
        # Broad shaded material and dark seams, like TG's filled slot sprites.
        interior = np.array(image)
        occupied = np.asarray(mask) > 0
        rows, cols = np.indices(occupied.shape)
        interior[occupied & (cols < 14) & (rows > 9)] = SLOT_PALETTE[1]
        image = Image.fromarray(interior)
        draw = ImageDraw.Draw(image)
        if name in ("pants", "underwear", "tights"):
            draw.line((10 if name != "underwear" else 8, 9 if name != "tights" else 8, 21 if name != "underwear" else 23, 9 if name != "tights" else 8), fill=SLOT_PALETTE[1])
        if name == "shoulder_left":
            draw.line([(9,12),(20,12),(23,15)], fill=SLOT_PALETTE[1])
        glyphs[name] = image
    glyphs["shoulder_right"] = glyphs["shoulder_left"].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    glyphs["occupied"] = Image.new("RGBA", (32,32))
    return glyphs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", action="store_true", help="Write a reference catalogue under build/cp13-hud")
    parser.add_argument("--export-pngs", action="store_true", help="Export individual states under build/cp13-hud/native")
    args = parser.parse_args()
    source_dir = OUTPUT / "sources" / "contour"
    ui_sheet = Dmi.from_file(source_dir / "ui.dmi")
    # The artist's sheet has repeated state names. Use its authored cell order.
    frame_art = {
        (16, False): ui_sheet.states[22].get_frame().crop((8, 8, 24, 24)),
        (16, True): ui_sheet.states[15].get_frame().crop((8, 8, 24, 24)),
        (32, False): ui_sheet.states[21].get_frame(),
        (32, True): ui_sheet.states[5].get_frame(),
    }
    settings = json.loads((source_dir / "grid.json").read_text(encoding="utf-8"))
    contours = {name: contour_glyph(source_dir, spec) for name, spec in settings.items()}
    glyphs = dict.fromkeys((
        "language", "craft", "navigate", "area_create", "emote", "resist",
        "swap", "throw", "drop", "memories", "sleep",
    ))
    glyphs.update({name: contours[name] for name in ("swap", "throw", "drop", "sleep")})
    tg_states = {s.name:s.get_frame() for s in Dmi.from_file(source_dir / "inventory_base.dmi").states}
    for name, state in (("language","talk_wheel"),("craft","craft"),("navigate","navigate"),("area_create","area_edit"),("memories","memories")):
        glyphs[name] = center_native(tg_extract(tg_states[state], include_shadows=True), (16,16))
    for name in ("swap","throw","drop","sleep"):
        glyphs[name] = relief(glyphs[name].getchannel("A"))
    glyphs["resist"] = tg_item(Image.open(source_dir / "tg/handcuff.png"), (16,16))
    # A filled expression tile retains the familiar face instead of a wire icon.
    face = Image.new("L", (16,16))
    ImageDraw.Draw(face).polygon([(5,3),(10,3),(12,5),(12,10),(10,12),(5,12),(3,10),(3,5)], fill=255)
    glyphs["emote"] = relief(face)
    face_draw = ImageDraw.Draw(glyphs["emote"])
    face_draw.line((5,6,6,6), fill=TG_PALETTE[0])
    face_draw.line((9,6,10,6), fill=TG_PALETTE[0])
    face_draw.line([(5,9),(6,10),(9,10),(10,9)], fill=TG_PALETTE[0])
    glyphs["throw_combat"] = combat_tint(glyphs["throw"])
    glyphs["act_throw"] = glyphs["throw"].copy()
    glyphs["act_throw_on"] = glyphs["throw_combat"].copy()
    for alias, original in (("act_resist_on", "resist"), ("act_sleep_flick", "sleep")):
        glyphs[alias] = combat_tint(glyphs[original])
    glyphs = {name: clean_pixels(image) for name, image in glyphs.items()}
    glyphs["arrow_up"] = vertical_arrow()
    glyphs["arrow_down"] = glyphs["arrow_up"].transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    write_dmi(OUTPUT, "glyphs_16x16", (16,16), glyphs)

    large = {name: contours[name] for name in ("equipment", "underwear", "accessories")}
    large["memories"] = center_native(tg_extract(tg_states["memories"], include_shadows=True), (32,32))
    write_dmi(OUTPUT, "glyphs_32x32", (32,32), large)

    inventory = inventory_glyphs(source_dir)
    write_dmi(OUTPUT, "inventory_32x32", (32,32), inventory)

    movement = {}
    lettering = json.loads((source_dir / "lettering.json").read_text(encoding="utf-8"))
    poses = {"walk": contours["walk"], "run": wordmark("RUN", lettering), "rest": wordmark("REST", lettering)}
    for body in ("human", "anthro"):
        for pose, image in poses.items():
            movement[f"{pose}_{body}"] = image.copy()
    movement["fight"] = wordmark("FIGHT", lettering, ACCENT)
    movement["fight_active"] = wordmark("FIGHT", lettering)
    write_dmi(OUTPUT, "movement_32x16", (32,16), movement)

    frames = {}
    for size in ((16,16), (32,16), (32,32), (16,32), (24,16), (24,32)):
        states = {key: frame(frame_art, size, key) for key in ("idle", "hover", "active", "combat", "disabled")}
        states.update({"outline": states["idle"].copy(), "grid": states["idle"].copy()})
        if size in ((16,32), (24,32)):
            states["buff"] = states["hover"].copy()
            states["debuff"] = states["combat"].copy()
        if size == (16,32):
            states["split"] = Image.new("RGBA", size)
            states["split"].alpha_composite(frames[(16,16)]["idle"], (0,0))
            states["split"].alpha_composite(frames[(16,16)]["idle"], (0,16))
        frames[size] = states
        write_dmi(OUTPUT, f"frames_{size[0]}x{size[1]}", size, states)

    up = glyphs["arrow_up"]
    down = glyphs["arrow_down"]
    floor = Image.new("RGBA", (16,32))
    floor.alpha_composite(down, (0,16))
    floor.alpha_composite(up, (0,0))
    # DM's y-axis starts at the bottom, so the top image is the UP region.
    write_dmi(OUTPUT, "floor_16x32", (16,32), {"floor_change_v": floor})
    frames[(32,32)]["reserved"] = frames[(32,32)]["hover"].copy()
    frames[(32,32)]["scroll_up"] = compose(frames[(32,32)]["idle"], fit(up.crop(up.getbbox()), (32,32), (10,14)))
    frames[(32,32)]["scroll_down"] = compose(frames[(32,32)]["idle"], fit(down.crop(down.getbbox()), (32,32), (10,14)))
    write_dmi(OUTPUT, "frames_32x32", (32,32), frames[(32,32)])

    hands = {}
    for side in ("l", "r"):
        hands[f"hand_{side}"] = contours["hand"].transpose(Image.Transpose.FLIP_LEFT_RIGHT) if side == "l" else contours["hand"].copy()
        hands[f"{side}handactive"] = frame(frame_art, (32,32), "active", outline_only=True)
    write_dmi(OUTPUT, "hands_32x32", (32,32), hands)

    all_sets = {"glyphs_16x16": glyphs, "glyphs_32x32": large, "movement_32x16": movement, "hands_32x32": hands, "floor_16x32": {"floor_change_v": floor}}
    all_sets["inventory_32x32"] = inventory
    all_sets.update({f"frames_{size[0]}x{size[1]}": states for size, states in frames.items()})
    entries = []
    for group, states in all_sets.items():
        if args.export_pngs:
            group_dir = REVIEW_OUTPUT / "native" / group
            group_dir.mkdir(parents=True, exist_ok=True)
        for state, image in states.items():
            if args.export_pngs:
                image.save(group_dir / f"{state}.png")
            if not group.startswith("frames_"):
                entries.append((state, image))
    entries.extend((f"frame_{w}x{h}_{state}", states[state]) for (w,h), states in frames.items() for state in ("idle", "hover", "active"))
    if args.preview:
        REVIEW_OUTPUT.mkdir(parents=True, exist_ok=True)
        font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 14)
        preview = Image.new("RGB", (960, ((len(entries)+5)//6)*148+50), "#05080d")
        draw = ImageDraw.Draw(preview)
        draw.text((16,12), "CP13 / native DMI states / enlarged 3x, nearest", font=font, fill="#91b8c2")
        for index, (name, image) in enumerate(entries):
            x, y = (index%6)*160+12, (index//6)*148+52
            draw.text((x,y), name, font=font, fill="#91b8c2")
            draw.text((x,y+19), f"{image.width}x{image.height}", font=font, fill="#78909a")
            preview.paste(image.resize((image.width*3, image.height*3), Image.Resampling.NEAREST), (x+24,y+40), image.resize((image.width*3,image.height*3), Image.Resampling.NEAREST))
        preview.save(REVIEW_OUTPUT / "catalogue.png")
    manifest = {
        "style_sources": ["tgui/packages/tgui/styles/interfaces/CyberpunkPanel.scss:.StyleGuide", "tgui/packages/tgui-panel/styles/themes/cyberpunk.scss"],
        "method": "TG Midnight filled sprite construction: original inventory pixels darkened, original TG small controls, shaded five-ink cyberpunk hands/equipment and relief pixel lettering; frames from the supplied ui.dmi",
        "max_colors_per_glyph": 5,
        "glyph_palette": ["#%02x%02x%02x" % color[:3] for color in GLYPH_PALETTE],
        "hand_palette": ["#%02x%02x%02x" % color[:3] for color in HAND_PALETTE],
        "slot_palette": ["#%02x%02x%02x" % color[:3] for color in SLOT_PALETTE],
        "palette": {"accent": "#be485b", "panel": "#07090e", "idle_border": "#3d1e29", "active_border": "#376975"},
        "sources": {p.relative_to(OUTPUT / "sources").as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source_dir.rglob("*")) if p.is_file()},
        "dmi": {},
    }
    for path in sorted(OUTPUT.glob("*.dmi")):
        dmi = Dmi.from_file(path)
        manifest["dmi"][path.name] = {
            "width": dmi.width, "height": dmi.height,
            "states": [s.name for s in dmi.states],
            "rgba_sha256": {s.name: hashlib.sha256(s.get_frame().tobytes()).hexdigest() for s in dmi.states},
        }
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8", newline="\n")
    print(f"Built and RGBA-roundtrip-verified {len(manifest['dmi'])} DMI files")
    for name, info in manifest["dmi"].items():
        print(f"{name}: {info['width']}x{info['height']}, {len(info['states'])} states")


if __name__ == "__main__":
    main()
