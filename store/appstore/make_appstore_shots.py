#!/usr/bin/env python3
"""Render the localized App Store screenshot sets for Mirror Booth.

    python3 store/appstore/make_appstore_shots.py [--locales pt-BR,fr-FR]

  store/appstore/screenshots/<locale>/NN_<scene>_iphone.png  1320x2868 (6.9")
  store/appstore/screenshots/<locale>/NN_<scene>_ipad.png    2064x2752 (13")

The folders follow the `fastlane deliver` layout (see README.md). They are
generated, so they stay out of git; rerun this to get them back.

Every picture comes from the fictional faces in faces/ (generate_faces.py),
mirrored the way the app mirrors and filtered by the app's own shaders through
mirrorbooth/tool/store_filter_render_test.dart. Filter and voice-effect names
are read from the app's ARB files, so the listing always matches the UI.
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
APP = REPO / "mirrorbooth"
OUT = HERE / "screenshots"

FONT = "/System/Library/Fonts/SFNS.ttf"
# docs/ site palette, same as store/play/make_play_assets.py
BG_TOP = (13, 10, 20)
BG_BOTTOM = (36, 24, 60)
ACCENT = (216, 180, 254)
WHITE = (255, 255, 255)
RED = (255, 69, 58)

TARGETS = {"iphone": (1320, 2868), "ipad": (2064, 2752)}

# Face file -> x of the facial midline as a fraction of the width.
FACES = {
    "ana": ("ana_4102.png", 0.487),
    "lea": ("lea_4305.png", 0.500),
    "rafa": ("rafa_4204.png", 0.500),
}
FACE_Y = 0.37   # eye line, where crops are centred

GRID_FILTERS = ["neon", "popArt", "comic", "thermal", "vampire", "frozen"]
KALEIDO_FILTER = "comic"
VIDEO_FILTER = "crt"
AUDIO_CHIPS = ["audioEffectRobot", "audioEffectChipmunk", "audioEffectEcho"]

# App Store locale -> (ARB file, hero face, face used for the filter scenes)
LOCALES = {
    "en-US": ("en", "lea", "rafa"),
    "pt-BR": ("pt", "ana", "rafa"),
    "es-MX": ("es", "rafa", "ana"),
    "es-ES": ("es", "ana", "lea"),
    "fr-FR": ("fr", "lea", "ana"),
}
# Same pictures as en-US, per the ASO plan.
COPIES = {"en-GB": "en-US", "en-AU": "en-US", "en-CA": "en-US"}

EN = {
    "hero": "Which side of your face wins?",
    "original": "Original",
    "left": "Left + Left",
    "right": "Right + Right",
    "live": "Your perfectly symmetric face, live",
    "filters": "24 live filters",
    "kaleido": "Rotate the mirror, make a kaleidoscope",
    "video": "Record video with voice effects",
}
PT = {
    "hero": "Qual lado do seu rosto vence?",
    "original": "Original",
    "left": "Esquerdo + Esquerdo",
    "right": "Direito + Direito",
    "live": "Seu rosto perfeitamente simétrico, ao vivo",
    "filters": "24 filtros ao vivo",
    "kaleido": "Gire o espelho e crie um caleidoscópio",
    "video": "Grave vídeos com efeitos de voz",
}
ES_MX = {
    "hero": "¿Qué lado de tu cara gana?",
    "original": "Original",
    "left": "Izquierda + Izquierda",
    "right": "Derecha + Derecha",
    "live": "Tu cara perfectamente simétrica, en vivo",
    "filters": "24 filtros en vivo",
    "kaleido": "Gira el espejo y crea un caleidoscopio",
    "video": "Graba videos con efectos de voz",
}
ES_ES = dict(
    ES_MX,
    live="Tu cara perfectamente simétrica, en directo",
    filters="24 filtros en directo",
    video="Graba vídeos con efectos de voz",
)
FR = {
    "hero": "Quel côté de votre visage gagne ?",
    "original": "Original",
    "left": "Gauche + Gauche",
    "right": "Droite + Droite",
    "live": "Votre visage parfaitement symétrique, en direct",
    "filters": "24 filtres en direct",
    "kaleido": "Tournez le miroir, créez un kaléidoscope",
    "video": "Filmez avec des effets de voix",
}
COPY = {"en-US": EN, "pt-BR": PT, "es-MX": ES_MX, "es-ES": ES_ES, "fr-FR": FR}


def font(size, weight=400):
    f = ImageFont.truetype(FONT, size)
    axes = f.get_variation_axes()
    f.set_variation_by_axes([
        weight if a["name"] in (b"Weight", "Weight") else a["default"]
        for a in axes
    ])
    return f


def gradient(size):
    w, h = size
    canvas = Image.new("RGB", size, BG_TOP)
    draw = ImageDraw.Draw(canvas)
    for y in range(h):
        t = y / max(h - 1, 1)
        draw.line([(0, y), (w, y)],
                  fill=tuple(int(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    return canvas


def cover(im, size, focus_y=FACE_Y):
    """Scale to fill [size], cropping around the face (None keeps the centre)."""
    tw, th = size
    scale = max(tw / im.width, th / im.height)
    w, h = round(im.width * scale), round(im.height * scale)
    im = im.resize((w, h), Image.LANCZOS)
    x = (w - tw) // 2
    y = (h - th) // 2 if focus_y is None \
        else min(max(round(h * focus_y - th * 0.42), 0), h - th)
    return im.crop((x, y, x + tw, y + th))


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


def kaleido(im):
    """Mirror axis turned to horizontal over a tilted head: two faces, chin to chin."""
    pivot = (im.width * 0.5, im.height * FACE_Y)
    tilted = im.rotate(-20, Image.BICUBIC, center=pivot)
    top = tilted.crop((im.width * 0.12, im.height * 0.03,
                       im.width * 0.88, im.height * 0.60))
    top = top.resize((im.width, round(top.height * im.width / top.width)), Image.LANCZOS)
    out = Image.new("RGB", (top.width, top.height * 2))
    out.paste(top, (0, 0))
    out.paste(top.transpose(Image.FLIP_TOP_BOTTOM), (0, top.height))
    return out


def wrap(text, f, width):
    lines, line = [], ""
    for word in text.split(" "):
        trial = f"{line} {word}".strip()
        if line and f.getlength(trial) > width:
            lines.append(line)
            line = word
        else:
            line = trial
    return lines + [line]


def headline(canvas, text, top, height, margin):
    """Largest size at which [text] fits; returns nothing, draws centred."""
    draw = ImageDraw.Draw(canvas)
    width = canvas.width - 2 * margin
    size = round(canvas.width * 0.105)
    while True:
        f = font(size, 760)
        lines = wrap(text, f, width)
        line_h = round(size * 1.14)
        if len(lines) <= 3 and len(lines) * line_h <= height \
                and all(f.getlength(l) <= width for l in lines):
            break
        size -= 2
    y = top + (height - len(lines) * line_h) // 2
    for line in lines:
        draw.text((canvas.width / 2, y), line, font=f, fill=WHITE, anchor="ma")
        y += line_h


def card(canvas, im, box, radius, glow=70, focus_y=FACE_Y):
    x0, y0, x1, y1 = box
    size = (x1 - x0, y1 - y0)
    shot = cover(im, size, focus_y)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    halo = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    halo.paste((*ACCENT, glow), (x0, y0), mask)
    halo = halo.filter(ImageFilter.GaussianBlur(radius * 0.6))
    canvas.paste(halo, (0, 0), halo)
    canvas.paste(shot, (x0, y0), mask)


def pill(canvas, text, center, size, fill=(0, 0, 0, 175), color=WHITE, weight=650,
         max_width=None):
    f = font(size, weight)
    while max_width and f.getlength(text) + size * 1.5 > max_width:
        size -= 1
        f = font(size, weight)
    w, h = round(f.getlength(text) + size * 1.5), round(size * 1.8)
    x, y = round(center[0] - w / 2), round(center[1] - h / 2)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=fill)
    draw.text((x + w / 2, y + h / 2), text, font=f, fill=color, anchor="mm")
    canvas.paste(layer, (0, 0), layer)
    return w


def labeled(canvas, im, box, label, radius, size):
    card(canvas, im, box, radius)
    x0, y0, x1, y1 = box
    pill(canvas, label, ((x0 + x1) / 2, y1 - size * 1.5), size,
         max_width=(x1 - x0) - size)


def layout(canvas):
    """(margin, content top, content bottom, radius, label size) for a canvas."""
    w, h = canvas.size
    return round(w * 0.05), round(h * 0.19), h - round(w * 0.05), round(w * 0.045), \
        round(w * 0.04 if w < 1500 else w * 0.028)


def scene_hero(canvas, t, pics, labels):
    m, top, bottom, r, ls = layout(canvas)
    w = canvas.width
    headline(canvas, t["hero"], m, top - 2 * m, m)
    gap = m // 2
    if w < 1500:
        mid = top + (bottom - top) * 44 // 100
        labeled(canvas, pics["hero"], (m, top, w - m, mid), t["original"], r, ls)
        half = (w - gap) // 2
        labeled(canvas, pics["hero_left"], (m, mid + gap, half, bottom), t["left"], r, ls)
        labeled(canvas, pics["hero_right"], (half + gap, mid + gap, w - m, bottom),
                t["right"], r, ls)
    else:
        col = (w - 2 * m - 2 * gap) // 3
        for i, (key, label) in enumerate((("hero", t["original"]),
                                          ("hero_left", t["left"]),
                                          ("hero_right", t["right"]))):
            x = m + i * (col + gap)
            labeled(canvas, pics[key], (x, top, x + col, bottom), label, r, ls)


def scene_live(canvas, t, pics, labels):
    m, top, bottom, r, ls = layout(canvas)
    w = canvas.width
    headline(canvas, t["live"], m, top - 2 * m, m)
    card(canvas, pics["hero_right"], (m, top, w - m, bottom), r)
    inset_w = round(w * (0.30 if w < 1500 else 0.24))
    inset_h = inset_w * 4 // 3
    pad = m // 2
    box = (w - m - pad - inset_w, bottom - pad - inset_h, w - m - pad, bottom - pad)
    labeled(canvas, pics["hero"], box, t["original"], r // 2, round(ls * 0.72))


def scene_filters(canvas, t, pics, labels):
    m, top, bottom, r, ls = layout(canvas)
    w = canvas.width
    headline(canvas, t["filters"], m, top - 2 * m, m)
    cols, rows = (2, 3) if w < 1500 else (3, 2)
    gap = m // 2
    cw = (w - 2 * m - (cols - 1) * gap) // cols
    ch = (bottom - top - (rows - 1) * gap) // rows
    for i, name in enumerate(GRID_FILTERS):
        x = m + (i % cols) * (cw + gap)
        y = top + (i // cols) * (ch + gap)
        key = "filter" + name[0].upper() + name[1:]
        labeled(canvas, pics[name], (x, y, x + cw, y + ch), labels[key], r, ls)


def scene_kaleido(canvas, t, pics, labels):
    m, top, bottom, r, ls = layout(canvas)
    headline(canvas, t["kaleido"], m, top - 2 * m, m)
    card(canvas, pics["kaleido"], (m, top, canvas.width - m, bottom), r, focus_y=None)


def scene_video(canvas, t, pics, labels):
    m, top, bottom, r, ls = layout(canvas)
    w = canvas.width
    headline(canvas, t["video"], m, top - 2 * m, m)
    card(canvas, pics["video"], (m, top, w - m, bottom), r)
    pill(canvas, "● 00:12", (m * 2.9, top + m * 1.1), ls, fill=(*RED, 235))
    y = bottom - ls * 2
    chips = [labels[k] for k in AUDIO_CHIPS]
    slot = (w - 2 * m) / len(chips)
    for i, label in enumerate(chips):
        pill(canvas, label, (m + slot * (i + 0.5), y), ls, max_width=slot - m / 3)


SCENES = [("hero", scene_hero), ("live", scene_live), ("filters", scene_filters),
          ("kaleido", scene_kaleido), ("video", scene_video)]


def render_filters(work, sources):
    """Run the app's shaders over the sources; returns {stem_filter: Image}."""
    src = work / "in"
    src.mkdir()
    for stem, (image, _) in sources.items():
        image.save(src / f"{stem}.png")
    names = sorted({n for _, wanted in sources.values() for n in wanted})
    out = work / "out"
    subprocess.run(
        ["flutter", "test", "tool/store_filter_render_test.dart"],
        cwd=APP, check=True, stdout=subprocess.DEVNULL,
        env={**os.environ, "STORE_IN": str(src), "STORE_OUT": str(out),
             "STORE_FILTERS": ",".join(names)},
    )
    return {p.stem: Image.open(p).convert("RGB").copy() for p in out.glob("*.png")}


