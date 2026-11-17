# 09 — Handoff pro MacBook: review screenshoty zlevněných stupňů „All filters“

Pro session na MacBooku (Xcode + simulátor). Na M2 se screenshoty nedělají (DevConventions
`shared/stacks/flutter.md`).

## Proč

V App Store Connect jsou 4 nové stupně balíčku „All filters“ (PR #40, popis
`store/appstore/README.md`). Jsou ve stavu MISSING_METADATA, protože jim chybí jen review
screenshot. Stávající `collection.all_unlock` (4,99 USD) je READY_TO_SUBMIT a nový screenshot
nepotřebuje.

| Produkt | Cena | Nabízí se, když uživatel vlastní |
|---|---|---|
| `com.ol1n.mirrorbooth.collection.all_unlock` | 4,99 USD | 0 placených kolekcí |
| `com.ol1n.mirrorbooth.collection.all_unlock_s1` | 3,99 USD | 1 |
| `com.ol1n.mirrorbooth.collection.all_unlock_s2` | 2,99 USD | 2 |
| `com.ol1n.mirrorbooth.collection.all_unlock_s3` | 1,99 USD | 3 |
| `com.ol1n.mirrorbooth.collection.all_unlock_s4` | 0,99 USD | 4 a víc |

## Co udělat

1. `git pull` na `main`.
2. **Lokální StoreKit konfigurace, ne sandbox.** Produkty v MISSING_METADATA se v sandboxu
   nenačtou. Ve schématu Runner zapni StoreKit konfigurační soubor (Run → Options → StoreKit
   Configuration); pokud v repu žádný není, založ `mirrorbooth/ios/MirrorBooth.storekit` se
   všemi placenými kolekcemi a pěti produkty z tabulky (non-consumable, ceny z tabulky).
3. Spusť appku na simulátoru **iPhone 6.9"** (např. iPhone 16 Pro Max), angličtina.
4. V appce kup 2 libovolné placené kolekce (lokální StoreKit) a otevři paywall. Karta **All
   filters** ukazuje 2,99, přeškrtnuté 4,99 a řádek o odečtení. Vyfoť ji jako
   `all_unlock_discounted.png`.
5. Ulož do `store/appstore/review/` a pushni (soubory jmenovitě).
6. Pošli session **Store** zprávu s cestou. Store nahraje review screenshot k `all_unlock_s1`
   až `_s4`.

## Hotovo, když

PNG je v `main` a Store potvrdí, že stupně přešly z MISSING_METADATA do READY_TO_SUBMIT.

Nic neodesílej k review a neměň produkty v ASC. Verze s produkty vyjde až s novou ikonou
a balíkem nových shaderů.
