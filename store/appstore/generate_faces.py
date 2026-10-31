#!/usr/bin/env python3
"""Generate the fictional demo faces used in the App Store screenshots.

    python3 store/appstore/generate_faces.py [--seeds 3]

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

# name -> (seed base, person)
FACES = {
    "ana": (4101, "A 29 year old Brazilian woman with warm brown skin and long "
                  "dark curly hair falling over one shoulder, parted to one side."),
    "rafa": (4202, "A 34 year old Mexican man with olive skin, short dark hair "
                   "swept to one side and a trimmed beard."),
    "lea": (4303, "A 31 year old French woman with fair freckled skin and a "
                  "chestnut asymmetric bob haircut tucked behind one ear."),
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

    pending = {}
    for name, (base, person) in FACES.items():
        for seed in range(base, base + count):
            dest = out / f"{name}_{seed}.png"
            if dest.exists():
                continue
            body = json.dumps({"prompt": workflow(f"{person} {STYLE}", seed)}).encode()
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
