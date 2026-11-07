#!/usr/bin/env python3
"""Promotion images (1024x1024) for the Art and Fantasy in-app purchases.

    python3 store/appstore/make_iap_promo.py

Each image is a 2x2 grid of one symmetric face run through four filters of
that collection with the app's own shaders. No text: the App Store shows the
purchase's display name next to the image. Writes promo/<product>.png.
"""
import pathlib
import tempfile

from PIL import Image, ImageDraw

import make_appstore_shots as shots

HERE = shots.HERE
OUT = HERE / "promo"
SIZE = 1024
GAP = 24

# product suffix -> (face, filters in reading order)
PROMOS = {
    "art_unlock": ("cat_6101.png", ["oil", "popArt", "pencil", "neon"]),
    "fantasy_unlock": ("comic_6811.png", ["demon", "cyborg", "frozen", "zombie"]),
}


def main():
    sources = {}
    for key, (face, filters) in PROMOS.items():
        im = Image.open(HERE / "faces" / face).convert("RGB")
        sources[key] = (shots.mirror(im, 0.50, True), filters)
    with tempfile.TemporaryDirectory() as tmp:
        filtered = shots.render_filters(pathlib.Path(tmp), sources)

    OUT.mkdir(exist_ok=True)
    cell = (SIZE - 3 * GAP) // 2
    mask = Image.new("L", (cell, cell), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, cell - 1, cell - 1), 40, fill=255)
    for key, (_, filters) in PROMOS.items():
        canvas = shots.gradient((SIZE, SIZE))
        for i, name in enumerate(filters):
            tile = shots.cover(filtered[f"{key}_{name}"], (cell, cell))
            x = GAP + (i % 2) * (cell + GAP)
            y = GAP + (i // 2) * (cell + GAP)
            canvas.paste(tile, (x, y), mask)
        canvas.convert("RGB").save(OUT / f"{key}.png", "PNG", optimize=True)
        print(key, "written")


if __name__ == "__main__":
    main()
