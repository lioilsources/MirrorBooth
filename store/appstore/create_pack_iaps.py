#!/usr/bin/env python3
"""Create the 13 filter packs ($0.99 non-consumables) on App Store Connect.

    python3 store/appstore/create_pack_iaps.py [--price 0.99] [--no-submit]

Same steps as create_bundle_iap.py, per pack: product, en-US + cs
localizations, price, availability (Art Unlock's territories), review
screenshot (Art Unlock's paywall). Idempotent. Apple only reviews new IAPs
together with an app version, so after this run add them to the version's
submission in App Store Connect (Add for Review), as with All Unlock.
"""
import hashlib
import sys
import urllib.request

from asc_api import APP_ID, call
from create_bundle_iap import TEMPLATE, put

PACKS = {
    "mosaic": ("Mosaic", "Mozaika"),
    "halftone": ("Halftone", "Rastr"),
    "sketch": ("Sketch", "Skica"),
    "optics": ("Optics", "Optika"),
    "kaleido": ("Kaleido", "Kaleido"),
    "tiles": ("Tiles", "Dlaždice"),
    "glitch": ("Glitch", "Glitch"),
    "vhs": ("VHS", "VHS"),
    "face": ("Face", "Tvář"),
    "layers": ("Layers", "Vrstvy"),
    "paint": ("Paint", "Malba"),
    "color": ("Color", "Barvy"),
    "light": ("Light", "Světlo"),
}


def ensure_iap(PRODUCT, ref_name, LOCALIZATIONS, REVIEW_NOTE, price, submit):
    iaps = {i["attributes"]["productId"]: i
            for i in call("GET", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=50")["data"]}
    template = iaps[TEMPLATE]["id"]

    if PRODUCT in iaps:
        iap = iaps[PRODUCT]["id"]
        print("product exists", iap, iaps[PRODUCT]["attributes"]["state"])
    else:
        iap = call("POST", "/v2/inAppPurchases", {"data": {
            "type": "inAppPurchases",
            "attributes": {"name": ref_name, "productId": PRODUCT,
                           "inAppPurchaseType": "NON_CONSUMABLE",
                           "reviewNote": REVIEW_NOTE},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }})["data"]["id"]
        print("product created", iap)

    have = {l["attributes"]["locale"] for l in
            call("GET", f"/v2/inAppPurchases/{iap}/inAppPurchaseLocalizations")["data"]}
    for locale, (name, description) in LOCALIZATIONS.items():
        if locale in have:
            continue
        call("POST", "/v1/inAppPurchaseLocalizations", {"data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": {"locale": locale, "name": name, "description": description},
            "relationships": {"inAppPurchaseV2": {"data": {
                "type": "inAppPurchases", "id": iap}}},
        }})
        print("localization", locale)

    try:  # 404 until a schedule exists
        priced = call("GET", f"/v1/inAppPurchasePriceSchedules/{iap}/manualPrices"
                             "?limit=5")["data"]
    except SystemExit:
        priced = []
    if priced:
        print("price already set")
    else:
        url = f"/v2/inAppPurchases/{iap}/pricePoints?filter[territory]=USA&limit=200"
        point = next(p for p in call("GET", url)["data"]
                     if p["attributes"]["customerPrice"] == price)
        call("POST", "/v1/inAppPurchasePriceSchedules", {
            "data": {"type": "inAppPurchasePriceSchedules", "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "inAppPurchasePrices",
                                           "id": "${price}"}]},
            }},
            "included": [{"type": "inAppPurchasePrices", "id": "${price}",
                          "attributes": {"startDate": None},
                          "relationships": {"inAppPurchasePricePoint": {"data": {
                              "type": "inAppPurchasePricePoints", "id": point["id"]}}}}],
        })
        print("price", price, "USD")

    try:  # 404 until availability exists
        avail = call("GET", f"/v2/inAppPurchases/{iap}/inAppPurchaseAvailability")
    except SystemExit:
        avail = {}
    if avail.get("data"):
        print("availability already set")
    else:
        territories = call("GET", f"/v1/inAppPurchaseAvailabilities/{template}"
                                  "/availableTerritories?limit=200")["data"]
        call("POST", "/v1/inAppPurchaseAvailabilities", {"data": {
            "type": "inAppPurchaseAvailabilities",
            "attributes": {"availableInNewTerritories": True},
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap}},
                "availableTerritories": {"data": [
                    {"type": "territories", "id": t["id"]} for t in territories]},
            },
        }})
        print("availability", len(territories), "territories")

    try:  # 404 until a screenshot exists
        shot = call("GET", f"/v2/inAppPurchases/{iap}/appStoreReviewScreenshot")
    except SystemExit:
        shot = {}
    if shot.get("data"):
        print("review screenshot already there")
    else:
        src = call("GET", f"/v2/inAppPurchases/{template}/appStoreReviewScreenshot")["data"]
        asset = src["attributes"]["imageAsset"]
        url = asset["templateUrl"].format(w=asset["width"], h=asset["height"], f="png")
        data = urllib.request.urlopen(url, timeout=120).read()
        new = call("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", {"data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": "paywall.png", "fileSize": len(data)},
            "relationships": {"inAppPurchaseV2": {"data": {
                "type": "inAppPurchases", "id": iap}}},
        }})["data"]
        for part in new["attributes"]["uploadOperations"]:
            put(part, data[part["offset"]:part["offset"] + part["length"]])
        call("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{new['id']}", {"data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots", "id": new["id"],
            "attributes": {"uploaded": True,
                           "sourceFileChecksum": hashlib.md5(data).hexdigest()},
        }})
        print("review screenshot uploaded")

    if not submit:
        return
    call("POST", "/v1/inAppPurchaseSubmissions", {"data": {
        "type": "inAppPurchaseSubmissions",
        "relationships": {"inAppPurchaseV2": {"data": {
            "type": "inAppPurchases", "id": iap}}},
    }})
    print("submitted for review")



def main():
    argv = sys.argv[1:]
    price = argv[argv.index("--price") + 1] if "--price" in argv else "0.99"
    for pack, (en, cs) in PACKS.items():
        print("==", pack)
        ensure_iap(
            f"com.ol1n.mirrorbooth.collection.{pack}", f"{en} Pack",
            {"en-US": (f"{en} Filters", f"Save photos and videos with every {en} filter"),
             "cs": (f"Filtry {cs}", f"Ukládání fotek a videí se všemi filtry {cs}")},
            f"Unlocks saving photos and videos with the {en} filter pack. Paywall: "
            f"open the Packs tab, tap the {en} chip, then tap the shutter.",
            price, "--no-submit" not in argv)


if __name__ == "__main__":
    main()
