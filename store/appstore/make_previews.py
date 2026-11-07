#!/usr/bin/env python3
"""Render the App Store preview clips (886x1920, 26 s, 30 fps, silent stereo).

    python3 store/appstore/make_previews.py [--lang en|pt|es|fr] [--short] [name ...]

--short renders the ~17 s App Store cut (<name>_short.mp4): it opens on the
mirrored face and leaves out the image rotation.

Each clip opens on the unmirrored face, flips between left+left and
right+right, browses a few filters on the real FilterStrip, lands on its own
shader, then turns the mirror axis and rotates the whole image. The frames
come from mirrorbooth/tool/store_preview_render_test.dart (real composer and
shaders); faces are the fictional renders from generate_faces.py.
Captions and the app UI follow --lang (default en).
Output: store/appstore/previews/<lang>/<name>.mp4 (git-ignored).
"""
import os
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
APP = HERE.parent.parent / "mirrorbooth"

# name -> (face, filters browsed; the last one stays on[, English captions])
# Character clips (05+) lean on the paid Art and Fantasy filters.
CLIPS = {
    "01_bia_neon": ("bia_4711", "glow,comic,neon"),
    "02_zoe_chibi": ("zoe_4803", "glow,doll,chibi"),
    "03_theo_alien": ("theo_4903", "bigNose,bigEars,alien"),
    "04_miko_glitch": ("miko_5002", "pencil,comic,glitch"),
    "05_cat_oil": ("cat_6101", "chibi,popArt,oil",
                   "Your real cat|Left + left|Right + right|Pick a filter|"
                   "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "06_dog_comic": ("dog_6201", "bigEars,thermal,comic",
                     "Your real pup|Left + left|Right + right|Pick a filter|"
                     "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "07_bear_pencil": ("bear_6303", "glow,crt,pencil",
                       "Your teddy|Left + left|Right + right|Pick a filter|"
                       "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "08_bunny_frozen": ("bunny_6402", "doll,neon,frozen",
                        "Your plushie|Left + left|Right + right|Pick a filter|"
                        "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "09_fashiondoll_pop": ("fashiondoll_6501", "doll,lips,popArt",
                           "Your doll|Left + left|Right + right|Pick a filter|"
                           "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "10_porcelain_ghost": ("porcelain_6601", "glow,oil,ghost",
                           "Your doll|Left + left|Right + right|Pick a filter|"
                           "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "11_chibi_glitch": ("chibi_6701", "chibi,neon,glitch",
                        "Cartoons too|Left + left|Right + right|Pick a filter|"
                        "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "12_comic_demon": ("comic_6811", "comic,popArt,demon",
                       "Comic heroes too|Left + left|Right + right|Pick a filter|"
                       "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "13_alien_cyborg": ("alien_6901", "alien,thermal,cyborg",
                        "Aliens too|Left + left|Right + right|Pick a filter|"
                        "Turn the mirror axis|Rotate the image|Mirror Booth"),
    "14_nora_vampire": ("nora_7003", "slim,oil,vampire"),
    "15_kenji_zombie": ("kenji_7101", "bigNose,pencil,zombie"),
}

# Seven captions per language, in the order of the clip's phases.
CAPTIONS = {
    "en": None,  # the renderer's own defaults
    "pt": "Seu rosto real|Esquerda + esquerda|Direita + direita|"
          "Escolha um filtro|Gire o eixo do espelho|Gire a imagem|Mirror Booth",
    "es": "Tu cara real|Izquierda + izquierda|Derecha + derecha|"
          "Elige un filtro|Gira el eje del espejo|Gira la imagen|Mirror Booth",
    "fr": "Ton vrai visage|Gauche + gauche|Droite + droite|"
          "Choisis un filtre|Tourne l'axe du miroir|Tourne l'image|Mirror Booth",
}


def main():
    argv = sys.argv[1:]
    lang = "en"
    if "--lang" in argv:
        i = argv.index("--lang")
        lang = argv[i + 1]
        del argv[i:i + 2]
    short = "--short" in argv
    if short:
        argv.remove("--short")
    names = argv or list(CLIPS)
    out = HERE / "previews" / lang
    out.mkdir(parents=True, exist_ok=True)
    failed = []
    # One at a time: parallel flutter test runs race on the shared build/ dir.
    for name in names:
        face, filters, *own = CLIPS[name]
        env = dict(os.environ,
                   PREVIEW_FACE=str(HERE / "faces" / f"{face}.png"),
                   PREVIEW_OUT=str(out / f"{name}{'_short' if short else ''}.mp4"),
                   PREVIEW_SHORT="1" if short else "0",
                   PREVIEW_FILTERS=filters,
                   PREVIEW_LOCALE=lang)
        if CAPTIONS[lang]:
            env["PREVIEW_CAPTIONS"] = CAPTIONS[lang]
        elif own:
            env["PREVIEW_CAPTIONS"] = own[0]
        log = out / f"{name}{'_short' if short else ''}.log"
        with open(log, "w") as f:
            code = subprocess.run(
                ["flutter", "test", "tool/store_preview_render_test.dart"],
                cwd=APP, env=env, stdout=f, stderr=subprocess.STDOUT).returncode
        print(f"{name}: {'ok' if code == 0 else 'FAILED, see ' + str(log)}",
              flush=True)
        if code:
            failed.append(name)
    if failed:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
