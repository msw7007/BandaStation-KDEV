"""Build native CP13 HUD states from generated art and the TGUI StyleGuide."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = next(path for path in Path(__file__).resolve().parents if (path / "tgstation.dme").is_file())
sys.path.insert(0, str(ROOT))
from tools.dmi import Dmi

OUTPUT = Path(__file__).resolve().parents[1] / "icons/hud/cp13"
GLYPH = (141, 175, 185, 255)
ACCENT = (190, 72, 91, 255)
SOURCES = {
    "language": "exec-422bfd5c-67cf-40b1-bb3b-63c681ce27df.png",
    "craft": "exec-2bf2f41f-a913-47f0-8e37-232106480fac.png",
    "navigate": "exec-fdf7a834-221d-47b0-b449-935539bd8419.png",
    "area_create": "exec-19c0f08a-0ad0-4985-a436-3a6ca1fd015d.png",
    "emote": "exec-8c9a4d7e-e990-4875-8031-9fd1abd44e39.png",
    "resist": "exec-ae2f416e-2602-424b-98de-c513165e33a7.png",
    "run": "exec-b8dd09d0-8564-467a-bf74-87b3e22d5068.png",
    "rest": "exec-379b1517-b0cb-43f3-bb47-28e1ae62dbff.png",
    "underwear": "exec-b8354aee-983c-4291-9e7a-b3e048504bf7.png",
}
NATIVE = {"equipment": 32, "memories": 32, "swap": 16, "walk": 16, "throw": 16, "drop": 16}


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


def flatten(image):
    """Remove generated fringe/shading; retain the source silhouette and holes."""
    pixels = np.array(image.convert("RGBA"), dtype=np.int16)
    r, g, b, a = (pixels[:, :, i] for i in range(4))
    cyan = (a >= 224) & (r >= 35) & (g >= 50) & (b >= 50) & (g-r >= 8) & (b-r >= 10)
    red = (a >= 224) & (r >= 65) & (r-g >= 28) & (r-b >= 20)
    result = np.zeros(pixels.shape, dtype=np.uint8)
    result[cyan] = GLYPH
    result[red] = ACCENT
    image = Image.fromarray(result)
    if not image.getbbox():
        raise ValueError("Source does not contain a usable silhouette")
    return image.crop(image.getbbox())


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
            image.putpixel((x,y), GLYPH)
    return image


def frame(size, state, outline_only=False):
    """Rasterize StyleGuide__cutButton geometry directly on the native grid."""
    w, h = size
    cut = 2 if min(size) == 16 else 3
    palette = {
        "idle": ((12,12,20,208), (111,40,54,200)),
        "hover": ((6,24,31,228), (74,160,180,255)),
        "active": ((5,29,37,236), (91,189,205,255)),
        "combat": ((37,7,13,232), (195,64,84,255)),
        "disabled": ((5,8,13,200), (35,49,56,220)),
    }
    fill, border = palette[state]
    image = Image.new("RGBA", size)
    points = [(cut,0), (w-1,0), (w-1,h-1-cut), (w-1-cut,h-1), (0,h-1), (0,cut)]
    ImageDraw.Draw(image).polygon(points, fill=None if outline_only else fill, outline=border)
    return image


def compose(frame_image, glyph):
    image = frame_image.copy()
    image.alpha_composite(glyph)
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generated", type=Path)
    parser.add_argument("--trial", type=Path)
    parser.add_argument("--preview", action="store_true", help="Also write the optional reference catalogue")
    args = parser.parse_args()
    source_dir = OUTPUT / "sources"
    source_dir.mkdir(parents=True, exist_ok=True)
    if args.generated:
        for key, name in SOURCES.items():
            shutil.copy2(args.generated / name, source_dir / f"{key}.png")
    if args.trial:
        for key, size in NATIVE.items():
            shutil.copy2(args.trial / f"{key}_{size}x{size}.png", source_dir / f"native_{key}.png")

    glyphs = {}
    for key in ("language", "craft", "navigate", "area_create", "emote", "resist"):
        glyphs[key] = fit(flatten(Image.open(source_dir / f"{key}.png")), (16,16), (12,12))
    # Preserve a full native-pixel gutter between the generated floor tiles.
    for coordinate in range(16):
        glyphs["area_create"].putpixel((7, coordinate), (0,0,0,0))
        glyphs["area_create"].putpixel((coordinate, 7), (0,0,0,0))
    for key in ("swap", "throw", "drop"):
        glyphs[key] = Image.open(source_dir / f"native_{key}.png").convert("RGBA")
        p = np.array(glyphs[key])
        p[(p[:,:,3] > 0) & (p[:,:,1] > p[:,:,0])] = GLYPH
        p[(p[:,:,3] > 0) & (p[:,:,0] > p[:,:,1])] = ACCENT
        glyphs[key] = Image.fromarray(p)
    glyphs["memories"] = fit(flatten(Image.open(source_dir / "native_memories.png")), (16,16), (14,14))
    # A one-pixel spine keeps the two pages distinct after nearest fitting.
    for y in range(4,11):
        glyphs["memories"].putpixel((7,y), (0,0,0,0))
    glyphs["sleep"] = fit(flatten(Image.open(source_dir / "rest.png")), (16,16), (12,6))
    glyphs["throw_combat"] = glyphs["throw"].copy()
    p = np.array(glyphs["throw_combat"])
    p[p[:,:,3] > 0] = ACCENT
    glyphs["throw_combat"] = Image.fromarray(p)
    glyphs["act_throw"] = glyphs["throw"].copy()
    glyphs["act_throw_on"] = glyphs["throw_combat"].copy()
    for alias, original in (("act_resist_on", "resist"), ("act_sleep_flick", "sleep")):
        pixels = np.array(glyphs[original])
        pixels[pixels[:,:,3] > 0] = ACCENT
        glyphs[alias] = Image.fromarray(pixels)
    glyphs = {name: clean_pixels(image) for name, image in glyphs.items()}
    glyphs["arrow_up"] = vertical_arrow()
    glyphs["arrow_down"] = glyphs["arrow_up"].transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    write_dmi(OUTPUT, "glyphs_16x16", (16,16), glyphs)

    large = {
        "equipment": fit(flatten(Image.open(source_dir / "native_equipment.png")), (32,32), (22,24)),
        "underwear": fit(flatten(Image.open(source_dir / "underwear.png")), (32,32), (18,22)),
        "accessories": fit(flatten(Image.open(source_dir / "area_create.png")), (32,32), (18,18)),
        "memories": fit(flatten(Image.open(source_dir / "native_memories.png")), (32,32), (24,24)),
    }
    write_dmi(OUTPUT, "glyphs_32x32", (32,32), large)

    movement = {}
    poses = {
        "walk": fit(flatten(Image.open(source_dir / "native_walk.png")), (32,16), (14,12)),
        "run": fit(flatten(Image.open(source_dir / "run.png")), (32,16), (22,12)),
        "rest": fit(flatten(Image.open(source_dir / "rest.png")), (32,16), (24,9)),
    }
    for body in ("human", "anthro"):
        for pose, image in poses.items():
            movement[f"{pose}_{body}"] = image.copy()
    write_dmi(OUTPUT, "movement_32x16", (32,16), movement)

    frames = {}
    for size in ((16,16), (32,16), (32,32), (16,32)):
        states = {key: frame(size, key) for key in ("idle", "hover", "active", "combat", "disabled")}
        states.update({"outline": states["idle"].copy(), "grid": states["idle"].copy()})
        if size == (16,32):
            states["buff"] = states["hover"].copy()
            states["debuff"] = states["combat"].copy()
            states["split"] = Image.new("RGBA", size)
            states["split"].alpha_composite(frame((16,16), "idle"), (0,0))
            states["split"].alpha_composite(frame((16,16), "idle"), (0,16))
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
    frames[(32,32)]["scroll_up"] = compose(frame((32,32), "idle"), fit(up.crop(up.getbbox()), (32,32), (10,14)))
    frames[(32,32)]["scroll_down"] = compose(frame((32,32), "idle"), fit(down.crop(down.getbbox()), (32,32), (10,14)))
    write_dmi(OUTPUT, "frames_32x32", (32,32), frames[(32,32)])

    stock = Dmi.from_file(ROOT / "icons/hud/screen_midnight.dmi")
    hands = {}
    for side in ("l", "r"):
        original = next(s.get_frame() for s in stock.states if s.name == f"hand_{side}")
        hands[f"hand_{side}"] = fit(flatten(original), (32,32), (18,18))
        hands[f"{side}handactive"] = frame((32,32), "active", outline_only=True)
    write_dmi(OUTPUT, "hands_32x32", (32,32), hands)

    all_sets = {"glyphs_16x16": glyphs, "glyphs_32x32": large, "movement_32x16": movement, "hands_32x32": hands, "floor_16x32": {"floor_change_v": floor}}
    all_sets.update({f"frames_{size[0]}x{size[1]}": states for size, states in frames.items()})
    native_dir = OUTPUT / "native"
    native_dir.mkdir(exist_ok=True)
    entries = []
    for group, states in all_sets.items():
        group_dir = native_dir / group
        group_dir.mkdir(exist_ok=True)
        for state, image in states.items():
            image.save(group_dir / f"{state}.png")
            if not group.startswith("frames_"):
                entries.append((state, image))
    entries.extend((f"frame_{w}x{h}_{state}", states[state]) for (w,h), states in frames.items() for state in ("idle", "hover", "active"))
    if args.preview:
        font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 14)
        preview = Image.new("RGB", (960, ((len(entries)+5)//6)*148+50), "#05080d")
        draw = ImageDraw.Draw(preview)
        draw.text((16,12), "CP13 / native DMI states / enlarged 3x, nearest", font=font, fill="#91b8c2")
        for index, (name, image) in enumerate(entries):
            x, y = (index%6)*160+12, (index//6)*148+52
            draw.text((x,y), name, font=font, fill="#91b8c2")
            draw.text((x,y+19), f"{image.width}x{image.height}", font=font, fill="#78909a")
            preview.paste(image.resize((image.width*3, image.height*3), Image.Resampling.NEAREST), (x+24,y+40), image.resize((image.width*3,image.height*3), Image.Resampling.NEAREST))
        preview.save(OUTPUT / "catalogue.png")
    manifest = {
        "style_sources": ["tgui/packages/tgui/styles/interfaces/CyberpunkPanel.scss:.StyleGuide", "tgui/packages/tgui-panel/styles/themes/cyberpunk.scss"],
        "method": "image_gen silhouettes; alpha/palette cleanup; nearest-neighbor native fitting; CSS-derived native pixel frames; stock hand glyphs",
        "palette": {"glyph": "#8dafb9", "accent": "#be485b", "panel": "#0c0c14", "idle_border": "#6f2836", "active_border": "#5bbdcd"},
        "sources": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source_dir.glob("*.png"))},
        "dmi": {},
    }
    for path in sorted(OUTPUT.glob("*.dmi")):
        dmi = Dmi.from_file(path)
        manifest["dmi"][path.name] = {"width": dmi.width, "height": dmi.height, "states": [s.name for s in dmi.states]}
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    print(f"Built and RGBA-roundtrip-verified {len(manifest['dmi'])} DMI files")
    for name, info in manifest["dmi"].items():
        print(f"{name}: {info['width']}x{info['height']}, {len(info['states'])} states")


if __name__ == "__main__":
    main()
