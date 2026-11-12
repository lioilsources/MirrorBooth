# 09 · PLÁN: evoluce shaderů, kolo 3 (Pretty a Ugly, obličej)

Navazuje na kolo 2 (`Prompts/08-PLAN-shader-evoluce-kolo-2.md`, běh `uc2-r2` na L40S). Cíl: **40–80 shaderů pro chipy Pretty a Ugly**, které dnes mají jen 5 + 5 filtrů a moc nefungují. Téma od Olina: oči, nos, rty, tváře, čelo, vlasy, jizvy, masky, líčení, joker, filmové efekty a masky, mimozemšťané, morfing do zvířat.

## Co shader ví o obličeji

Jen `uFaceCenter` (vec2, 0–1) a `uFaceScale` (float). V appce jsou zatím konstantní: střed (0.5, 0.5), měřítko 0.35 (`mirrorbooth/lib/core/face_anchor.dart`). Detekce obličeje není. Proto:

- Rysy se umisťují **relativně k uFaceCenter/uFaceScale** v souřadnicích obličeje `q = (uv - uFaceCenter) / uFaceScale` (oči ~ (±0.30, −0.15), nos ~ (0, 0.05), ústa ~ (0, 0.35), tváře ~ (±0.40, 0.20), čelo y < −0.45, vlasy y < −0.60 a po stranách).
- Měkké masky (smoothstep elipsy), žádné ostré hrany, aby drobná odchylka polohy nevadila.
- Testovací selfie: obličej vycentrovaný, měřítko ~0.35 (stejně jako appka).
- (Později appka dostane detekci obličeje přes Vision/ML Kit; shadery napsané takhle pak budou sedět ještě líp.)

## Rodiny (ostrovy) a karty techniky

| Kolekce | Rodina | Musí | Nesmí |
|---|---|---|---|
| Pretty | eyes | zjasnit / zvětšit / zabarvit duhovku v elipsách očí, jiskra | přebarvit celý snímek |
| Pretty | lips-makeup | tónovat a lesknout rty, růž na tvářích, oční linky/stíny | warp mimo obličej |
| Pretty | skin-glow | vyhlazení se zachováním hran uvnitř masky obličeje, glow, pihy | změny mimo masku |
| Pretty | hair-halo | tónování/záře nad čelem a kolem hlavy, korunka, svatozář | deformace obličeje |
| Pretty | sculpt | jemný warp: štíhlé tváře, menší nos, větší oči, plné rty (max 15 %) | karikatura |
| Ugly | scars | procedurální jizvy, stehy, modřiny, popáleniny na masce obličeje | celoplošný efekt |
| Ugly | face-paint | joker úsměv, lebka, tribal, superhrdinská maska, klaun | nezávislé na obličeji |
| Ugly | alien | zelená/šedá pleť, obří černé oči, protáhlá lebka, antény | jen přebarvení |
| Ugly | animal | čumák (bulge nosu), srst (šum), kočičí/hadí oči, uši, vousky | jen přebarvení |
| Ugly | features | velký nos/ústa/oči, malá hlava, posunuté rysy (bulge/pinch) | polární kaleidoskop |
| Ugly | movie-fx | zombie, upálení, kyborg plát, vlkodlak, mumie, Predator | jen barevná LUT |

Statická kontrola karty před renderem (regex/AST): musí používat `uFaceCenter` a `uFaceScale`; zakázat `atan` u všech rodin kromě alien/animal (uši, vousky smí).

## Pravidla z kola 2 (beze změny)

- Rodič se losuje rovnoměrně přes buňky archivu, ne podle fitness.
- Kvóta linie 20 % na seed, dynamický zákaz tokenů > 30 % archivu.
- Operátory: variace, křížení (v rodině), import (sousední rodina), zjednodušení.
- Osy archivu: pohyb × síla zásahu; archiv 5×5 na rodinu.
- Brány: kontrakt uniformů, glslang, **impellerc včetně SkSL na VM**, bez NaN, blikání pod limitem, čas snímku pod rozpočtem, smyčky max 2 do hloubky.
- `face_keep` podle rodiny: sculpt vysoký, features/animal/alien nízký.
- Skóre: CLIP shoda s textovým popisem rodiny (anglicky, např. "a selfie with glossy red lipstick and blush"), novost (CLIP embedding + kód), PickScore jen s malou vahou.
- Navíc: **lokalita** — rozdíl proti originálu musí být z většiny uvnitř masky obličeje / hlavy (kromě hair-halo a movie-fx).
- Dedup: hash kódu, podobnost renderu > 0.97 zahodit.
- Rodiny postupně, checkpointy, memguard, restart evaluátoru po N dětech.

## Seedy

Pretty: glow, slim, doll, chibi, lips (+ r2 Face rodina jako zdroj warpů). Ugly: bigNose, alien, melt, bigEars, longNeck, zombie, vampire, demon, cyborg, frozen, ghost. Aspoň 3 seedy na rodinu; chybějící dopsat ručně (např. jizva, joker, kočičí oči).

## Rozsah

1. Zkouška: lips-makeup + animal × 100 dětí. Zkontrolovat rozmanitost, lokalitu, paměť.
2. Plný běh: 11 rodin × 300 dětí ≈ 2–3 h GPU. Pokud odhad přesáhne 5 h, zastavit a ohlásit.
3. Export 4–8 kusů na rodinu z různých buněk.

## Výstup

- `pipeline/output/uc3/<rodina>/<id>.frag` + `meta.json` + náhled `.webp`, HTML galerie po rodinách.
- Integrace do Labu: `pipeline/integrate.py --collection experimental`, enum `r3<Family><id>` (např. `r3LipsC0012`), štítek `<Family> n`.
- Větev `feat/lab-round3` (z `feat/family-packs`), PR bez merge, TestFlight lab build (release-ios, input lab=true). Nikdy netagovat `v*`.
- Po Olinově výběru přejdou nejlepší do Pretty a Ugly (zdarma) nebo do nových balíčků.

## Hotovo, když

1. Export 40–80 shaderů z aspoň 8 rodin, žádná rodina > 20 %.
2. Vše projde impellerc (Metal, GLES, Vulkan, SkSL) na Macu beze změny.
3. Polární warp ≤ 10 % exportu; lokalita splněna u ≥ 80 %.
4. Běh doběhl bez pádu, nebo navázal z checkpointu.
