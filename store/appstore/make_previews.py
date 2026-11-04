#!/usr/bin/env python3
"""Render the App Store preview clips (886x1920, 26 s, 30 fps, silent stereo).

    python3 store/appstore/make_previews.py [--lang en|pt|es|fr] [name ...]

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

# name -> (face, filters browsed; the last one stays on)
CLIPS = {
    "01_bia_neon": ("bia_4711", "glow,comic,neon"),
    "02_zoe_chibi": ("zoe_4803", "glow,doll,chibi"),
    "03_theo_alien": ("theo_4903", "bigNose,bigEars,alien"),
    "04_miko_glitch": ("miko_5002", "pencil,comic,glitch"),
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
    names = argv or list(CLIPS)
    out = HERE / "previews" / lang
    out.mkdir(parents=True, exist_ok=True)
    failed = []
    # One at a time: parallel flutter test runs race on the shared build/ dir.
    for name in names:
        face, filters = CLIPS[name]
        env = dict(os.environ,
                   PREVIEW_FACE=str(HERE / "faces" / f"{face}.png"),
                   PREVIEW_OUT=str(out / f"{name}.mp4"),
                   PREVIEW_FILTERS=filters,
                   PREVIEW_LOCALE=lang)
        if CAPTIONS[lang]:
            env["PREVIEW_CAPTIONS"] = CAPTIONS[lang]
        log = out / f"{name}.log"
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
