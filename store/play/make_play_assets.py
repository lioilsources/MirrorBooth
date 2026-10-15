#!/usr/bin/env python3
"""Render every Google Play listing graphic for MirrorBooth.

    python3 store/play/make_play_assets.py [--src DIR]

  store/play/graphics/icon-512.png          512x512, RGB (Play rejects alpha)
  store/play/graphics/feature-1024x500.png  mandatory listing banner
  store/play/screenshots/phone/NN_*.png     1080x1920 (9:16)
  store/play/screenshots/tablet/NN_*.png    1920x1200

Adapted from DuolingoCards/tools/{play_graphics,appstore_shots}.py.

Raw captures are iPhone 1125x2436 (2.165:1). Play caps phone screenshots at
2:1, so they are *framed* (whole capture centred at full height on a dark
wash) rather than cropped. The fourth shot is a frame pulled from the echo
effect demo clip with ffmpeg; it is skipped if ffmpeg is missing.
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
ICON = REPO / "mirrorbooth" / "assets" / "icon" / "icon.png"
DEFAULT_SRC = REPO.parent / "ol1n.now/apps/mirrorbooth/screenshots/raw/mobile/ios"

FONT = "/System/Library/Fonts/SFNS.ttf"
# docs/ site palette
BG_TOP = (13, 10, 20)       # #0d0a14
BG_BOTTOM = (36, 24, 60)    # a shade lighter than #1d1530
ACCENT = (216, 180, 254)    # #d8b4fe
MUTED = (167, 155, 196)

# (output name, raw file stem or video spec) in listing order.
SHOTS = [
    ("neon_mirror", ("video", "mb_effect_echo_1778454657078.MP4", 9.0)),
    ("pop_mirror", ("image", "mb_1783922830175.PNG")),
    ("heat_mirror", ("image", "mb_1784071530980.PNG")),
    ("blue_kaleido", ("image", "mb_1784070856777.PNG")),
]

TARGETS = {"phone": (1080, 1920), "tablet": (1920, 1200)}


def font(size, weight=None):
    f = ImageFont.truetype(FONT, size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def flatten(im, bg=(0, 0, 0)):
    if im.mode not in ("RGBA", "LA", "P"):
        return im.convert("RGB")
    im = im.convert("RGBA")
    out = Image.new("RGB", im.size, bg)
    out.paste(im, (0, 0), im)
    return out


def gradient(size, top=BG_TOP, bottom=BG_BOTTOM, horizontal=False):
    w, h = size
    canvas = Image.new("RGB", size, top)
    draw = ImageDraw.Draw(canvas)
    n = w if horizontal else h
    for i in range(n):
        t = i / max(n - 1, 1)
        c = tuple(int(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(i, 0), (i, h)] if horizontal else [(0, i), (w, i)], fill=c)
    return canvas


def store_icon(out):
    icon = flatten(Image.open(ICON)).resize((512, 512), Image.LANCZOS)
    path = out / "icon-512.png"
    icon.save(path, "PNG")
    return path


def feature_graphic(out):
    w, h = 1024, 500
    canvas = gradient((w, h), horizontal=True)
    draw = ImageDraw.Draw(canvas)

    side = 280
    icon = flatten(Image.open(ICON)).resize((side, side), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, side - 1, side - 1], radius=62, fill=255)
    pos = (72, (h - side) // 2)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow.paste((216, 180, 254, 90), pos, mask)
    glow = glow.filter(ImageFilter.GaussianBlur(26))
    canvas.paste(glow, (0, 0), glow)
    canvas.paste(icon, pos, mask)

    x = 72 + side + 52
    size = 86  # shrink the wordmark until it clears the right edge
    while draw.textlength("MirrorBooth", font=font(size, 700)) > w - x - 44:
        size -= 2
    draw.text((x, 150), "MirrorBooth", font=font(size, 700), fill=ACCENT)
    draw.text((x, 262), "Symmetric face mirror", font=font(38, 500),
              fill=(236, 230, 245))
    draw.text((x, 318), "24 live filters · photos · video",
              font=font(30, 400), fill=MUTED)

    path = out / "feature-1024x500.png"
    canvas.save(path, "PNG")
    return path


def frame(im, size):
    tw, th = size
    margin = round(th * 0.06)
    scale = (th - 2 * margin) / im.height
    shot = im.resize(
        (round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    radius = round(shot.width * 0.06)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, shot.width - 1, shot.height - 1], radius=radius, fill=255)

    canvas = gradient(size)
    pos = ((tw - shot.width) // 2, (th - shot.height) // 2)
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    glow.paste((216, 180, 254, 70), pos, mask)
    glow = glow.filter(ImageFilter.GaussianBlur(round(margin * 0.45)))
    canvas.paste(glow, (0, 0), glow)
    canvas.paste(shot, pos, mask)
    return canvas


def load(spec, src, tmp):
    if spec[0] == "image":
        p = src / spec[1]
        return flatten(Image.open(p)) if p.exists() else None
    _, name, t = spec
    clip = src / name
    if not clip.exists() or not shutil.which("ffmpeg"):
        return None
    dest = pathlib.Path(tmp) / (clip.stem + ".png")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(t), "-i",
                    str(clip), "-frames:v", "1", str(dest)], check=True)
    return flatten(Image.open(dest))


def main():
    argv = sys.argv[1:]
    src = pathlib.Path(argv[argv.index("--src") + 1]) if "--src" in argv \
        else DEFAULT_SRC

    gfx = HERE / "graphics"
    gfx.mkdir(parents=True, exist_ok=True)
    for p in (store_icon(gfx), feature_graphic(gfx)):
        print(p.relative_to(REPO), Image.open(p).size, Image.open(p).mode)

    with tempfile.TemporaryDirectory() as tmp:
        images = []
        for name, spec in SHOTS:
            im = load(spec, src, tmp)
            if im is None:
                print(f"skip {name}: source missing", file=sys.stderr)
                continue
            images.append((name, im))
        if len(images) < 2:
            raise SystemExit("Play needs at least 2 phone screenshots")

        for target, size in TARGETS.items():
            out = HERE / "screenshots" / target
            out.mkdir(parents=True, exist_ok=True)
            for old in out.glob("*.png"):
                old.unlink()
            for i, (name, im) in enumerate(images, start=1):
                dest = out / f"{i:02d}_{name}.png"
                frame(im, size).save(dest, "PNG")
                print(dest.relative_to(REPO), size)


if __name__ == "__main__":
    main()
