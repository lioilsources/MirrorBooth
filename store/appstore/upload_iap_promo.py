#!/usr/bin/env python3
"""Upload the promotion images from make_iap_promo.py and promote the purchases.

    python3 store/appstore/upload_iap_promo.py [--dry-run]

For each *_unlock in-app purchase: uploads promo/<suffix>.png as its image
(skipped when one is already attached) and creates the promoted purchase
(App Store product page, visible to all users) when it does not exist yet.
Apple reviews the image; promotion shows once the purchase is approved.
"""
import hashlib
import pathlib
import sys
import urllib.request

from asc_api import APP_ID, call

HERE = pathlib.Path(__file__).resolve().parent
PREFIX = "com.ol1n.mirrorbooth.collection."
SUFFIXES = ["art_unlock", "fantasy_unlock"]


def put(part, chunk):
    req = urllib.request.Request(part["url"], data=chunk, method=part["method"],
                                 headers={h["name"]: h["value"]
                                          for h in part["requestHeaders"]})
    with urllib.request.urlopen(req, timeout=300):
        pass


def upload_image(iap_id, path):
    data = path.read_bytes()
    image = call("POST", "/v1/inAppPurchaseImages", {"data": {
        "type": "inAppPurchaseImages",
        "attributes": {"fileName": path.name, "fileSize": len(data)},
        "relationships": {"inAppPurchase": {"data": {
            "type": "inAppPurchases", "id": iap_id}}},
    }})["data"]
    for part in image["attributes"]["uploadOperations"]:
        put(part, data[part["offset"]:part["offset"] + part["length"]])
    call("PATCH", f"/v1/inAppPurchaseImages/{image['id']}", {"data": {
        "type": "inAppPurchaseImages", "id": image["id"],
        "attributes": {"uploaded": True,
                       "sourceFileChecksum": hashlib.md5(data).hexdigest()},
    }})


def main():
    dry = "--dry-run" in sys.argv
    iaps = call("GET", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=50")["data"]
    by_product = {i["attributes"]["productId"]: i["id"] for i in iaps}
    promoted = call("GET", f"/v1/apps/{APP_ID}/promotedPurchases?include=inAppPurchaseV2"
                           "&limit=50")["data"]
    promoted_ids = {p["relationships"]["inAppPurchaseV2"]["data"]["id"]
                    for p in promoted
                    if (p["relationships"].get("inAppPurchaseV2") or {}).get("data")}

    for suffix in SUFFIXES:
        iap_id = by_product[PREFIX + suffix]
        images = call("GET", f"/v2/inAppPurchases/{iap_id}/images")["data"]
        if images:
            print(suffix, "image already there:", images[0]["attributes"].get("state"))
        elif dry:
            print(suffix, "would upload image")
        else:
            upload_image(iap_id, HERE / "promo" / f"{suffix}.png")
            print(suffix, "image uploaded")

        if iap_id in promoted_ids:
            print(suffix, "already promoted")
        elif dry:
            print(suffix, "would promote")
        else:
            call("POST", "/v1/promotedPurchases", {"data": {
                "type": "promotedPurchases",
                "attributes": {"visibleForAllUsers": True, "enabled": True},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": APP_ID}},
                    "inAppPurchaseV2": {"data": {"type": "inAppPurchases",
                                                 "id": iap_id}},
                },
            }})
            print(suffix, "promoted")


if __name__ == "__main__":
    main()
