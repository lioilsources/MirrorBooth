#!/usr/bin/env python3
"""Render the App Store "Header and Search Results" artwork for Mirror Booth.

    python3 tool/store_header.py [output folder]

  store/appstore_creative/header-3840x1646.png   product page header (21:9)
  store/appstore_creative/search-3840x2560.png   search results asset (3:2)

A wall of photo-booth prints made from the app's own pictures: the fictional
faces in store/appstore/faces/ (generate_faces.py), mirrored the way the app
mirrors, and the filtered faces in store/icon/candidates/, rendered by the
app's shaders. In the middle stand the three heroes of the first screenshot:
Lea as she is, flanked by her Left + Left and Right + Right faces.

No text, so one image serves every localization. Apple publishes the sizes,
not each device's crop: the header template marks a 1646x661 "Art Safe Area"
in the centre, so the heroes sit inside it and the wall around them may be
cut anywhere. The PNGs are RGB without alpha (Apple rejects alpha). Check the
result with Preview in App Store Connect before submitting.
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
FACES = ROOT / "store/appstore/faces"
FILTERED = ROOT / "store/icon/candidates"
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "store/appstore_creative"

# docs/ site palette, as in store/appstore/make_appstore_shots.py
BG_EDGE = (13, 10, 20)
BG_MID = (36, 24, 60)
BG_GLOW = (92, 56, 150)
ACCENT = (216, 180, 254)
PAPER = (250, 248, 252)

FACE_Y = 0.37  # eye line in the face files, where crops are centred
HERO = ("lea_4305.png", 0.500)  # en-US hero face and its midline

# Wall prints: (file, how). "orig" as generated, "left"/"right" mirrored from
# that half, anything else is a filtered face from FILTERED. Adults,
# characters and animals only; the two kid-looking faces stay out.
WALL = [
    ("face_bia_neon.png", "filtered"),
    ("cat_6101.png", "left"),
    ("rafa_4204.png", "right"),
    ("face_chibi_comic.png", "filtered"),
    ("kenji_7101.png", "left"),
    ("dog_6201.png", "right"),
    ("face_alien_thermal.png", "filtered"),
    ("nora_7003.png", "left"),
    ("bunny_6402.png", "orig"),
    ("ana_4102.png", "right"),
    ("face_comic_popArt.png", "filtered"),
    ("bear_6303.png", "left"),
    ("face_miko_glitch.png", "filtered"),
    ("fashiondoll_6501.png", "right"),
    ("face_cat_popArt.png", "filtered"),
    ("bia_4711.png", "left"),
    ("porcelain_6601.png", "right"),
    ("face_porcelain_oil.png", "filtered"),
    ("miko_5002.png", "orig"),
    ("rafa_4204.png", "left"),
    ("face_bunny_glow.png", "filtered"),
    ("comic_6811.png", "right"),
    ("chibi_6701.png", "left"),
    ("face_bia_mirror.png", "filtered"),
    ("alien_6901.png", "orig"),
    ("kenji_7101.png", "right"),
    ("face_cat_mirror.png", "filtered"),
    ("ana_4102.png", "left"),
    ("nora_7003.png", "right"),
]
MIDLINES = {"ana_4102.png": 0.487}  # the rest are centred

_cache = {}


def who(name):
    """The character in a file: face_cat_popArt.png and cat_6101.png -> cat."""
    return name.removeprefix("face_").split("_")[0]


def load(name):
    if name not in _cache:
        path = FACES / name if (FACES / name).exists() else FILTERED / name
        _cache[name] = Image.open(path).convert("RGB")
    return _cache[name]


def mirror(im, midline, keep_left):
    """Reflect one half of the face across its midline, as the app does."""
    cx = round(im.width * midline)
    half = min(cx, im.width - cx)
    box = (cx - half, 0, cx, im.height) if keep_left else (cx, 0, cx + half, im.height)
    part = im.crop(box)
    flipped = part.transpose(Image.FLIP_LEFT_RIGHT)
    out = Image.new("RGB", (half * 2, im.height))
    out.paste(part if keep_left else flipped, (0, 0))
    out.paste(flipped if keep_left else part, (half, 0))
    return out


def picture(name, how, midline=None):
    im = load(name)
    if how in ("left", "right"):
        im = mirror(im, midline or MIDLINES.get(name, 0.5), how == "left")
    return im


def cover(im, size, focus_y, zoom=1.0):
    """Scale to fill [size] (times [zoom]), eye line a little above the centre."""
    tw, th = size
    scale = max(tw / im.width, th / im.height) * zoom
    w, h = round(im.width * scale), round(im.height * scale)
    im = im.resize((w, h), Image.LANCZOS)
    x = (w - tw) // 2
    y = min(max(round(h * focus_y - th * 0.42), 0), h - th)
    return im.crop((x, y, x + tw, y + th))


def rounded(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


def print_card(im, w, focus_y=FACE_Y, axis=False, zoom=1.0):
    """A photo-booth print, RGBA: picture on white paper, 3:4."""
    h = round(w * 4 / 3)
    border = max(6, round(w * 0.045))
    card = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    card.paste((*PAPER, 255), (0, 0), rounded((w, h), round(w * 0.07)))
    inner = (w - 2 * border, h - 2 * border)
    shot = cover(im, inner, focus_y, zoom)
    if axis:
        # The mirror axis the app draws: a dashed line down the midline.
        layer = Image.new("RGBA", inner, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        x = inner[0] / 2
        dash, lw = inner[1] / 34, max(3, round(w * 0.008))
        y = dash * 0.5
        while y < inner[1]:
            d.line([(x, y), (x, min(y + dash, inner[1]))],
                   fill=(255, 255, 255, 190), width=lw)
            y += dash * 2
        layer = Image.alpha_composite(
            layer.filter(ImageFilter.GaussianBlur(lw * 1.5)), layer)
        shot = Image.alpha_composite(shot.convert("RGBA"), layer).convert("RGB")
    card.paste(shot, (border, border), rounded(inner, round(w * 0.045)))
    return card


def place(canvas, card, centre, angle, shadow=(6, 2, 14, 150), glow=None):
    card = card.rotate(angle, resample=Image.BICUBIC, expand=True)
    x = round(centre[0] - card.width / 2)
    y = round(centre[1] - card.height / 2)
    blur = max(6, round(card.width * 0.035))
    pad = blur * 4
    alpha = card.getchannel("A")
    size = (card.width + 2 * pad, card.height + 2 * pad)
    if glow:
        a = Image.new("L", size, 0)
        a.paste(alpha.point(lambda v: v * glow[3] // 255), (pad, pad))
        halo = Image.new("RGBA", size, (*glow[:3], 0))
        halo.putalpha(a.filter(ImageFilter.GaussianBlur(blur * 2.2)))
        paste_clipped(canvas, halo, x - pad, y - pad)
    a = Image.new("L", size, 0)
    a.paste(alpha.point(lambda v: v * shadow[3] // 255), (pad, pad + blur))
    sh = Image.new("RGBA", size, (*shadow[:3], 0))
    sh.putalpha(a.filter(ImageFilter.GaussianBlur(blur)))
    paste_clipped(canvas, sh, x - pad, y - pad)
    paste_clipped(canvas, card, x, y)


def paste_clipped(canvas, layer, x, y):
    """alpha_composite that tolerates layers hanging off the canvas."""
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + layer.width, canvas.width), min(y + layer.height, canvas.height)
    if x1 <= x0 or y1 <= y0:
        return
    part = layer.crop((x0 - x, y0 - y, x1 - x, y1 - y))
    canvas.alpha_composite(part, (x0, y0))


def background(w, h):
    """Radial glow from the centre: lavender-violet into the site's near-black."""
    small = (w // 8, h // 8)
    img = Image.new("RGB", small)
    px = img.load()
    cx, cy = small[0] / 2, small[1] / 2
    rx, ry = small[0] * 0.62, small[1] * 0.75
    for j in range(small[1]):
        for i in range(small[0]):
            d = min(1.0, math.hypot((i - cx) / rx, (j - cy) / ry))
            if d < 0.5:
                t = d / 0.5
                c = [a + (b - a) * t for a, b in zip(BG_GLOW, BG_MID)]
            else:
                t = (d - 0.5) / 0.5
                c = [a + (b - a) * t for a, b in zip(BG_MID, BG_EDGE)]
            px[i, j] = tuple(round(v) for v in c)
    return img.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(8)) \
        .convert("RGBA")


