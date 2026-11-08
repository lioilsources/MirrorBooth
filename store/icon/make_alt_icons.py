#!/usr/bin/env python3
"""Build the app icons from the picked candidate (kaleido, main icon since 2.4.1).

    python3 store/icon/make_alt_icons.py

  store/icon/kaleido_1024.png      full-bleed master (committed)
  ios/Runner/Assets.xcassets/AppIcon.appiconset         main icon
  ios/Runner/Assets.xcassets/AppIcon-Color.appiconset   same, alternate icon
  ios/Runner/Assets.xcassets/AppIcon-Face.appiconset    the pre-2.4.1 face icon
  android/app/src/main/res/mipmap-*                     legacy + adaptive icon
  assets/icon/icon.png                                  desktop icon source
  store/play/graphics/icon-512-kaleido.png              Play listing icon

The Flux render came with its own rounded corners on a cream margin; it is
cropped to the rounded square and the corners are filled with its navy so
the stores' own masks are the only rounding.
"""
import json
import re
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
ASSETS = REPO / "mirrorbooth/ios/Runner/Assets.xcassets"
SOURCE = HERE / "candidates/flux_kaleido_9102.png"
MASTER = HERE / "kaleido_1024.png"
APP = REPO / "mirrorbooth"
RES = APP / "android/app/src/main/res"
NAVY = (60, 52, 78)
# Android launcher sizes: legacy icon (48dp) and adaptive foreground (108dp).
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
# Share of the 108dp adaptive canvas the square artwork covers; the launcher
# mask shows the middle 72dp (0.67), so the artwork just fills it.
FOREGROUND_SCALE = 0.70

# The baked-in rounded square in the 1024 render, and its corner radius.
BOX = (58, 58, 965, 965)
RADIUS = 110


def master():
    if not SOURCE.exists():
        return Image.open(MASTER).convert("RGB")
    im = Image.open(SOURCE).convert("RGB").crop(BOX)
    navy = im.getpixel((RADIUS, RADIUS // 3))
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, -20, im.width - 1, im.height + 20], radius=RADIUS, fill=255)
    out = Image.new("RGB", im.size, navy)
    out.paste(im, (0, 0), mask)
    out = clean_corners(out.resize((1024, 1024), Image.LANCZOS))
    out.save(MASTER, optimize=True)
    return out


def clean_corners(im):
    """Paint the render's own cream frame in the corners over with navy."""
    px = np.asarray(im, dtype=float)
    yy, xx = np.mgrid[0:im.height, 0:im.width]
    dist = np.hypot(xx - (im.width - 1) / 2, yy - (im.height - 1) / 2)
    light = (px.mean(axis=2) > 140) & (dist > 540)
    mask = Image.fromarray((light * 255).astype("uint8"))
    mask = mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(2))
    alpha = np.asarray(mask, dtype=float) / 255
    alpha[dist < 525] = 0
    out = px * (1 - alpha[..., None]) + np.array(NAVY, float) * alpha[..., None]
    return Image.fromarray(out.astype("uint8"))


def appiconset(name, image):
    folder = ASSETS / f"{name}.appiconset"
    folder.mkdir(exist_ok=True)
    image.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(folder / "icon-1024.png")
    # Single-size icon: Xcode renders every other size at build time.
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "icon-1024.png", "idiom": "universal",
                    "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")


def android(image):
    for name, scale in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        image.resize((round(48 * scale),) * 2, Image.LANCZOS).save(
            folder / "ic_launcher.png", optimize=True)
        side = round(108 * scale)
        art = round(side * FOREGROUND_SCALE)
        fg = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        fg.paste(image.resize((art, art), Image.LANCZOS), ((side - art) // 2,) * 2)
        fg.save(folder / "ic_launcher_foreground.png", optimize=True)
    colors = RES / "values/colors.xml"
    colors.write_text(re.sub(
        r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]+',
        r"\g<1>#FF%02X%02X%02X" % NAVY, colors.read_text()))


def main():
    kaleido = master()
    main_set = ASSETS / "AppIcon.appiconset"
    face = ASSETS / "AppIcon-Face.appiconset/icon-1024.png"
    if not face.exists():  # keep the old icon before the main set is replaced
        appiconset("AppIcon-Face", Image.open(main_set / "Icon-App-1024x1024@1x.png"))
    for old in main_set.glob("*.png"):
        old.unlink()
    appiconset("AppIcon", kaleido)
    appiconset("AppIcon-Color", kaleido)
    android(kaleido)
    kaleido.save(APP / "assets/icon/icon.png", optimize=True)
    kaleido.resize((512, 512), Image.LANCZOS).save(
        REPO / "store/play/graphics/icon-512-kaleido.png", optimize=True)
    print("ok")


if __name__ == "__main__":
    main()
