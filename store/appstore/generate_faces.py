#!/usr/bin/env python3
"""Generate the fictional demo faces used in the App Store screenshots.

    python3 store/appstore/generate_faces.py [--seeds 3] [name ...]

Needs COMFYUI_API_URL (default https://comfyui.ol1n.com) and the
CF_ACCESS_CLIENT_ID / CF_ACCESS_CLIENT_SECRET service token. Every face is a
Flux render of nobody in particular: the listing must never show a real person
without a release. Output: store/appstore/faces/<name>_<seed>.png
"""
import json
import os
import pathlib
import sys
import time
import urllib.parse
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
API = os.environ.get("COMFYUI_API_URL", "https://comfyui.ol1n.com").rstrip("/")
WIDTH, HEIGHT = 1024, 1408

STYLE = (
    "Candid front-camera selfie photo, head and shoulders, the face dead centre "
    "of the frame, looking straight into the lens, head perfectly upright, "
    "natural soft window daylight, plain softly blurred apartment background, "
    "real skin texture with pores, natural asymmetry between the two sides of "
    "the face, a lopsided half smile raised on one side, one eyebrow slightly "
    "higher than the other, photorealistic, sharp focus on the eyes."
)

# The video previews flip between left+left and right+right, which only
# reads if the two halves differ a lot; replaces STYLE for those faces.
WINK_STYLE = (
    "Candid front-camera selfie photo, head and shoulders, the face dead centre "
    "of the frame, looking straight into the lens, head perfectly upright, "
    "playful wink: the left eye firmly shut, the right eye wide open, a crooked "
    "grin pulled up on one side only, the eyebrow above the open eye arched "
    "high, natural soft window daylight, plain softly blurred apartment "
    "background, real skin texture, photorealistic, sharp focus."
)

# Drawn rather than photographed, with the same wink.
MANGA_STYLE = (
    "Clean manga anime illustration, cel shading, crisp ink line art, the face "
    "dead centre of the frame, looking straight at the viewer, head perfectly "
    "upright, head and shoulders, playful wink: one eye shut as a curved line, "
    "the other big sparkling eye wide open, a crooked grin on one side only, "
    "soft pastel background."
)

# Non-human stars (animals, toys, cartoons): the subject sentence carries the
# look, this adds the framing and the lopsided expression the L/R flip needs.
CHARACTER_STYLE = (
    "Front-facing close-up portrait, the face dead centre of the frame, "
    "looking straight into the lens, head perfectly upright, head and "
    "shoulders, playful wink: one eye shut, the other eye wide open, a crooked "
    "grin pulled up on one side only, one ear or eyebrow raised higher than "
    "the other, soft even light, plain softly blurred pastel background, "
    "sharp focus."
)

# Strongly lopsided human faces for the left+left vs right+right demos.
ASYM_STYLE = (
    "Candid front-camera selfie photo, head and shoulders, the face dead centre "
    "of the frame, looking straight into the lens, head perfectly upright, "
    "a strongly asymmetric face: one eye squinting, the other wide open, a "
    "crooked smile on one side only, one eyebrow raised high, natural soft "
    "window daylight, plain softly blurred apartment background, real skin "
    "texture, photorealistic, sharp focus."
)

