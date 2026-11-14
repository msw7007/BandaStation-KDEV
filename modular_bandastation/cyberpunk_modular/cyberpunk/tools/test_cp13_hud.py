"""Offline asset checks; these do not launch BYOND or replace runtime tests."""

import hashlib
import json
import unittest

import numpy as np
from PIL import Image

from build_cp13_hud import OUTPUT
from tools.dmi import Dmi


class HudAssetTests(unittest.TestCase):
    def test_dmi_states_match_native_pngs(self):
        manifest = json.loads((OUTPUT / "manifest.json").read_text())
        for name, info in manifest["dmi"].items():
            dmi = Dmi.from_file(OUTPUT / name)
            self.assertEqual((dmi.width, dmi.height), (info["width"], info["height"]))
            self.assertEqual([s.name for s in dmi.states], info["states"])
            for state in dmi.states:
                with self.subTest(dmi=name, state=state.name):
                    png = Image.open(OUTPUT / "native" / name.removesuffix(".dmi") / f"{state.name}.png").convert("RGBA")
                    self.assertEqual((state.dirs, state.framecount), (1, 1))
                    self.assertEqual(state.get_frame().tobytes(), png.tobytes())
                    self.assertIsNotNone(png.getbbox())

    def test_source_hashes(self):
        manifest = json.loads((OUTPUT / "manifest.json").read_text())
        for name, expected in manifest["sources"].items():
            self.assertEqual(hashlib.sha256((OUTPUT / "sources" / name).read_bytes()).hexdigest(), expected)

    def test_clean_symmetric_floor_arrows(self):
        floor = Dmi.from_file(OUTPUT / "floor_16x32.dmi").states[0].get_frame()
        up, down = floor.crop((0,0,16,16)), floor.crop((0,16,16,32))
        self.assertEqual(up.tobytes(), up.transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes())
        self.assertEqual(up.tobytes(), down.transpose(Image.Transpose.FLIP_TOP_BOTTOM).tobytes())
        mask = np.array(up)[:,:,3] > 0
        self.assertEqual(mask.sum(axis=1).tolist(), [0,0,0,2,4,6,8,2,2,2,2,2,2,0,0,0])
        self.assertEqual(np.where(mask[7:13])[1].min(), 7)
        self.assertEqual(np.where(mask[7:13])[1].max(), 8)

    def test_no_detached_single_pixel_glyphs(self):
        dmi = Dmi.from_file(OUTPUT / "glyphs_16x16.dmi")
        for state in dmi.states:
            mask = np.array(state.get_frame())[:,:,3] > 0
            padded = np.pad(mask, 1)
            neighbors = np.zeros(mask.shape, dtype=np.uint8)
            for dy in range(3):
                for dx in range(3):
                    if dx != 1 or dy != 1:
                        neighbors += padded[dy:dy+16, dx:dx+16]
            with self.subTest(state=state.name):
                self.assertFalse(np.any(mask & (neighbors == 0)))

    def test_native_flick_and_scroll_contracts(self):
        glyphs = Dmi.from_file(OUTPUT / "glyphs_16x16.dmi")
        self.assertTrue({"act_throw", "act_throw_on", "act_resist_on", "act_sleep_flick", "arrow_up", "arrow_down"} <= {s.name for s in glyphs.states})
        frames = Dmi.from_file(OUTPUT / "frames_32x32.dmi")
        self.assertTrue({"scroll_up", "scroll_down", "reserved"} <= {s.name for s in frames.states})

    def test_active_hand_outline_does_not_cover_items(self):
        hands = Dmi.from_file(OUTPUT / "hands_32x32.dmi")
        for state in hands.states:
            if state.name.endswith("handactive"):
                self.assertIsNone(state.get_frame().crop((4,4,28,28)).getbbox())


if __name__ == "__main__":
    unittest.main(verbosity=2)
