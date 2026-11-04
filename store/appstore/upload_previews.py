#!/usr/bin/env python3
"""Replace the iPhone app previews of an editable App Store version.

    ASC_KEY_PATH=… ASC_KEY_ID=… ASC_ISSUER_ID=… \
        python3 store/appstore/upload_previews.py 2.3.4 [pt-BR fr-FR …]

Takes the clips rendered by make_previews.py from previews/<lang>/, where
<lang> is the store locale's language (pt-BR -> pt). App Store shows at most
three previews per locale; CLIPS picks them. Defaults to the locales that have
localized screenshots.
"""
import hashlib
import pathlib
import sys
import time

from asc_api import call
from upload_screenshots import find_version, put

HERE = pathlib.Path(__file__).resolve().parent
PREVIEW_TYPE = "IPHONE_67"  # 886x1920 serves the 6.9" and 6.7" slots
CLIPS = ["01_bia_neon", "02_zoe_chibi", "04_miko_glitch"]
LOCALES = ["en-US", "en-GB", "en-AU", "en-CA", "pt-BR", "es-MX", "es-ES", "fr-FR"]
# Poster frame (HH:MM:SS:FF): left+left, the wink mirrored into closed eyes.
POSTER = "00:00:02:15"


def replace_set(localization_id, files):
    sets = call("GET", f"/v1/appStoreVersionLocalizations/{localization_id}"
                       "/appPreviewSets?limit=30")["data"]
    current = next((s for s in sets
                    if s["attributes"]["previewType"] == PREVIEW_TYPE), None)
    if current is None:
        current = call("POST", "/v1/appPreviewSets", {"data": {
            "type": "appPreviewSets",
            "attributes": {"previewType": PREVIEW_TYPE},
            "relationships": {"appStoreVersionLocalization": {"data": {
                "type": "appStoreVersionLocalizations", "id": localization_id}}},
        }})["data"]
    set_id = current["id"]
    for old in call("GET", f"/v1/appPreviewSets/{set_id}/appPreviews?limit=30")["data"]:
        call("DELETE", f"/v1/appPreviews/{old['id']}")

    ids = []
    for path in files:
        data = path.read_bytes()
        preview = call("POST", "/v1/appPreviews", {"data": {
            "type": "appPreviews",
            "attributes": {"fileName": path.name, "fileSize": len(data),
                           "mimeType": "video/mp4", "previewFrameTimeCode": POSTER},
            "relationships": {"appPreviewSet": {"data": {
                "type": "appPreviewSets", "id": set_id}}},
        }})["data"]
        for part in preview["attributes"]["uploadOperations"]:
            put(part, data[part["offset"]:part["offset"] + part["length"]])
        call("PATCH", f"/v1/appPreviews/{preview['id']}", {"data": {
            "type": "appPreviews", "id": preview["id"],
            "attributes": {"uploaded": True,
                           "sourceFileChecksum": hashlib.md5(data).hexdigest()},
        }})
        ids.append(preview["id"])

    call("PATCH", f"/v1/appPreviewSets/{set_id}/relationships/appPreviews", {
        "data": [{"type": "appPreviews", "id": i} for i in ids]})
    return set_id


def state(preview):
    a = preview["attributes"]
    return (a.get("videoDeliveryState") or a.get("assetDeliveryState") or {}).get("state")


def wait_complete(set_id):
    # Apple transcodes every clip; that takes minutes, not seconds.
    for _ in range(120):
        previews = call("GET", f"/v1/appPreviewSets/{set_id}/appPreviews?limit=30")["data"]
        states = [state(p) for p in previews]
        if all(s in ("COMPLETE", "FAILED") for s in states):
            return previews
        time.sleep(10)
    return previews


def main():
    version, *wanted = sys.argv[1:]
    version_id = find_version(version)
    locales = call("GET", f"/v1/appStoreVersions/{version_id}"
                          "/appStoreVersionLocalizations?limit=50")["data"]
    by_locale = {l["attributes"]["locale"]: l["id"] for l in locales}

    done = []
    for locale in wanted or LOCALES:
        if locale not in by_locale:
            print(locale, "not in this version, skipped", flush=True)
            continue
        folder = HERE / "previews" / locale.split("-")[0]
        files = [folder / f"{name}.mp4" for name in CLIPS]
        missing = [f.name for f in files if not f.exists()]
        if missing:
            raise SystemExit(f"{locale}: missing {missing} in {folder}")
        done.append((locale, replace_set(by_locale[locale], files)))
        print(locale, len(files), "uploaded", flush=True)
    failed = 0
    for locale, set_id in done:
        previews = wait_complete(set_id)
        for p in previews:
            if state(p) != "COMPLETE":
                failed += 1
                a = p["attributes"]
                errors = (a.get("videoDeliveryState") or a.get("assetDeliveryState") or {})
                print(locale, a["fileName"], state(p), errors.get("errors"), flush=True)
        print(locale, sum(state(p) == "COMPLETE" for p in previews), "of",
              len(previews), "complete", flush=True)
    if failed:
        raise SystemExit(f"{failed} previews did not finish processing")


if __name__ == "__main__":
    main()
