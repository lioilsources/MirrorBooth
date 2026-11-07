# Mirror Booth 2.4.0: co je v buildu a co zbývá v obchodech

Stav k 7. 11. 2026. Kód pokrývá body 1–8 z `MIRRORBOOTH_STORE_PLAN.md`, kódové
části plánů viditelnosti pro App Store a Google Play a podklady (videa,
screenshoty, ikony, metadata). Nic z toho není odeslané ke schválení.

## Changelog 2.4.0

- **Kolekce jako non-consumable na iOS.** Appka prodává
  `com.ol1n.mirrorbooth.collection.art_unlock` a `…fantasy_unlock`.
  Kupci starých consumable `collection.art` / `collection.fantasy` dostanou
  kolekci zpět z historie transakcí (StoreKit 2 `Transaction.all` +
  `SKIncludeConsumableInAppPurchaseHistory`, iOS 18+). Na starším iOS
  zůstane odemčení z lokální cache, po přeinstalaci se ale neobnoví.
  Android (od 2.3.5 také `*_unlock`) se ptá na obě sady a prodává `*_unlock`,
  pokud v Play existuje, jinak původní ID. Nákupy obou sad odemykají.
- **Restore Purchases** na paywallu obnoví `*_unlock` (StoreKit 2
  `currentEntitlements`).
- **Balíček „All filters“** (`collection.all_unlock`; na Play případně i
  `collection.all`). Na paywallu se objeví až ve chvíli, kdy produkt
  v obchodě existuje; do té doby se nic nezmění.
- **Nákup zahájený v App Storu** (propagované nákupy): nativní posluchač
  `PurchaseIntent` (iOS 16.4+) předá produkt do Flutteru, ten ho koupí
  běžnou cestou a transakci dokončí. Funguje i při studeném startu z karty
  nákupu. Po odemčení se otevře první filtr kolekce.
- **Alternativní ikony** `AppIcon-Color` (kaleidoskop, vybraná
  `flux_kaleido_9102`) a `AppIcon-Face` (zatím placeholder = dnešní ikona),
  přibalené přes `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS`.
  V appce se nepřepínají.
- **Deep linky** `mirrorbooth://…` a `https://olin.now/mirror/…`:
  `camera`, `collection/<pretty|ugly|art|fantasy>`, `f/<filtr>`,
  `event/<id>` (`holiday`, `newyear`, `valentine`, `artweek`,
  `halloween`). Neznámá cesta otevře kameru, bez pádu. Flutterové
  vestavěné zpracování odkazů je vypnuté.
- **Výzva k hodnocení** (`in_app_review`): po 3. uložení nebo sdílení fotky
  nebo po prvním uloženém či sdíleném videu, max. jednou za verzi, nikdy
  při prvním spuštění a ne do 30 s po chybě.
- **Měřené sdílení.** iOS:
  `https://apps.apple.com/app/id6767824892?ct=share` (+ `ppid`, `pt`, až
  budou vyplněné v `lib/core/store_links.dart`). Android:
  `…details?id=com.ab.mirrorbooth&referrer=utm_source=share&utm_medium=app_share`.
  Vodoznak sdílené fotky/videa má pod „Mirror Booth“ malou adresu
  `olin.now/mirror`. Fotka v galerii zůstává čistá.
- **Accessibility.** VoiceOver/TalkBack popisky spouště, nahrávání,
  přepnutí kamery, strany zrcadlení, logu a zavíracích tlačítek; prstence osy
  a rotace jsou ovladatelné gesty nahoru/dolů (po 15°). Nadpis paywallu se
  při velkém písmu zalamuje (dříve přetékal). Testy v
  `test/accessibility_test.dart` (písmo 1×, 1,5×, 2× na šířce telefonu).
- **Minimální iOS je 15.0.** Flutter 3.47 při buildu projekt sám převedl
  (dříve 14.0); stejně by to udělal CI.

## Accessibility štítky pro App Store Connect

Vyplnit pro iPhone:

| Štítek | Podporuje | Proč |
|---|---|---|
| VoiceOver | ano | všechna tlačítka mají popisky, prstence jsou nastavitelné |
| Larger Text | ano | text se škáluje s Dynamic Type, ověřeno do 2× |
| Dark Interface | ano | celé UI je tmavé |
| Sufficient Contrast | ano | bílý text na černé/poloprůhledné černé |
| Voice Control | neuvádět | neověřeno na zařízení |
| Reduced Motion, Captions, Audio Descriptions | neuvádět | netýká se / neověřeno |

## Co musí Ol1n udělat v App Store Connect

1. **IAP `art_unlock` a `fantasy_unlock`:** doplnit metadata (název, popis
   ve všech jazycích, screenshot pro review, cenu stejnou jako dnes) a
   přiložit je k verzi 2.4.0.
2. **Consumable `collection.art` / `collection.fantasy` stáhnout z prodeje**
   (Cleared for Sale = off), až bude 2.4.0 schválená. Dřív ne: 2.3.4 je
   pořád prodává.
3. Volitelně vytvořit **`collection.all_unlock`** (non-consumable,
   třeba 1,5násobek ceny jedné kolekce). Bez něj se balíček nezobrazí.
