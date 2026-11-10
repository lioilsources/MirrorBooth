# 08 · PLÁN: evoluce shaderů, kolo 2 (různé rodiny místo jedné)

Navazuje na UC2 (evoluce shaderů na L40S, běh `evo1`). Cíl kola 2: **60–100 shaderů z aspoň 8 koncepčně různých rodin**, připravených pro záložku Lab v appce.

## Proč kolo 1 skončilo monokulturou

Rozbor 1 683 platných dětí z `evo1/kaleido`:

- 1 678 dětí používá polární (kaleidoskopický) warp, zbylých 5 je jen neonové obarvení.
- Všechny děti pocházejí z 5 z 24 seedů: cyborg 1 154, neon 254, melt 241, glow 31, slim 3. Ostatních 19 seedů nemá potomka.
- V celé populaci je 100 názvů funkcí, skoro všechny `kaleido*`, `neon*`, `flow*`, `swirl*`.

Příčiny:

1. **Jedno téma v promptu.** Každé dítě dostalo zadání „kaleidoskop“, takže se technika nemohla změnit.
2. **Výběr rodičů podle fitness.** Nejlépe hodnocená linie (cyborg) zaplavila archiv.
3. **Osy archivu neměří techniku.** Výpočetní cena × pohyb rozliší rychlý a pomalý kaleidoskop, ne kaleidoskop a mozaiku.
4. **PickScore měří „hezkou fotku“.** Odměňuje jemné pastelové obarvení a trestá každou výraznou deformaci.
5. **Akvarel a VHS neproběhly** (došla RAM), takže jiné téma nikdy nedostalo šanci.

## Návrh kola 2

### 1. Rodiny (témata) s kartou techniky

Každá rodina je samostatný ostrov s vlastním archivem a vlastním promptem. Karta říká, které stavební prvky dítě **musí** použít a které **nesmí**.

| Rodina | Musí | Nesmí |
|---|---|---|
| mozaika | kvantizace UV (`floor(uv*n)`), buňky, hex/voronoi | polární warp |
| polotón a dither | rastr bodů/čar podle jasu, Bayer matice | plynulé přebarvení |
| skica | hrany (Sobel, rozdíl sousedů), šrafování, papír | neonová paleta |
| optika | rybí oko, bulge, twirl, lom, čočka kolem `uFaceCenter` | dělení úhlu na segmenty |
| dlaždice a zrcadla | kartézské zrcadlení, opakování, posun řádků | `atan` |
| glitch | posun bloků a řádků, rozpad RGB kanálů, šum v čase | plynulé vlnění |
| VHS a CRT | řádky, maska, chroma bleed, tracking, zakřivení | kaleidoskop |
| malba | Kuwahara, akvarel (rozpíjení + papír), olej | ostré hrany |
| barva | duotón, posterizace, termo, negativ, mapování gradientem | deformace UV |
| světlo | bloom, záře z jasů, paprsky, bokeh, vinětace | deformace UV |
| obličej | deformace ukotvená na `uFaceCenter`/`uFaceScale` | efekt přes celý obraz |
| vrstvy | déšť, sníh, mlha, prach, částice přes obraz | změna barev obrazu |

Kontrola karty je statická (regex/AST nad kódem) a běží před renderem; dítě mimo kartu se zahodí.

### 2. Seedy

- Aspoň 3 seedy na rodinu, každý jiný přístup. Zdroje: 24 dosavadních filtrů (rozdělit do rodin), ručně psané shadery z round B v Lab, případně CC0 seedy z dřívější větve se seed korpusem.
- Seed bez rodiny se nepoužije. Žádná rodina nesmí startovat jen z kaleidoskopu nebo cyborga.

### 3. Výběr rodičů a kvóty

- Rodič se losuje **rovnoměrně přes buňky archivu**, ne podle fitness.
- **Kvóta linie:** z jednoho seedu nejvýš 20 % dětí rodiny. Po překročení se linie pro výběr rodičů zamkne.
- **Dynamický zákaz:** token nebo název funkce, který je ve víc než 30 % archivu rodiny, jde do promptu jako zakázaný pro dalších N dětí.

