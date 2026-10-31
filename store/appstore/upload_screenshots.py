#!/usr/bin/env python3
"""Replace the screenshots of an editable App Store version.

    ASC_KEY_PATH=… ASC_KEY_ID=… ASC_ISSUER_ID=… \
        python3 store/appstore/upload_screenshots.py 2.3.4 [pt-BR fr-FR …]

Takes every locale folder in screenshots/ unless locales are named. Only the
named version changes, and a locale it does not list is reported and skipped.
"""
import hashlib
import pathlib
import sys
import time
import urllib.request

from asc_api import APP_ID, call

HERE = pathlib.Path(__file__).resolve().parent
DISPLAY_TYPES = {"iphone": "APP_IPHONE_67", "ipad": "APP_IPAD_PRO_3GEN_129"}


def find_version(version):
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions"
                           f"?filter[versionString]={version}&filter[platform]=IOS")["data"]
    if not versions or versions[0]["attributes"]["appVersionState"] != "PREPARE_FOR_SUBMISSION":
        raise SystemExit(f"{version} is not an editable version")
    return versions[0]["id"]


def put(part, chunk, attempts=5):
    """Apple's upload hosts drop connections now and then; retry the chunk."""
    for attempt in range(1, attempts + 1):
        try:
            urllib.request.urlopen(urllib.request.Request(
                part["url"], data=chunk, method=part["method"],
                headers={h["name"]: h["value"] for h in part["requestHeaders"]},
            ), timeout=300).read()
            return
        except OSError:
            if attempt == attempts:
                raise
            time.sleep(5 * attempt)


def replace_set(localization_id, display_type, files):
    sets = call("GET", f"/v1/appStoreVersionLocalizations/{localization_id}"
                       "/appScreenshotSets?limit=30")["data"]
    current = next((s for s in sets
                    if s["attributes"]["screenshotDisplayType"] == display_type), None)
    if current is None:
        current = call("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {"appStoreVersionLocalization": {"data": {
                "type": "appStoreVersionLocalizations", "id": localization_id}}},
        }})["data"]
    set_id = current["id"]
    for old in call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=30")["data"]:
        call("DELETE", f"/v1/appScreenshots/{old['id']}")

    ids = []
    for path in files:
        data = path.read_bytes()
        shot = call("POST", "/v1/appScreenshots", {"data": {
            "type": "appScreenshots",
            "attributes": {"fileName": path.name, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {
                "type": "appScreenshotSets", "id": set_id}}},
        }})["data"]
        for part in shot["attributes"]["uploadOperations"]:
            chunk = data[part["offset"]:part["offset"] + part["length"]]
            put(part, chunk)
        call("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {
            "type": "appScreenshots", "id": shot["id"],
            "attributes": {"uploaded": True,
                           "sourceFileChecksum": hashlib.md5(data).hexdigest()},
        }})
        ids.append(shot["id"])

    call("PATCH", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots", {
        "data": [{"type": "appScreenshots", "id": i} for i in ids]})
    return set_id


def wait_complete(set_id):
    for _ in range(60):
        shots = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=30")["data"]
        states = [s["attributes"]["assetDeliveryState"]["state"] for s in shots]
        if all(s in ("COMPLETE", "FAILED") for s in states):
            return states
        time.sleep(5)
    return states


def main():
    version, *wanted = sys.argv[1:]
    version_id = find_version(version)
    locales = call("GET", f"/v1/appStoreVersions/{version_id}"
                          "/appStoreVersionLocalizations?limit=50")["data"]
    by_locale = {l["attributes"]["locale"]: l["id"] for l in locales}
    wanted = wanted or sorted(p.name for p in (HERE / "screenshots").iterdir() if p.is_dir())

    done = []
    for locale in wanted:
        if locale not in by_locale:
            print(locale, "not in this version, skipped", flush=True)
            continue
        for device, display_type in DISPLAY_TYPES.items():
            files = sorted((HERE / "screenshots" / locale).glob(f"*_{device}.png"))
            done.append((locale, device, replace_set(by_locale[locale], display_type, files)))
            print(locale, device, len(files), "uploaded", flush=True)
    failed = 0
    for locale, device, set_id in done:
        states = wait_complete(set_id)
        failed += sum(s != "COMPLETE" for s in states)
        print(locale, device, states.count("COMPLETE"), "of", len(states), "complete", flush=True)
    if failed:
        raise SystemExit(f"{failed} screenshots did not finish processing")


if __name__ == "__main__":
    main()