def main():
    argv = sys.argv[1:]
    wanted = argv[argv.index("--locales") + 1].split(",") if "--locales" in argv \
        else list(LOCALES)

    faces, sources = {}, {}
    for key, (name, midline) in FACES.items():
        im = Image.open(HERE / "faces" / name).convert("RGB")
        left, right = mirror(im, midline, True), mirror(im, midline, False)
        faces[key] = (im, left, right)
        sources[f"{key}_grid"] = (right, GRID_FILTERS)
        sources[f"{key}_kaleido"] = (kaleido(im), [KALEIDO_FILTER])
        sources[f"{key}_video"] = (left, [VIDEO_FILTER])

    with tempfile.TemporaryDirectory() as tmp:
        filtered = render_filters(pathlib.Path(tmp), sources)

    for locale in wanted:
        arb, hero, other = LOCALES[locale]
        labels = json.loads((APP / "lib" / "l10n" / f"app_{arb}.arb").read_text())
        im, left, right = faces[hero]
        pics = {
            "hero": im, "hero_left": left, "hero_right": right,
            "kaleido": filtered[f"{other}_kaleido_{KALEIDO_FILTER}"],
            "video": filtered[f"{other}_video_{VIDEO_FILTER}"],
            **{n: filtered[f"{other}_grid_{n}"] for n in GRID_FILTERS},
        }
        dest = OUT / locale
        shutil.rmtree(dest, ignore_errors=True)
        dest.mkdir(parents=True)
        for device, size in TARGETS.items():
            for i, (name, draw) in enumerate(SCENES, start=1):
                canvas = gradient(size)
                draw(canvas, COPY[locale], pics, labels)
                canvas.save(dest / f"{i:02d}_{name}_{device}.png", "PNG", optimize=True)
        print(locale, len(list(dest.glob("*.png"))), "shots")

    for locale, source in COPIES.items():
        if source in wanted:
            shutil.rmtree(OUT / locale, ignore_errors=True)
            shutil.copytree(OUT / source, OUT / locale)
            print(locale, "copied from", source)


if __name__ == "__main__":
    main()