### 4. Mutační operátory (střídat, ne jeden prompt)

- **variace:** změň parametry a jednu funkci rodiče.
- **křížení:** vezmi techniku z rodiče A a aplikuj ji na výstup rodiče B (oba ze stejné rodiny).
- **import:** přenes jeden prvek ze sousední rodiny (např. dither do VHS), karta rodiny pořád platí.
- **zjednodušení:** odstraň jednu vrstvu efektu, zachovej charakter (brání bobtnání kódu; medián byl 3 104 ALU).

### 5. Osy archivu

Místo cena × pohyb: **pohyb × síla zásahu do obrazu** (1 − podobnost s neupraveným snímkem). Cena je jen limit (viz brány). Archiv 5×5 na rodinu, tedy až 300 buněk celkem.

### 6. Hodnocení

Tvrdé brány (ano/ne, bez bodů):

- kontrakt uniformů, glslang, **impellerc včetně SkSL** už na VM (v kole 1 prošel shader s `abs(int)`, který SkSL odmítne),
- render bez NaN, blikání pod limitem, čas snímku pod rozpočtem,
- `face_keep` nad prahem **podle rodiny** (optika a obličej smí deformovat víc než barva).

Skóre (jen řadí uvnitř buňky):

- **shoda s tématem:** CLIP podobnost renderu s textovým popisem rodiny,
- **novost:** vzdálenost renderu (CLIP embedding) a kódu od nejbližších v archivu,
- PickScore vypustit, nebo nechat s malou vahou jako pojistku proti rozbitému obrazu.

Deduplikace: normalizovaný hash kódu a podobnost renderu nad 0,97 s něčím v archivu znamená zahodit.

### 7. Kalibrace podle Olina

Hodnocení filtrů 01–52 z Lab (líbí / nelíbí, čísla z appky) uložit jako tabulku a ověřit na ní nové skóre: líbivé musí vyjít výš než nelíbivé. Když ne, upravit váhy před během.

### 8. Stabilita běhu

- Rodiny běží **postupně**, každá s checkpointem a možností navázat; pád jedné nezahodí ostatní.
- Měřit RSS evaluátoru a vLLM po dávkách, evaluátor restartovat po N dětech, memguard nechat zapnutý.
- Render a hodnocení v dávkách, ne po jednom dítěti.
- Nejdřív zkouška: 2 rodiny × 100 dětí, zkontrolovat rozmanitost a paměť, až potom plný běh.

### 9. Rozsah a cena

- 12 rodin × 500 dětí = 6 000 dětí. Kolo 1 dalo 1 944 dětí za 62 minut, tedy zhruba 3–4 hodiny GPU.
- Z každé rodiny do exportu 5–8 kusů z různých buněk.

### 10. Výstup

- `pipeline/output/uc2-r2/<rodina>/<id>.frag` + `meta.json` (rodina, rodič, metriky, stav impellerc) + náhled `.webp`.
- Galerie po rodinách a buňkách (HTML), aby šlo vybírat ještě před appkou.
- Do appky přes `pipeline/integrate.py --collection experimental`, štítky s číslem a zkratkou rodiny.

## Hotovo, když

1. Export má 60–100 shaderů z aspoň 8 rodin a žádná rodina netvoří víc než 20 %.
2. Žádná linie seedu nemá víc než 20 % exportu.
3. Všechny exportované shadery projdou impellerc (Metal, GLES, Vulkan, SkSL) na Macu beze změny.
4. Polární warp je nejvýš v 10 % exportu.
5. Běh doběhl bez pádu na paměť, nebo po pádu navázal z checkpointu.

## Kroky

1. Karty rodin + statická kontrola karty, testy na dosavadních 24 seedech.
2. Seedy: rozřadit stávající, doplnit z round B.
3. Výběr rodičů, kvóty, dynamický zákaz, čtyři operátory.
4. Nové osy archivu, brány, skóre (CLIP téma + novost), deduplikace.
5. impellerc na VM, checkpointy, měření RSS, dávky.
6. Zkouška 2 × 100, vyhodnotit, doladit.
7. Plný běh, export, galerie, integrace do Lab, build na TestFlight.
