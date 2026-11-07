#!/usr/bin/env python3
"""Render 1024x1024 app icon candidates for Mirror Booth.

    python3 store/icon/make_icon_candidates.py [--skip-flux] [--skip-derived]

Two families land in store/icon/candidates/ (git-ignored):

  flux_<style>_<seed>.png   graphic icons from Flux on ComfyUI (same server
                            and credentials as store/appstore/generate_faces.py)
  face_<face>_<filter>.png  a character face from store/appstore/faces,
                            mirrored the way the app mirrors and run through
                            the app's own filter shaders

Square, full bleed, no transparency and no text: iOS masks the corners and
Play crops to its own shape.
"""
import json
import pathlib
import sys
import tempfile
import time
import urllib.parse

from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
APPSTORE = HERE.parent / "appstore"
sys.path.insert(0, str(APPSTORE))
import generate_faces as gf  # noqa: E402
import make_appstore_shots as shots  # noqa: E402

OUT = HERE / "candidates"
SIZE = 1024
SEEDS = (9101, 9102)

ICON = ("Mobile app icon artwork, square, full bleed edge to edge, perfectly "
        "centered, bold simple shapes that read at small sizes, no text, no "
        "letters, no border, no rounded corners. ")

FLUX = {
    "splitface": "A stylized human face split vertically down the middle by "
                 "a thin glowing mirror line, both halves identical, flat "
                 "vector illustration, deep purple to lilac gradient "
                 "background.",
    "vase": "Two identical face profiles facing each other forming a vase "
            "silhouette in the negative space between them, glowing neon "
            "lilac lines on a deep midnight purple background.",
    "handmirror": "A glossy 3D hand mirror whose reflection shows a cheeky "
                  "winking face, soft studio lighting, pastel lilac "
                  "background.",
    "kaleido": "A kaleidoscope made of one smiling face mirrored four times "
               "around the centre, vivid pop art colours, halftone dots.",
    "halfcat": "A cute cat face, the left half realistic fur, the right half "
               "a flat pop art cartoon, split on a crisp vertical line, "
               "lilac background.",
    "booth": "A tiny retro photo booth with a velvet curtain, a symmetric "
             "smiley face glowing on the curtain, cosy purple lighting, "
             "3D clay style.",
}

# face file, facial midline, filter (None = unfiltered mirror)
DERIVED = [
    ("bia_4711.png", 0.50, None), ("bia_4711.png", 0.50, "neon"),
    ("cat_6101.png", 0.50, None), ("cat_6101.png", 0.50, "popArt"),
    ("bunny_6402.png", 0.50, "glow"), ("chibi_6701.png", 0.50, "comic"),
    ("alien_6901.png", 0.50, "thermal"), ("comic_6811.png", 0.50, "popArt"),
    ("miko_5002.png", 0.50, "glitch"), ("porcelain_6601.png", 0.50, "oil"),
]


def flux():
    pending = {}
    for style, prompt in FLUX.items():
        for seed in SEEDS:
            dest = OUT / f"flux_{style}_{seed}.png"
            if dest.exists():
                continue
            wf = gf.workflow(ICON + prompt, seed)
            wf["5"]["inputs"].update(width=SIZE, height=SIZE)
            body = json.dumps({"prompt": wf}).encode()
            pending[json.loads(gf.request("/prompt", body))["prompt_id"]] = dest
    while pending:
        time.sleep(5)
        for pid, dest in list(pending.items()):
            entry = json.loads(gf.request(f"/history/{pid}")).get(pid)
            if not entry:
                continue
            if entry.get("status", {}).get("status_str") == "error":
                raise SystemExit(f"ComfyUI failed on {dest.name}")
            image = entry["outputs"]["8"]["images"][0]
            dest.write_bytes(gf.request("/view?" + urllib.parse.urlencode(image)))
            print(dest.name, flush=True)
            del pending[pid]


def square(im, midline):
    """Right+right mirror, cropped square around the eyes."""
    m = shots.mirror(im, midline, keep_left=False)
    side = min(m.width, m.height)
    top = min(max(round(m.height * shots.FACE_Y - side * 0.45), 0), m.height - side)
    x = (m.width - side) // 2
    return m.crop((x, top, x + side, top + side)).resize((SIZE, SIZE), Image.LANCZOS)


def derived():
    sources = {}
    for name, midline, filt in DERIVED:
        stem = name.split("_")[0]
        im = Image.open(APPSTORE / "faces" / name).convert("RGB")
        sq = square(im, midline)
        if filt is None:
            sq.save(OUT / f"face_{stem}_mirror.png")
            print(f"face_{stem}_mirror.png", flush=True)
        else:
            src, wanted = sources.setdefault(stem, (sq, []))
            wanted.append(filt)
    if not sources:
        return
    with tempfile.TemporaryDirectory() as tmp:
        out = shots.render_filters(pathlib.Path(tmp), sources)
    for key, im in out.items():
        stem, filt = key.split("_", 1)
        # The renderer runs every filter over every source; keep the pairs asked for.
        if filt not in sources[stem][1]:
            continue
        im.resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"face_{stem}_{filt}.png")
        print(f"face_{stem}_{filt}.png", flush=True)


def main():
    OUT.mkdir(exist_ok=True)
    if "--skip-derived" not in sys.argv:
        derived()
    if "--skip-flux" not in sys.argv:
        flux()


if __name__ == "__main__":
    main()