4. **Propagované nákupy:** u `*_unlock` zapnout Promote, nahrát obrázek
   1024×1024. Test na zařízení se sandbox účtem:
   `itms-services://?action=purchaseIntent&bundleId=com.ol1n.mirrorbooth&productIdentifier=com.ol1n.mirrorbooth.collection.art_unlock`
5. **PPO test ikony:** v Product Page Optimization vybrat `AppIcon-Color`
   (a později `AppIcon-Face`, až bude hotová grafika obličeje s dělicí čarou).
   Ikonu lze testovat jen s buildem 2.4.0.
6. **Campaign token:** App Analytics → Campaigns → provider token (`pt`)
   doplnit do `StoreLinks.providerToken`; ID Custom Product Page
   „Shared photo“ do `StoreLinks.sharedPhotoPageId`.
7. **Název, podtitul, klíčová slova, promo text** pro en-GB, fr-FR, it, cs,
   id, ar-SA, hi: návrhy v `store/appstore/metadata/<locale>/`, kontrola
   `python3 store/appstore/check_metadata.py`. en-US je jen návrh
   klíčových slov; název a podtitul en-US jsem odvodil z plánu, porovnat
   s tím, co je živé. Cross-lokalizaci es-MX (anglická slova pro USA)
   před nasazením ověřit v dokumentaci Apple.
8. **Preview videa (max. 3):** `store/appstore/previews/en/`
   `05_cat_oil_short.mp4`, `12_comic_demon_short.mp4`,
   `13_alien_cyborg_short.mp4` (17 s, 886×1920, efekt od první vteřiny,
   titulky v obraze). Nahrát přes `upload_previews.py` (potřebuje App Manager
   klíč, `ASC_KEY_*` nejsou v tomto prostředí nastavené).
9. **Screenshoty (max. 10, dnes 5):** navrhované doplnění z
   `store/appstore/screenshots/candidates/`: `cat_01_lr`, `comic_01_lr`,
   `alien_01_lr`, `alien_02_filters`, `cat_02_filters`. První tři
   pozice nechat před/po (dnešní hero je přesně to).
10. **In-App Events:** deep link události ve tvaru
    `mirrorbooth://event/holiday` (další ID viz Changelog). Posílat aspoň
    2 týdny předem; featuring nominace 3 týdny předem.
11. **Accessibility štítky** podle tabulky výše; Age rating projet podle
    aktuálního dotazníku.

## Co musí Ol1n udělat v Play Console

1. **Grafika:** 4 nové screenshoty telefonu (limit 8, dnes 4) v
   `store/appstore/screenshots/candidates/play/`: `cat_01_lr`,
   `comic_01_lr`, `alien_01_lr`, `alien_02_filters` (1080×1920).
2. **Experiment ikony:** varianta `store/play/graphics/icon-512-kaleido.png`.
3. Ověřit, že v Play existují **`collection.art_unlock` a
   `collection.fantasy_unlock`** (2.3.5 je už používá); volitelně
   **`collection.all_unlock`** (jednorázový). Play Billing Library v appce je 8.0.0
   (`in_app_purchase_android` 0.5.4), takže slevové nabídky na jednorázové
   produkty jsou technicky možné; plugin ale do Dartu posílá jen výchozí
   nabídku, takže sleva musí být nastavená jako ta výchozí.
4. **Vlastní záznam `olinnow`:** odkaz z olin.now už nese `&listing=olinnow`.
   Záznam vytvořit v Play Console (dokud neexistuje, odkaz vede na výchozí).
5. **App Links:** do `https://olin.now/.well-known/assetlinks.json` dát
   SHA-256 klíče pro podepisování aplikací z Play Console (Nastavení →
   Integrita aplikace). Šablona níže. Bez ní se odkazy `olin.now/mirror/…`
   otevřou v prohlížeči, `mirrorbooth://` funguje vždy.
6. Video v záznamu jen jako YouTube odkaz na šířku; z našich videí na výšku
   pro Play žádné není.

```json
[{"relation": ["delegate_permission/common.handle_all_urls"],
  "target": {"namespace": "android_app", "package_name": "com.ab.mirrorbooth",
             "sha256_cert_fingerprints": ["<SHA-256 z Play Console>"]}}]
```

## Web olin.now (repo ol1n.now, větev `feat/mirrorbooth-store-links`)

- Smart App Banner (`apple-itunes-app`) na stránce každé appky s App Store ID.
- Odkazy Mirror Booth s `?ct=olinnow` a `&listing=olinnow`.
- `olin.now/mirror`: krátká adresa z vodoznaku, přesměruje iPhone do App
  Storu (`ct=watermark`), Android na Play (`utm_source=watermark`), ostatní na
  `olin.now/mirrorbooth`.
- Universal links (`apple-app-site-association`) nejsou: potřebují Team ID a
  capability Associated Domains v provisioning profilu, jinak CI build
  neprojde podpisem. Do té doby slouží `mirrorbooth://`.

## Jak vznikl build

`flutter analyze` čistý, `flutter test` (testy pro migraci nákupů, balíček,
propagované nákupy, deep linky, výzvu k hodnocení, odkazy a přístupnost),
`flutter build ios --release --no-codesign` a `flutter build apk --release`
prošly. Na zařízení ani v sandboxu netestováno. Do TestFlightu jde build
přes CI po pushnutí tagu `v2.4.0` (workflow `release-ios.yml`).
