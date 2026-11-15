# App Store listing assets

Localized screenshots and keywords for Mirror Booth (`com.ol1n.mirrorbooth`,
Apple ID 6767824892). Google Play materials live in `store/play/`.

## Screenshots

    python3 store/appstore/make_appstore_shots.py              # all locales
    python3 store/appstore/make_appstore_shots.py --locales pt-BR

Writes five scenes per locale to `store/appstore/screenshots/<locale>/`, as
iPhone 6.9" (1320×2868) and iPad 13" (2064×2752) RGB PNGs. The output is about
70 MB per locale, so it is git-ignored and rebuilt from `faces/`. Needs Pillow
and Flutter.

| # | Scene | Content |
|---|---|---|
| 1 | hero | original vs. left + left vs. right + right |
| 2 | live | full symmetric face, original as inset |
| 3 | filters | six filters, through the app's shaders |
| 4 | kaleido | mirror axis turned over a tilted head |
| 5 | video | recording with the voice-effect names |

Faces in `faces/` are fictional adults rendered by `generate_faces.py`. Never
replace them with a real person without a signed release. Headlines live in
`make_appstore_shots.py`; filter and voice-effect names come from the app's ARB
files. `en-GB`, `en-AU` and `en-CA` are copies of `en-US`.

## Character candidates

    python3 store/appstore/make_character_shots.py   # 3 iPhone shots per character
    python3 store/appstore/make_previews.py 05_cat_oil … 15_kenji_zombie

Animals, plush toys, dolls, cartoons, an alien and two strongly lopsided
faces (`generate_faces.py`, `CHARACTER_STYLE` / `ASYM_STYLE`), each with a
left/right shot, a filter grid and a live filter that lean on the paid Art
and Fantasy collections. Shots land in `screenshots/candidates/` (with
440 px JPEG thumbs for curation), previews in `previews/en/`. They are
candidates: copy the picked ones into a locale folder before uploading.
Keep every character generic; no branded toy, doll or comic hero.

## Upload

Screenshots need a new App Store version in Prepare for Submission. Use an App
Manager key; the CI key (Developer) gets 403 on metadata changes.

    cd store/appstore
    ASC_KEY_PATH=… ASC_KEY_ID=… ASC_ISSUER_ID=… python3 upload_screenshots.py 2.3.4

## pt-BR keywords (100 characters max)

```
simetria,facial,espelho,teste,beleza,feio,bonito,gêmeo,clone,distorcer,câmera,efeito,zoeira,chibi
```

Words from the title (`Mirror Booth: rosto simétrico`) and the subtitle
(`Filtros engraçados para selfie`) are left out: the App Store indexes them
anyway and combines single words into phrases such as "simetria facial".

## Promoted in-app purchases

    python3 store/appstore/make_iap_promo.py      # promo/<product>.png, 1024×1024
    python3 store/appstore/upload_iap_promo.py    # image + promotion, App Manager key

Run the upload once the `*_unlock` purchases are approved: while a purchase is
waiting for review, ASC refuses a new image ("change pending review").

## Bundle: all collections ($4.99, includes every future collection)

    python3 store/appstore/create_bundle_iap.py   # ASC: create, price, territories, submit
    python3 store/play/create_bundle_product.py   # Play: create and activate

Both are idempotent. Apple only takes it once another non-consumable is
approved (FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION until then).

## Bundle tiers: complete-the-set pricing (not created yet)

The app (`FilterCollection.bundleLadder`, `lib/core/set_ladder.dart`) offers
one "All filters" product chosen by how many paid collections the customer
owns; every tier unlocks every paid collection, including future ones. The
app shows only store prices and never computes an amount. A tier the store
does not return is skipped (the next lower tier is offered), so the app works
before the new products exist.

| Tier | Product ID | Price (USD price point) | Offered when owning |
|---|---|---|---|
| 0 | `com.ol1n.mirrorbooth.collection.all_unlock` | 4.99 | 0 paid collections |
| 1 | `com.ol1n.mirrorbooth.collection.all_unlock_s1` | 3.99 | 1 |
| 2 | `com.ol1n.mirrorbooth.collection.all_unlock_s2` | 2.99 | 2 |
| 3 | `com.ol1n.mirrorbooth.collection.all_unlock_s3` | 1.99 | 3 |
| 4 | `com.ol1n.mirrorbooth.collection.all_unlock_s4` | 0.99 | 4 or more |

Manual step, not done: create tiers 1–4 as non-consumables in App Store
Connect and as one-time products in Play Console (same IDs on both), with the
same name and paywall review screenshot as tier 0, Family Sharing like tier 0,
other currencies left to the store. Review note for every tier:

> Complete-the-set pricing: these products unlock identical content. The app
> offers exactly one of them, chosen by how many items the customer already
> owns, so earlier purchases are credited.

Never turn on Promote for tiers 1–4: a promoted tier could be bought from the
product page at the discounted price. The legacy Play bundle
`com.ol1n.mirrorbooth.collection.all` keeps unlocking everything and is sold
as tier 0 only while `all_unlock` is missing on Play.

Unverified: whether `all_unlock` exists in App Store Connect and at what price
(check with `passctl asc iaps --app mirrorbooth`). The tiers assume tier 0 is
4.99 USD; `create_bundle_iap.py` defaults to that price.
