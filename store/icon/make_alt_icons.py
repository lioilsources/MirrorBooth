#!/usr/bin/env python3
"""Build the alternate app icons for App Store Product Page Optimization and
the Play store-listing experiment from the picked candidate.

    python3 store/icon/make_alt_icons.py

  store/icon/kaleido_1024.png      full-bleed master (committed)
  ios/Runner/Assets.xcassets/AppIcon-Color.appiconset   picked candidate
  ios/Runner/Assets.xcassets/AppIcon-Face.appiconset    placeholder (today's icon)
  store/play/graphics/icon-512-kaleido.png              Play experiment variant

The Flux render came with its own rounded corners on a cream margin; it is
cropped to the rounded square and the corners are filled with its navy so
the stores' own masks are the only rounding.
"""
import json
import pathlib

from PIL import Image, ImageDraw

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
ASSETS = REPO / "mirrorbooth/ios/Runner/Assets.xcassets"
SOURCE = HERE / "candidates/flux_kaleido_9102.png"
MASTER = HERE / "kaleido_1024.png"
CURRENT = ASSETS / "AppIcon.appiconset/Icon-App-1024x1024@1x.png"

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
    out = out.resize((1024, 1024), Image.LANCZOS)
    out.save(MASTER, optimize=True)
    return out


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


def main():
    kaleido = master()
    appiconset("AppIcon-Color", kaleido)
    # TODO(ol1n): replace with the face-with-split-line design when it exists.
    appiconset("AppIcon-Face", Image.open(CURRENT))
    kaleido.resize((512, 512), Image.LANCZOS).save(
        REPO / "store/play/graphics/icon-512-kaleido.png", optimize=True)
    print("ok")


if __name__ == "__main__":
    main()
