#!/usr/bin/env python3
"""Render the Google Play promo video (1920x1080, 30 fps, ~45 s, silent).

    python3 store/play/make_trailer.py [--lang en|cs] [--render] [--out DIR]

Play takes the promo video only as a YouTube link, landscape. This builds it
from the App Store preview clips (store/appstore/make_previews.py: the real
FilterStrip, composer and shaders on the fictional faces), nothing else:

  intro card    3 s    listing icon, name, tagline
  triptych 1   26 s    three full clips side by side, in sync
  triptych 2   11.6 s  three more clips, filter + mirror-axis phases only
  outro card    4 s    icon, name, two lines

with 0.5 s fades through the dark background. Card texts and the YouTube title/description live in
store/play/trailer_text.json. Clips are read from
store/appstore/previews/<lang>/ (git-ignored); --render renders the missing
ones with make_previews.py first (slow: a few minutes per clip).
Output: store/play/trailer/mirrorbooth_trailer_<lang>.mp4 (git-ignored).
"""
import json
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
PREVIEWS = REPO / "store" / "appstore" / "previews"
ICON = HERE / "graphics" / "icon-512-kaleido.png"
TEXT = json.loads((HERE / "trailer_text.json").read_text())

FULL = ["05_cat_oil", "12_comic_demon", "13_alien_cyborg"]
CUT = ["06_dog_comic", "08_bunny_frozen", "10_porcelain_ghost"]
# Filter and mirror-axis phases of a 26 s clip (see store_preview_render_test).
CUT_FROM, CUT_LEN = 7.0, 11.6

W, H, FPS = 1920, 1080, 30
INTRO, FULL_LEN, OUTRO, FADE = 3.0, 26.0, 4.0, 0.5
CLIP_H, GAP = 1000, 24
CLIP_W = round(886 * CLIP_H / 1920 / 2) * 2

FONT = "/System/Library/Fonts/SFNS.ttf"
BG_TOP = (13, 10, 20)
BG_BOTTOM = (36, 24, 60)
ACCENT = (216, 180, 254)
WHITE = (245, 242, 250)
MUTED = (180, 170, 200)


def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def background():
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(
            round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    return im


def card(title, lines, sizes):
    im = background()
    d = ImageDraw.Draw(im)
    icon = Image.open(ICON).convert("RGBA").resize((260, 260), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 259, 259), 58, fill=255)
    block = 260 + 50 + 130 + sum(s + 34 for s, _ in sizes)
    y = (H - block) // 2
    im.paste(icon, ((W - 260) // 2, y), mask)
    y += 260 + 50
    f = font(120, 700)
    d.text(((W - d.textlength(title, font=f)) / 2, y), title, font=f,
           fill=ACCENT)
    y += 130 + 34
    for text, (size, color) in zip(lines, sizes):
        f = font(size, 500)
        d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f,
               fill=color)
        y += size + 34
    return im


def main():
    argv = sys.argv[1:]
    lang, out = "en", HERE / "trailer"
    if "--lang" in argv:
        i = argv.index("--lang")
        lang = argv[i + 1]
        del argv[i:i + 2]
    if "--out" in argv:
        i = argv.index("--out")
        out = pathlib.Path(argv[i + 1])
        del argv[i:i + 2]
    text = TEXT[lang]
    src = PREVIEWS / lang
    missing = [n for n in FULL + CUT if not (src / f"{n}.mp4").exists()]
    if missing:
        if "--render" not in argv:
            raise SystemExit(f"missing clips in {src}: {', '.join(missing)} "
                             "(pass --render)")
        subprocess.run([sys.executable, str(REPO / "store/appstore/make_previews.py"),
                        "--lang", lang, *missing], check=True)

    out.mkdir(parents=True, exist_ok=True)
    dst = out / f"mirrorbooth_trailer_{lang}.mp4"
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        card(text["title"], [text["tagline"]],
             [(64, WHITE)]).save(tmp / "intro.png")
        card(text["title"], text["outro"],
             [(56, WHITE), (48, MUTED)]).save(tmp / "outro.png")
        background().save(tmp / "bg.png")

        # One segment at a time, then a stream-copy concat: a single graph
        # with cross-fades buffers whole segments in RAM.
        norm = f"fps={FPS},format=yuv420p,setsar=1"
        x0 = (W - 3 * CLIP_W - 2 * GAP) // 2
        y0 = (H - CLIP_H) // 2
        dark = "0x%02x%02x%02x" % BG_TOP
        segments = [
            ("intro", INTRO, ["-loop", "1", "-i", str(tmp / "intro.png")], None),
            ("full", FULL_LEN, [], [(n, 0.0) for n in FULL]),
            ("cut", CUT_LEN, [], [(n, CUT_FROM) for n in CUT]),
            ("outro", OUTRO, ["-loop", "1", "-i", str(tmp / "outro.png")], None),
        ]
        parts = []
        for i, (name, length, inputs, clips) in enumerate(segments):
            fades = []
            if i:
                fades.append(f"fade=t=in:d={FADE}:color={dark}")
            if i < len(segments) - 1:
                fades.append(f"fade=t=out:st={length - FADE}:d={FADE}"
                             f":color={dark}")
            if clips:
                inputs = ["-loop", "1", "-i", str(tmp / "bg.png")]
                g, prev = [], "0:v"
                for k, (n, ss) in enumerate(clips):
                    inputs += ["-ss", str(ss), "-i", str(src / f"{n}.mp4")]
                    g.append(f"[{k + 1}:v]scale={CLIP_W}:{CLIP_H}"
                             f":flags=lanczos[c{k}]")
                    g.append(f"[{prev}][c{k}]overlay={x0 + k * (CLIP_W + GAP)}"
                             f":{y0}:shortest=1[t{k}]")
                    prev = f"t{k}"
                g.append(f"[{prev}]{','.join([norm] + fades)}[v]")
                graph = ["-filter_complex", ";".join(g), "-map", "[v]"]
            else:
                graph = ["-vf", ",".join([norm] + fades)]
            part = tmp / f"{i}_{name}.mp4"
            subprocess.run(
                ["ffmpeg", "-v", "error", "-y", "-framerate", str(FPS), *inputs,
                 *graph, "-t", str(length), "-an",
                 "-c:v", "libx264", "-preset", "slow", "-crf", "17",
                 "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", str(FPS),
                 "-video_track_timescale", "15360", str(part)],
                check=True)
            parts.append(part)
        (tmp / "list.txt").write_text(
            "".join(f"file '{p}'\n" for p in parts))
        total = INTRO + FULL_LEN + CUT_LEN + OUTRO
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y",
             "-f", "concat", "-safe", "0", "-i", str(tmp / "list.txt"),
             "-f", "lavfi", "-i",
             "anullsrc=channel_layout=stereo:sample_rate=48000",
             "-map", "0:v", "-map", "1:a", "-c:v", "copy",
             "-c:a", "aac", "-b:a", "128k", "-t", f"{total:.2f}",
             "-movflags", "+faststart", str(dst)],
            check=True)
    print(f"{dst} ({total:.1f} s)")


if __name__ == "__main__":
    main()
