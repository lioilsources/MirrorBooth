#!/usr/bin/env python3
"""Create and activate the 13 filter packs ($0.99 each) on Google Play.

    python3 store/play/create_pack_products.py [--price 0.99] [--dry-run]

Same recipe as create_bundle_product.py: regions and tax settings come from
collection.art, local prices from Play's own USD conversion. Idempotent:
PATCH with allowMissing creates or updates, activation is repeatable.
"""
import sys

from play_api import PACKAGE, call
from create_bundle_product import TEMPLATE, money

# pack -> (en-US title, cs-CZ title)
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


def listings(en, cs):
    return [
        {"languageCode": "en-US", "title": f"{en} filter pack",
         "description": f"Unlock saving photos and videos with every {en} filter."},
        {"languageCode": "cs-CZ", "title": f"Balíček {cs}",
         "description": f"Odemkne ukládání fotek a videí se všemi filtry {cs}."},
    ]


def main():
    argv = sys.argv[1:]
    usd = argv[argv.index("--price") + 1] if "--price" in argv else "0.99"
    base = f"/applications/{PACKAGE}/oneTimeProducts"
    template = call("GET", f"{base}/{TEMPLATE}")
    option = template["purchaseOptions"][0]
    converted = call("POST", f"/applications/{PACKAGE}/pricing:convertRegionPrices",
                     {"price": money(usd)})
    regions = converted["convertedRegionPrices"]
    configs = [{"regionCode": r["regionCode"],
                "price": regions[r["regionCode"]]["price"],
                "availability": r["availability"]}
               for r in option["regionalPricingAndAvailabilityConfigs"]
               if r["regionCode"] in regions]
    other = converted.get("convertedOtherRegionsPrice", {})
    version = template["regionsVersion"]["version"].replace("/", "%2F")
    print(len(configs), "regions, US", usd, "USD")
    for pack, (en, cs) in PACKS.items():
        product_id = f"com.ol1n.mirrorbooth.collection.{pack}"
        product = {
            "packageName": PACKAGE,
            "productId": product_id,
            "listings": listings(en, cs),
            "taxAndComplianceSettings": template.get("taxAndComplianceSettings", {}),
            "purchaseOptions": [{
                "purchaseOptionId": "buy",
                "buyOption": {"legacyCompatible": True},
                "regionalPricingAndAvailabilityConfigs": configs,
                "newRegionsConfig": {
                    "usdPrice": other.get("usdPrice", money(usd)),
                    "eurPrice": other.get("eurPrice"),
                    "availability": "AVAILABLE",
                },
                "taxAndComplianceSettings": option.get("taxAndComplianceSettings", {}),
            }],
        }
        if "--dry-run" in argv:
            print("would create", product_id)
            continue
        call("PATCH", f"/applications/{PACKAGE}/onetimeproducts/{product_id}"
                      f"?allowMissing=true&regionsVersion.version={version}"
                      "&updateMask=listings,purchaseOptions,taxAndComplianceSettings",
             product)
        call("POST", f"{base}/{product_id}/purchaseOptions:batchUpdateStates", {"requests": [{
            "activatePurchaseOptionRequest": {
                "packageName": PACKAGE, "productId": product_id, "purchaseOptionId": "buy"},
        }]})
        print(product_id, "active")


if __name__ == "__main__":
    main()