def dim(card, amount):
    """Push a wall print back so the heroes read first."""
    rgb = card.convert("RGB")
    dark = Image.new("RGB", card.size, BG_EDGE)
    out = Image.blend(rgb, dark, amount).convert("RGBA")
    out.putalpha(card.getchannel("A"))
    return out


def render(w, h, hero_w, cell, gap, name, seed):
    canvas = background(w, h)
    hero_h = round(hero_w * 4 / 3)
    big_w = round(hero_w * 1.12)
    big_h = round(big_w * 4 / 3)
    row = big_w + 2 * hero_w + 2 * gap
    clear = ((w - row) / 2 - cell * 0.35, (h - big_h) / 2 - cell * 0.42,
             (w + row) / 2 + cell * 0.35, (h + big_h) / 2 + cell * 0.42)

    # The wall: staggered rows, a little jitter and tilt, nothing in the
    # band around the heroes.
    rnd = random.Random(seed)
    card_w = round(cell * 0.74)
    row_h = round(cell * 1.06)
    recent = []
    for r in range(-1, h // row_h + 2):
        for c in range(-1, w // cell + 2):
            x = c * cell + (cell // 2 if r % 2 else 0) + rnd.randint(-22, 22)
            y = r * row_h + row_h // 2 + rnd.randint(-22, 22)
            angle = rnd.uniform(-9, 9)
            if clear[0] < x < clear[2] and clear[1] < y < clear[3]:
                continue
            # A print whose face is not among the last row's worth used, so
            # neither side nor row neighbours show the same character.
            fname, how = rnd.choice([s for s in WALL if who(s[0]) not in recent])
            recent = (recent + [who(fname)])[-12:]
            filtered = how == "filtered"
            card = print_card(picture(fname, how), card_w,
                              0.5 if filtered else FACE_Y,
                              zoom=1.0 if filtered else 1.15)
            # Darker towards the edges, brighter towards the heroes.
            dist = math.hypot((x - w / 2) / (w / 2), (y - h / 2) / (h / 2))
            place(canvas, dim(card, min(0.55, 0.18 + 0.32 * dist)), (x, y), angle)

    # Heroes: Lea's Left + Left, Lea as she is (mirror axis drawn), Right + Right.
    face, midline = HERO
    left = print_card(picture(face, "left", midline), hero_w, zoom=1.4)
    right = print_card(picture(face, "right", midline), hero_w, zoom=1.4)
    orig = print_card(picture(face, "orig"), big_w, axis=True, zoom=1.4)
    cx, cy = w / 2, h / 2
    off = big_w / 2 + gap + hero_w / 2
    glow = (*ACCENT, 120)
    place(canvas, left, (cx - off, cy + hero_h * 0.03), -5,
          shadow=(4, 0, 10, 200), glow=glow)
    place(canvas, right, (cx + off, cy + hero_h * 0.03), 5,
          shadow=(4, 0, 10, 200), glow=glow)
    place(canvas, orig, (cx, cy), 0, shadow=(4, 0, 10, 220), glow=(*ACCENT, 150))

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    print(path)


# Header: the three heroes fit the 1646x661 safe area, tilt included.
render(3840, 1646, hero_w=430, cell=360, gap=40,
       name="header-3840x1646.png", seed=11)
render(3840, 2560, hero_w=880, cell=520, gap=80,
       name="search-3840x2560.png", seed=5)
