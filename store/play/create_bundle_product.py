#!/usr/bin/env python3
"""Create and activate the "all collections" one-time product on Google Play.

    python3 store/play/create_bundle_product.py [--price 5.99] [--dry-run]

Copies regions and tax settings from collection.art; local prices come from
Play's own USD conversion. Play has no review for products: once active it is
on sale (the 2.4.0 paywall already offers it).
"""
import json
import sys

from play_api import PACKAGE, call

PRODUCT = "com.ol1n.mirrorbooth.collection.all_unlock"
TEMPLATE = "com.ol1n.mirrorbooth.collection.art"
LISTINGS = {
    "en-US": ("All filters", "Unlock saving photos and videos with every Art and "
                             "Fantasy filter, plus every future filter pack free."),
    "cs-CZ": ("Všechny filtry", "Odemkne ukládání fotek a videí se všemi filtry Art a "
                                "Fantasy a všechny budoucí balíčky zdarma."),
}


def money(usd):
    units, _, cents = usd.partition(".")
    return {"currencyCode": "USD", "units": units,
            "nanos": int(cents.ljust(9, "0")[:9])}


def main():
    argv = sys.argv[1:]
    usd = argv[argv.index("--price") + 1] if "--price" in argv else "5.99"
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
    product = {
        "packageName": PACKAGE,
        "productId": PRODUCT,
        "listings": [{"languageCode": k, "title": t, "description": d}
                     for k, (t, d) in LISTINGS.items()],
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
    print(len(configs), "regions, US", usd, "USD")
    if "--dry-run" in argv:
        print(json.dumps(product, ensure_ascii=False)[:800])
        return
    version = template["regionsVersion"]["version"].replace("/", "%2F")
    # patch is the one method on the lowercase path
    call("PATCH", f"/applications/{PACKAGE}/onetimeproducts/{PRODUCT}?allowMissing=true&regionsVersion.version={version}"
                  "&updateMask=listings,purchaseOptions,taxAndComplianceSettings",
         product)
    print("created")
    call("POST", f"{base}/{PRODUCT}/purchaseOptions:batchUpdateStates", {"requests": [{
        "activatePurchaseOptionRequest": {
            "packageName": PACKAGE, "productId": PRODUCT, "purchaseOptionId": "buy"},
    }]})
    print("activated")


if __name__ == "__main__":
    main()
