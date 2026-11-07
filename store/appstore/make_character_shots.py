#!/usr/bin/env python3
"""Render candidate App Store screenshots starring the character faces.

    python3 store/appstore/make_character_shots.py [--play] [name ...]

--play renders Google Play phone shots instead: 1080x1920 (Play caps the
aspect ratio at 2:1) in screenshots/candidates/play/.

For every character in CHARACTERS three iPhone 6.9" (1320x2868) scenes go to
store/appstore/screenshots/candidates/<name>_NN_<scene>.png, plus a 440 px
wide JPEG in candidates/thumbs/ for the curation page:

  lr       original vs. left + left vs. right + right
  filters  six filters (mostly the paid Art and Fantasy ones) via the shaders
  live     one filter full screen, original as inset

They are candidates, not a locale set: pick the keepers and copy them into a
locale folder before upload_screenshots.py. Layout, palette and shaders are
shared with make_appstore_shots.py. English copy only.
"""
import json
import pathlib
import shutil
import sys
import tempfile

from PIL import Image

import make_appstore_shots as shots

HERE = shots.HERE
OUT = HERE / "screenshots" / "candidates"
SIZE = shots.TARGETS["iphone"]

# name -> (face file, facial midline x, headline for the L/R scene,
#          six grid filters, live filter)
CHARACTERS = {
    "cat": ("cat_6101.png", 0.50, "Which side of your cat wins?",
            ["popArt", "oil", "comic", "neon", "pencil", "frozen"], "oil"),
    "dog": ("dog_6201.png", 0.50, "Which side of your pup wins?",
            ["comic", "thermal", "popArt", "crt", "ghost", "cyborg"], "comic"),
    "bear": ("bear_6303.png", 0.50, "Mirror your teddy",
             ["pencil", "oil", "crt", "popArt", "zombie", "ghost"], "pencil"),
    "bunny": ("bunny_6402.png", 0.50, "Mirror your plushies",
              ["neon", "popArt", "glitch", "oil", "frozen", "demon"], "neon"),
    "fashiondoll": ("fashiondoll_6501.png", 0.50, "Dolls have two sides too",
                    ["popArt", "comic", "neon", "oil", "vampire", "frozen"], "popArt"),
    "porcelain": ("porcelain_6601.png", 0.50, "Which side is creepier?",
                  ["oil", "pencil", "crt", "ghost", "vampire", "zombie"], "ghost"),
    "chibi": ("chibi_6701.png", 0.50, "Cartoons get mirrored too",
              ["neon", "glitch", "popArt", "comic", "crt", "frozen"], "glitch"),
    "comic": ("comic_6811.png", 0.50, "Every hero has a better side",
              ["comic", "popArt", "pencil", "thermal", "demon", "cyborg"], "popArt"),
    "alien": ("alien_6901.png", 0.50, "Even aliens pick a side",
              ["thermal", "neon", "glitch", "crt", "cyborg", "frozen"], "thermal"),
    "nora": ("nora_7003.png", 0.50, "Which side of your face wins?",
             ["oil", "pencil", "popArt", "neon", "vampire", "frozen"], "oil"),
    "kenji": ("kenji_7101.png", 0.50, "Which side of your face wins?",
              ["pencil", "comic", "oil", "crt", "zombie", "cyborg"], "comic"),
}

COPY = dict(shots.EN, filters="Art & Fantasy filters, live",
            live="Perfectly symmetric, live")


def main():
    global OUT, SIZE
    argv = sys.argv[1:]
    if "--play" in argv:
        argv.remove("--play")
        OUT, SIZE = OUT / "play", (1080, 1920)
    only = argv
    labels = json.loads((shots.APP / "lib" / "l10n" / "app_en.arb").read_text())
    chars = {k: v for k, v in CHARACTERS.items() if not only or k in only}

    faces, sources = {}, {}
    for key, (name, midline, _, grid, live) in chars.items():
        im = Image.open(HERE / "faces" / name).convert("RGB")
        left, right = shots.mirror(im, midline, True), shots.mirror(im, midline, False)
        faces[key] = (im, left, right)
        sources[f"{key}_grid"] = (right, grid)
        sources[f"{key}_live"] = (left, [live])

    with tempfile.TemporaryDirectory() as tmp:
        filtered = shots.render_filters(pathlib.Path(tmp), sources)

    thumbs = OUT / "thumbs"
    thumbs.mkdir(parents=True, exist_ok=True)
    for key, (_, _, hero_line, grid, live) in chars.items():
        im, left, right = faces[key]
        pics = {"hero": im, "hero_left": left, "hero_right": right,
                **{n: filtered[f"{key}_grid_{n}"] for n in grid}}
        t = dict(COPY, hero=hero_line)
        old_grid = shots.GRID_FILTERS
        shots.GRID_FILTERS = grid
        scenes = [("lr", shots.scene_hero), ("filters", shots.scene_filters),
                  ("live", shots.scene_live)]
        for i, (scene, draw) in enumerate(scenes, start=1):
            canvas = shots.gradient(SIZE)
            p = dict(pics, hero_right=filtered[f"{key}_live_{live}"]) \
                if scene == "live" else pics
            draw(canvas, t, p, labels)
            stem = f"{key}_{i:02d}_{scene}"
            canvas.save(OUT / f"{stem}.png", "PNG", optimize=True)
            thumb = canvas.resize((440, round(440 * SIZE[1] / SIZE[0])), Image.LANCZOS)
            thumb.save(thumbs / f"{stem}.jpg", "JPEG", quality=82)
        shots.GRID_FILTERS = old_grid
        print(key, "3 shots", flush=True)


if __name__ == "__main__":
    main()