# name -> (seed base, person[, style]). ana, rafa and lea are the screenshot
# faces; bia, zoe, theo and miko star in the video previews (make_previews.py).
FACES = {
    "ana": (4101, "A 29 year old Brazilian woman with warm brown skin and long "
                  "dark curly hair falling over one shoulder, parted to one side."),
    "rafa": (4202, "A 34 year old Mexican man with olive skin, short dark hair "
                   "swept to one side and a trimmed beard."),
    "lea": (4303, "A 31 year old French woman with fair freckled skin and a "
                  "chestnut asymmetric bob haircut tucked behind one ear."),
    "bia": (4711, "A 32 year old Brazilian woman with warm brown skin, cheekily "
                  "winking at the camera with one eye squeezed shut, long dark "
                  "hair all swept over one shoulder and a single big hoop "
                  "earring on one ear.", WINK_STYLE),
    "zoe": (4801, "A cheerful 10 year old girl with light brown skin, freckles "
                  "and a single thick braid over one shoulder, wearing a "
                  "yellow t-shirt.", WINK_STYLE),
    "theo": (4901, "A cheeky 11 year old boy with pale skin, messy sandy blond "
                   "hair flopping over one side of his forehead and a "
                   "gap-toothed grin.", WINK_STYLE),
    "miko": (5001, "A teenage anime girl with short teal hair, a long fringe "
                   "covering one side of her forehead and a hair clip on the "
                   "other side.", MANGA_STYLE),
    # Characters for the extra previews (make_previews.py). Generic designs
    # only: no branded toy or comic character.
    "cat": (6101, "Photo of a fluffy ginger tabby cat with one ear folded "
                  "down and a white patch over one eye.", CHARACTER_STYLE),
    "dog": (6201, "Photo of a scruffy beagle puppy with one floppy ear flipped "
                  "inside out and a brown patch around one eye.", CHARACTER_STYLE),
    "bear": (6301, "Photo of a well-loved brown plush teddy bear with a "
                   "stitched patch on one cheek, one button eye larger than "
                   "the other and a ribbon bow on one ear.", CHARACTER_STYLE),
    "bunny": (6401, "Photo of a soft pastel pink plush bunny toy with one long "
                    "ear standing up and the other flopped down.", CHARACTER_STYLE),
    "fashiondoll": (6501, "Photo of a generic plastic fashion doll with glossy "
                          "platinum blonde hair swept over one shoulder, pink "
                          "lipstick, a pink outfit and one big heart earring, "
                          "unbranded.", CHARACTER_STYLE),
    "porcelain": (6601, "Photo of an antique porcelain doll with painted rosy "
                        "cheeks, glass eyes, auburn ringlets on one side and a "
                        "lace bonnet tilted to one side.", CHARACTER_STYLE),
    "chibi": (6701, "Cute chibi anime character illustration, huge head, "
                    "pink twin tails of different lengths, a star hair clip on "
                    "one side, big sparkling eyes.", CHARACTER_STYLE),
    "comic": (6811, "Bold retro comic book illustration of an original "
                    "superheroine with spiky orange hair, a small red domino "
                    "eye mask and a lightning bolt badge, no hood, no cowl, "
                    "no ears on the mask, thick ink outlines, halftone dots, "
                    "a strand of hair falling over one side.",
              CHARACTER_STYLE),
    "alien": (6901, "Photo of a friendly green alien with big glossy black "
                    "eyes, a single antenna bent to one side and a smooth "
                    "head.", CHARACTER_STYLE),
    "nora": (7001, "A 27 year old Nigerian woman with dark skin and short "
                   "natural hair shaved on one side.", ASYM_STYLE),
    "kenji": (7101, "A 40 year old Japanese man with a salt and pepper beard "
                    "and hair parted hard to one side.", ASYM_STYLE),
}


def request(path, data=None):
    req = urllib.request.Request(API + path, data=data, headers={
        "CF-Access-Client-Id": os.environ["CF_ACCESS_CLIENT_ID"],
        "CF-Access-Client-Secret": os.environ["CF_ACCESS_CLIENT_SECRET"],
        "Content-Type": "application/json",
        "User-Agent": "mirrorbooth-store-assets",
    })
    with urllib.request.urlopen(req, timeout=60) as res:
        return res.read()


def workflow(prompt, seed):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {
            "unet_name": "flux1-dev.safetensors", "weight_dtype": "default"}},
        "2": {"class_type": "DualCLIPLoader", "inputs": {
            "clip_name1": "t5xxl_fp16.safetensors", "clip_name2": "clip_l.safetensors",
            "type": "flux"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "4": {"class_type": "CLIPTextEncodeFlux", "inputs": {
            "clip": ["2", 0], "clip_l": prompt, "t5xxl": prompt, "guidance": 3.0}},
        "5": {"class_type": "EmptySD3LatentImage", "inputs": {
            "width": WIDTH, "height": HEIGHT, "batch_size": 1}},
        "6": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 26, "cfg": 1, "sampler_name": "euler",
            "scheduler": "simple", "denoise": 1, "model": ["1", 0],
            "positive": ["4", 0], "negative": ["4", 0], "latent_image": ["5", 0]}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["6", 0], "vae": ["3", 0]}},
        "8": {"class_type": "SaveImage", "inputs": {
            "filename_prefix": "mirrorbooth_face", "images": ["7", 0]}},
    }


def main():
    argv = sys.argv[1:]
    count = int(argv[argv.index("--seeds") + 1]) if "--seeds" in argv else 3
    out = HERE / "faces"
    out.mkdir(exist_ok=True)

    only = [a for a in argv if a in FACES]

    pending = {}
    for name, (base, person, *style) in FACES.items():
        if only and name not in only:
            continue
        for seed in range(base, base + count):
            dest = out / f"{name}_{seed}.png"
            if dest.exists():
                continue
            body = json.dumps({"prompt": workflow(f"{person} {style[0] if style else STYLE}", seed)}).encode()
            pending[json.loads(request("/prompt", body))["prompt_id"]] = dest

    while pending:
        time.sleep(5)
        for pid, dest in list(pending.items()):
            entry = json.loads(request(f"/history/{pid}")).get(pid)
            if not entry:
                continue
            if entry.get("status", {}).get("status_str") == "error":
                raise SystemExit(f"ComfyUI failed on {dest.name}: {entry['status']}")
            image = entry["outputs"]["8"]["images"][0]
            query = urllib.parse.urlencode(image)
            dest.write_bytes(request(f"/view?{query}"))
            print(dest.relative_to(HERE.parent.parent), flush=True)
            del pending[pid]


if __name__ == "__main__":
    main()
