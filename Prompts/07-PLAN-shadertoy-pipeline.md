# 07 — ShaderGen v2: pipeline generující nové MirrorBooth filtry z knihovny Shadertoy

> Plán pro implementaci (Opus). Provozní příprava strojů (SPARK/M2/JODA) je v `07-SETUP-shadertoy-pipeline-infra.md`. Pracuj po fázích, každou fázi uzavři zeleným CI
> a samostatným PR. Nepřeskakuj testy a nikdy nesahej do souborů mimo `pipeline/`
> a mimo sekci **Fáze 6** bez explicitního rozhodnutí v tomto plánu.

> **Stav (2026-11-08): Fáze 0–7 jsou implementované a sloučené do `main`**
> (commity `01157bc`…`3468471`, 2026-09-29 a 2026-10-01). Tento dokument teď
> slouží jako záznam rozhodnutí a kontrakt, který kód skutečně dodržuje —
> aktuální použití je v `pipeline/README.md`. Jediná věc, kterou plán
> předpokládal a kód ještě neměl, byl způsob sklízení shaderů bez API klíče;
> ten doplňuje `shadertoy/import_manual.py` (popsáno v rozhodnutí A a Fázi 1
> níže). Co zůstává neověřené mimo M2 (cloud na to nemá Flutter SDK ani GPU):
> skutečná kompilace `impellerc`, headless render, `flutter analyze`/`test`,
> QA na zařízení — `pytest -m "not network and not llm"` v cloudu projde
> (217+ testů), zbytek se skipuje a čeká na M2.

## Kontext

`pipeline/` už obsahuje první verzi generátoru GLSL filtrů (LangGraph, 5 agentů:
`style_architect → rag_retriever → glsl_coder → validator ⟲ → ranker`). RAG je
naplněný jen 24 vlastními shadery z `mirrorbooth/shaders/`, validace je regex +
volitelný `glslangValidator`, hodnocení je čistě textové (LLM nevidí výsledek)
a integrace do aplikace je ruční („zkopíruj .frag, zaregistruj v pubspec a
`mirror_filter.dart`“).

Cíl v2: napojit pipeline na **Shadertoy** (největší veřejná knihovna GLSL
shaderů, oficiální REST API) a udělat z ní end-to-end nástroj, který

1. sklízí kandidátní shadery ze Shadertoy (seznam vybraný uživatelem nebo API, cache, licenční filtr),
2. buď je **deterministicky portuje** na MirrorBooth kontrakt (režim *port*),
   nebo je použije jen jako **RAG inspiraci** pro nový shader (režim *inspire*),
3. ověří výsledek skutečným Flutter kompilátorem (`impellerc`), ne regexem,
4. vyrenderuje headless náhled nad testovací selfie a ohodnotí ho vizuálně,
5. jedním příkazem zaregistruje filtr do aplikace tak, že `flutter analyze` +
   `flutter test` projdou.

---

## Předpoklady a rozhodnutí (přečti jako první)

| # | Rozhodnutí | Důvod |
|---|-----------|-------|
| A | „ToyShader knihovna“ = **Shadertoy** (shadertoy.com). Oficiální App Key (`shadertoy.com/myapps`) se v praxi dlouhodobě novým žadatelům nevydává. **Scraping view-stránky je vyloučen — ne kvůli ToS rizikům, ale protože shadertoy.com je za Cloudflare bot-ochranou (JS výzva „Just a moment…“) a cokoli, co by se ji snažilo obejít (hraný User-Agent, headless prohlížeč apod.), je obcházení bezpečnostní kontroly. To se nedělá, ani v cloudu, ani na M2, ani „jen na čtení“.** Realizace: `shadertoy/client.py` (`ShadertoyClient`) mluví **jen** s oficiálním `/api/v1/…?key=` a aktivuje se jen s `SHADERTOY_API_KEY` v `.env`; `shadertoy/model.py` (`Shader`/`RenderPass`/`RenderInput`) je na zdroji nezávislý. Všechny stažené i ručně získané shadery leží jako JSON v `rag/shadertoy_cache/` (gitignored) — `harvest.py --from-cache` a `agents/transpiler.py`'s `load_source_shader()` čtou odtud **před** voláním API, takže cache-first fallback funguje bez klíče, pokud v ní něco je. `shadertoy/import_manual.py` + staging adresář `shadertoy_manual/` (`_TEMPLATE.json`, `README.md`, oba commitnuté) tohle dělají použitelným: uživatel si shader prohlédne ve svém běžném prohlížeči (Network panel → zkopírovat JSON, nebo ruční přepis do šablony), `import_manual.py` to zvaliduje přes `Shader.model_validate` a zapíše do cache — žádný kód v `pipeline/` sám nevolá shadertoy.com mimo `ShadertoyClient`. | Klíč nikdy nebyl zaručený a automatizované stahování ze stránky za Cloudflare výzvou je bezpečnostní obcházení, ne jen riziko ToS — to je mimo rozsah toho, co tento nástroj (nebo kdokoli jiný) smí dělat. Ruční import do stejné cache, kterou už `--from-cache`/`load_source_shader` uměly číst, dosáhne stejného cíle bez automatizovaného přístupu k shadertoy.com a beze změny downstream kódu (licence, portabilita, transpiler). |
| B | **Výchozí licence Shadertoy je CC BY-NC-SA 3.0 — nekomerční.** MirrorBooth prodává kolekce Art/Fantasy jako IAP. Proto: režim *port* smí přímo převzít kód **pouze** ze shaderů, které mají v hlavičce explicitně permisivní licenci (MIT, CC0, public domain, CC BY, Unlicense, BSD). Vše ostatní jde jen do RAG jako inspirace (technika, ne kód) a výstupní shader píše LLM od nuly. Každý portovaný `.frag` má povinnou atribuční hlavičku (autor, URL, licence). | Právní riziko pro placené kolekce. Toto pravidlo nesmí obejít žádný CLI přepínač; jen `--i-accept-nc-license` pro lokální experimenty, který zapíše `license_ok=false` do metadat a `integrate.py` takový shader odmítne. |
| C | LLM zůstává na lokálním OpenAI-kompatibilním endpointu („Spark“, viz `config.py`). Přidej ale abstrakci `llm.py` s providerem `spark` (výchozí) a volitelně `anthropic` (oficiální `anthropic` SDK, model `claude-opus-5`) — ten je potřeba hlavně pro vizuálního rankera (Fáze 5), protože lokální llama3 nevidí obrázky. Bez nastaveného `ANTHROPIC_API_KEY` se vizuální ranker vypne a pipeline funguje jako dnes. | Uživatel má lokální inferenci; nechceme tvrdou závislost na cloudu. |
| D | Cílová Flutter verze je ta z CI (`FLUTTER_VERSION: '3.41.x'`, Impeller). Kompilační validace používá `impellerc` z Flutter SDK (`FLUTTER_ROOT`), ne `glslangValidator`. `glslangValidator` zůstává jen jako fallback, když `FLUTTER_ROOT` není nastaven. | Regex validace dnes propouští konstrukty, které Impeller odmítne (`fwidth`, `texelFetch`, `bool` uniformy, `uint`…). |
| E | Uniform kontrakt aplikace se **nemění**. Pořadí float slotů v `_FilterShaderPainter` (`filtered_mirror_canvas.dart`) je pevné: `uResolution(2) → uTime(1, jen needsTime) → uFaceCenter(2)+uFaceScale(1) (jen needsFace)`. Sampler je vždy jen `uTexture`. Každý nový shader musí uniformy deklarovat přesně v tomto pořadí a nesmí mít žádné jiné. Shadertoy `iMouse` se mapuje na `uFaceCenter` (viz tabulka níže). | Painter nastavuje uniformy podle indexů; jiné pořadí = tichý rozbitý shader na zařízení. |
| F | Zařízení v cloudu není. Headless render (Fáze 5) je náhrada, ne důkaz. Finální QA na iOS/Android dělá uživatel; plán to bere jako součást Definition of Done s poznámkou „ověřeno uživatelem“. | |

---

## Cílová architektura

```
                        ┌──────────────── harvest.py (dávkově) ───────────────┐
import_manual.py ─────►│ rag/shadertoy_cache/*.json → license_classifier    │
(nebo ShadertoyClient   │        → portability_classifier → harvest_report.md │
 s SHADERTOY_API_KEY)   └──────────────┬─────────────────────┬────────────────┘
                                    │ permisivní licence    │ všechny (jen text)
                                    ▼                       ▼
                             režim PORT              rag/ingest_shadertoy.py → ChromaDB
                                    │                       │
run.py --from-shadertoy <id> ───────┤   run.py --style "…" ─┘ (režim INSPIRE, jako dnes,
                                    │                          RAG má navíc Shadertoy chunky)
                                    ▼
   ┌─── LangGraph ──────────────────────────────────────────────────────────┐
   │ (port)  transpiler ──► llm_fixer ⟲ ──► validator(impellerc) ──► preview │
   │ (inspire) style_architect → rag_retriever → glsl_coder ⟲ validator → preview │
   │                                                              │          │
   │                                          ranker (text + vize) ◄─────────┘
   └──────────────────────────────────────────────────────────────┬─────────┘
                                                                  ▼
                              output/<run>/ : filter_x.frag, tech_spec.json,
                                              rank_report.json, preview_t*.png,
                                              provenance.json
                                                                  │
                    integrate.py --run-dir … --collection art --label … ──► mirrorbooth/
                    (kopie .frag, pubspec, mirror_filter.dart, flutter analyze+test)
```

---

## Kontrakt: Shadertoy → MirrorBooth

Transpiler (Fáze 3) je deterministický textový převod. Vše, co nejde převést
deterministicky, dostane LLM „fixer“ jako konkrétní instrukci (ne volnou ruku).

| Shadertoy | MirrorBooth | Poznámka |
|-----------|-------------|----------|
| `void mainImage(out vec4 fragColor, in vec2 fragCoord)` | funkce zůstává, generuje se `main()`: `vec2 fc = FlutterFragCoord().xy; fc.y = uResolution.y - fc.y; vec4 c; mainImage(c, fc); fragColor = vec4(clamp(c.rgb, 0.0, 1.0), 1.0);` | Shadertoy má počátek vlevo dole, Flutter vlevo nahoře → flip Y. Parametr `fragColor` stíní globální `out vec4 fragColor` — legální GLSL; pokud `impellerc` protestuje, přejmenuj parametr regexem na `stColor`. |
| `iResolution` (vec3) | `vec3(uResolution, 1.0)` — vlož `#define iResolution vec3(uResolution, 1.0)` | Zachovává `iResolution.xy`, `.x`, `.y`. |
| `iTime` | `uTime` (deklaruj `uniform float uTime;` jen pokud se používá → `needs_time=true`) | |
| `iTimeDelta` | `const float iTimeDelta = 1.0/60.0;` | |
| `iFrame` | `int(uTime * 60.0)` | |
| `iMouse` | `vec4(uFaceCenter * uResolution, 0.0, 0.0)` → `needs_face=true` | Střed obličeje jako „myš“ = připravené na budoucí face tracking. Pokud shader `iMouse` nepoužívá, uniformy `uFaceCenter/uFaceScale` **nedeklaruj**. |
| `iChannel0` (ctype `webcam`, `video`, `texture` s UV ≈ `fragCoord/iResolution`) | `uTexture` přes helper `vec4 stSample(vec2 uv) { return texture(uTexture, vec2(uv.x, 1.0 - uv.y)); }`; `texture(iChannel0, X)` → `stSample(X)` | Kamera je top-left; po flipu fragCoord musíme UV flipnout zpět. `textureLod(iChannel0, X, l)` → `stSample(X)`, tříargumentové `texture(...)` → dvouargumentové. `sampler wrap=repeat` → `stSample(fract(X))`. |
| `iChannel0` jako **datová textura** (Shadertoy preset noise `/media/a/*.png`) | nahradit procedurálním hash-noise (`hash21`, value noise) | Deterministicky nelze; transpiler označí `needs_llm_fix=["noise_texture"]` a fixer dostane hotový snippet noise funkce z `pipeline/snippets/noise.glsl`. |
| `iChannel1..3`, cubemap, buffer, keyboard, sound, music, `iDate`, `iSampleRate`, `iChannelResolution[n>0]` | **nepodporováno → shader odmítnut** v `portability_classifier` (skóre 0) | Multi-pass (Buffer A/B) je v1 mimo rozsah. Tab `Common` (type `common`) se předřadí před `Image` kód. |
| `#version`, `precision …;` | odstranit | Flutter přidává sám. |
| `dFdx/dFdy/fwidth` | fixer: nahradit `fwidth(x)` konstantou `(1.5 / uResolution.y)` nebo analytickým odhadem; když to nedává smysl, odmítnout | Impeller je nepodporuje. |
| `texelFetch`, `textureSize`, `bool`/`uint` proměnné, uniform pole, `sampler` pole | validator hlásí, fixer opravuje (`textureSize` → `uResolution`), jinak odmítnout | Dle Flutter dokumentace nepodporováno. |
| `gl_FragCoord` | `FlutterFragCoord()` | Už v dnešním validatoru. |

**Kategorizace shaderu** (`portability_classifier`, výstup do `provenance.json`):

- `image_filter` — vzorkuje `iChannel0` ve screen-space (UV odvozené z `fragCoord/iResolution`), žádné další kanály. Přímý port. Priorita 1.
- `procedural` — nevzorkuje žádný kanál (fraktály, plasma, raymarching…). Portuje se přes **kompozitní šablonu**: procedurální barva se míchá s kamerou (`multiply` / `screen` / `overlay` / maska podle luminance / maska podle Sobel hran), režim volí LLM v `tech_spec.blend_mode`. Priorita 2.
- `data_texture` — používá preset texturu jako šum → LLM fix (viz tabulka). Priorita 3.
- `unsupported` — cokoli z posledního řádku tabulky. Neportuje se, ale text jde do RAG.

**Rozpočet výkonu** (heuristika ve validatoru, mobilní GPU): odhad
`Σ (iterace smyčky × texture fetch v těle)` ≤ 64 a hloubka vnořených smyček ≤ 2;
raymarching > 48 kroků = varování, > 96 = chyba. Hodnoty ulož do
`config.py`, aby šly ladit.

---

## Fáze implementace

Každá fáze = jeden PR, vlastní testy, zelené `ci.yml`. Pořadí je závazné,
protože každá fáze staví na předchozí.

### Fáze 0 — Hygiena a tooling `pipeline/`

- `pyproject.toml` (nebo aspoň `requirements-dev.txt`) s `pytest`, `ruff`; `pipeline/tests/`.
- `llm.py`: `get_llm(role: Literal["architect","coder","ranker","fixer","vision"])`
  vracející klienta podle `settings.llm_provider` (`spark` | `anthropic`). Stávající
  agenti ho použijí místo přímého `ChatOpenAI(...)` (4× duplikovaný kód).
- `config.py`: přidat `shadertoy_api_key`, `flutter_root`, `llm_provider`,
  `anthropic_model = "claude-opus-5"`, výkonnostní limity, `preview_enabled`.
  Doplnit `.env.example`.
- Oprava chyb v dnešním kódu, které v2 rozbijí:
  - `state.py`: přidat pole `source` (`{"kind": "shadertoy"|"style", "id", "license", …}`),
    `needs_face`, `needs_time`, `category`, `preview_paths`, `provenance`.
  - `style_architect.py`: `json.loads` bez ošetření → použít společný
    `parse_json_block()` (už existuje 3× v různých podobách).
  - `validator.py`: `retry_count` se inkrementuje i při poslední neúspěšné iteraci a
    graf pak ukončí s vadným kódem bez příznaku → přidat `state["validation_passed"]`
    a v `run.py` výstup jasně označit `FAILED`.
- CI: nový job `pipeline-tests` v `.github/workflows/ci.yml` (`python -m pytest pipeline/tests -m "not network and not llm"`).
  Toto je jediná povolená změna mimo `pipeline/` v této fázi.

**Hotovo, když:** `pytest` běží offline, `run.py --style …` funguje beze změny chování.

### Fáze 1 — zdroje shaderů, licence, klasifikace, harvest

Implementováno v `pipeline/shadertoy/` (commit `38ffbba` + no-key doplněk):

- `model.py` — pydantic modely nezávislé na zdroji: `Shader.info` (id, name,
  username, description, tags, likes, viewed, date), `renderpass[]` (`type`:
  image/common/buffer/sound/cubemap, `code`, `inputs[].ctype`:
  texture/webcam/video/buffer/cubemap/keyboard/music/musicstream/mic/volume,
  `inputs[].sampler.{wrap,vflip,filter}`, `inputs[].channel`).
- `client.py` — `ShadertoyClient`: `GET /api/v1/shaders/{id}?key=` a
  `GET /api/v1/shaders/query/{q}?key=`, aktivní jen s `SHADERTOY_API_KEY`.
  Zdvořilý rate limit, backoff na 429/5xx, 403 hlásí „Shadertoy blocks some
  proxies/cloud IPs; run from a LAN machine“. Bez klíče: `MissingApiKeyError`
  s odkazem na `shadertoy.com/myapps`, ne pokus o obejití. Každý stažený
  shader se atomicky cache-uje do `rag/shadertoy_cache/<id>.json`.
- `import_manual.py` — **doplněk pro chybějící API klíč (žádné HTTP na
  shadertoy.com).** Promuje ručně získané shadery ze staging adresáře
  `shadertoy_manual/` (`_TEMPLATE.json` + `README.md` commitnuté, zbytek
  gitignored) do té samé `rag/shadertoy_cache/` — buď přímou kopii JSON,
  který uživatel zkopíroval z Network panelu svého prohlížeče, nebo
  konverzí minimální ruční šablony (`id`, `code`, `author`, `description`
  s licenčním textem, volitelně `channel0_ctype`) přes `Shader.model_validate`.
  Validuje, vypíše licenci/kategorii/portovatelnost (znovupoužívá
  `license.py`/`portability.py`) a hlásí chyby per soubor, ne traceback.
- `license.py` — klasifikátor z hlavičkových komentářů kódu + description:
  regexy pro MIT, CC0, „public domain“, Unlicense, BSD, „CC BY 4.0/3.0“ (bez
  NC/SA) → `permissive=True`; restriktivní znak (NC, SA, GPL, „all rights
  reserved“…) vždy vyhrává; odvozené dílo („based on shadertoy.com/view/…“)
  není permisivní; chybějící hlavička → `permissive=False`,
  `license="CC BY-NC-SA 3.0 (default)"`.
- `portability.py` — kategorizace (`image_filter`/`procedural`/
  `data_texture`/`unsupported`) + `portability_score` 0–100 (odečty za
  nepodporované konstrukty, délku, hloubku/náklad smyček, raymarch kroky).
- `harvest.py` (CLI): `--query … --sort … --num …` (potřebuje
  `SHADERTOY_API_KEY`, bez něj jasná hláška a exit 2) nebo `--from-cache`
  (**funguje bez klíče** — klasifikuje vše, co je v `rag/shadertoy_cache/`,
  ať se tam dostalo přes API nebo přes `import_manual.py`). Report
  `output/harvest_<ts>/harvest_report.md` (licence, kategorie, skóre, port
  yes/no, URL) + `candidates.json`. Doporučené dotazy (do vyhledávání na
  webu, pokud klíč není, nebo do `--query`, pokud je): `webcam`,
  `postprocessing`, `filter`, `image`, `cartoon`, `pixel`, `halftone`,
  `kaleidoscope`, `vhs`, `thermal`, `sketch`.

**Workflow bez klíče:** ruční sběr do `shadertoy_manual/` (§ 2.2b setup
dokumentu) → `python shadertoy/import_manual.py shadertoy_manual/` →
`python shadertoy/harvest.py --from-cache` → `python run.py --from-shadertoy <id>`.
Žádný z těchto kroků nevolá shadertoy.com; `agents/transpiler.py`'s
`load_source_shader()` čte cache před API i v *port* režimu, takže totéž
platí i bez harvestu.

**Hotovo** (ověřeno v cloudu, bez sítě): `python -m pytest -m "not network and not llm"`
běží zeleně (217+ testů, Shadertoy klient na `respx` fixturách, `import_manual`
na lokálních JSON); ruční end-to-end smoke test (`import_manual.py` →
`harvest.py --from-cache` → `run.py --from-shadertoy`) proběhl transpilerem,
validátorem (regex + perf rozpočet, `impellerc`/`glslangValidator` skipnuty —
chybí v cloudu) a headless náhledem (skipnuto — chybí `moderngl`), spadl až na
LLM rankeru, protože SPARK je jen v LAN — to je čekaná hranice, ne chyba.

### Fáze 2 — RAG ingest Shadertoy

- `rag/ingest_shadertoy.py`: čte cache z Fáze 1, chunkuje po funkcích (znovupoužij
  `_split_functions` z `ingest.py`, vytáhni ho do `rag/chunking.py`), metadata:
  `source="shadertoy"`, `shader_id`, `author`, `license`, `permissive`, `tags`,
  `likes`, `category`, `techniques` (rozšiř `TECHNIQUE_TAGS` o Shadertoy slovník:
  `raymarch`, `sdf`, `kaleido`, `voronoi`, `fbm`, `dither`, `halftone`, `bloom`,
  `vhs`, `barrel`…).
- `rag_retriever.py`: filtr `where` podle `category`/`permissive` z `tech_spec`,
  do promptu coderu přidávat u každého snippetu řádek `// source: shadertoy/<id> by <author> (<license>)`,
  a **tvrdé pravidlo v system promptu coderu**: snippety s `permissive=false` jsou
  jen technická reference, kód se nesmí kopírovat doslova.
- Oddělená ChromaDB kolekce `shadertoy_shaders` (nemíchat s `glsl_shaders`), retriever
  dotazuje obě a spojuje výsledky.

**Hotovo, když:** `run.py --style "kaleidoscope mirror"` v režimu *inspire* dostane
do kontextu Shadertoy snippety s atribucí; ingest je idempotentní (upsert).

### Fáze 3 — Transpiler a režim *port*

- `shadertoy/transpile.py`: čistá funkce `transpile(shader) -> TranspileResult(code, needs_time, needs_face, category, fixes_needed[], attribution_header)`.
  Implementuje tabulku kontraktu. Pořadí bloků výstupu:
  1. atribuční hlavička (`// Ported from https://www.shadertoy.com/view/<id> — "<name>" by <author>, <license>`),
  2. `#include <flutter/runtime_effect.glsl>`,
  3. uniformy **v kontraktním pořadí** (`uTexture`, `uResolution`, `[uTime]`, `[uFaceCenter, uFaceScale]`),
  4. `out vec4 fragColor;`,
  5. `#define`/`const` shim (`iResolution`, `iTimeDelta`, `iFrame`, `iMouse`), `stSample`,
  6. `Common` kód, `Image` kód,
  7. generovaný `main()` (u kategorie `procedural` kompozitní šablona z `pipeline/templates/composite_main.glsl`).
- Nový agent `agents/llm_fixer.py`: dostane kód + `fixes_needed` + chyby z validatoru
  a smí měnit **jen** to, co je vyjmenované (prompt to říká explicitně a diff se
  loguje do `output/<run>/fixer_diff.patch`).
- `graph.py`: druhý vstupní bod. Podle `state["source"]["kind"]`: `port` →
  `transpiler → validator ⟲ llm_fixer → preview → ranker`; `style` → stávající cesta.
- `run.py --from-shadertoy <id> [--name …] [--blend multiply]`. Odmítnutí kvůli licenci
  nebo kategorii `unsupported` musí být srozumitelná hláška, ne traceback.
- `output/<run>/provenance.json`: zdroj, licence, kategorie, seznam aplikovaných
  transformací, hash původního kódu.

**Testy:** fixtury `tests/fixtures/shadertoy/*.json` (ručně sestavené minimální
shadery pro každý řádek tabulky) → golden `.frag` výstupy; test „uniformy jsou
v kontraktním pořadí a žádné navíc“; test odmítnutí multi-pass/cubemap.

### Fáze 4 — Validator v2 (kompilace `impellerc`)

- `validator.py` rozdělit na `checks/contract.py` (regexy: povinné/zakázané
  konstrukty rozšířené o `fwidth|dFdx|dFdy|texelFetch|textureSize|\buint\b|\bbool\b\s+\w+\s*;|uniform\s+\w+\s+\w+\s*\[`, kontrola **pořadí a úplnosti** uniformů podle `needs_time/needs_face`),
  `checks/perf.py` (rozpočet smyček/fetchů) a `checks/compile.py`.
- `checks/compile.py`: najdi `impellerc` v `$FLUTTER_ROOT/bin/cache/artifacts/engine/<host>-x64/`,
  include dir `…/shader_lib`. Volání odpovídá tomu, jak shadery kompiluje Flutter
  tooling — před implementací si ověř aktuální flagy ve zdroji
  `packages/flutter_tools/lib/src/build_system/targets/shader_compiler.dart`
  odpovídající verze SDK (přibližně: `--runtime-stage-metal --runtime-stage-gles --runtime-stage-vulkan --iplr --sl=<out> --spirv=<out> --input=<frag> --input-type=frag --include=<shader_lib>`).
  Kompiluj pro všechny tři runtime stage; chybu z kteréhokoli vrať coderu/fixeru
  očištěnou o cesty. Když `FLUTTER_ROOT` chybí → fallback `glslangValidator`
  se shim hlavičkou (`#version 310 es`, `precision highp float;`, stub `FlutterFragCoord()`),
  a do výstupu **výrazné varování**, že kompilace nebyla ověřena Impellerem.
- `ranker.py`: skóre `flutter_compliance` nastavuj programově (1 = neprošel kompilátor),
  ne od LLM.

**Hotovo, když:** všech 24 stávajících shaderů projde `checks/compile.py` (regresní
test, spouští se lokálně s `FLUTTER_ROOT`, v CI je `@pytest.mark.flutter` a skipuje
se, pokud SDK není).

### Fáze 5 — Headless náhled a vizuální hodnocení

- `preview/render.py`: `moderngl` standalone kontext (`backend="egl"`, fallback na
  softwarový `osmesa`/`llvmpipe`; když nic není, náhled se přeskočí s varováním).
  Shim pro desktop GL: `#version 330`, `vec4 FlutterFragCoord() { return vec4(gl_FragCoord.x, uResolution.y - gl_FragCoord.y, 0.0, 1.0); }`,
  odstraň `#include`. Vstup: testovací selfie z `pipeline/assets/test_input/*.png`
  (**zrcadlově zkomponovaný** snímek 540×960, jako to vidí shader v aplikaci;
  uživatel dodá vlastní fotky, repo obsahuje jen syntetický placeholder — žádný
  obrázek s nejasnou licencí). Uniformy podle kontraktu, `uFaceCenter=(0.5,0.5)`,
  `uFaceScale=0.35`. Rendruj `t = 0, 0.7, 1.9 s` → `preview_t0.png` …
- `preview/metrics.py`: podíl NaN/černých pixelů, podíl pixelů shodných se vstupem
  („shader nic nedělá“), průměrná luminance/saturace, doba renderu. Tvrdé prahy
  → `validation_errors` (např. > 30 % černé = chyba).
- `agents/vision_ranker.py`: jen s providerem `anthropic` — pošle 3 náhledy + popis
  a dostane `visual_quality`, `face_readability` (obličej zůstává rozpoznatelný),
  `matches_intent`, `artifacts`. Sloučí se do `rank_report.json`. Bez klíče se
  ranker chová jako dnes.

### Fáze 6 — Integrace do aplikace (`integrate.py`)

Jediná fáze, která mění Flutter kód. Nejprve **jednorázová příprava** v aplikaci
(vlastní malý PR):

- `mirrorbooth/lib/core/mirror_filter.dart`: přidat markery pro generátor na
  6 místech (enum členy per kolekce, `label`, `icon`, `needsTime`, `needsFace`,
  `shaderAsset`; `collection` se řeší vložením do správné `||` skupiny), např.
  `// @shadergen:enum:art`, `// @shadergen:label`, … Sémantika kódu se nemění.
- `mirrorbooth/pubspec.yaml`: marker `# @shadergen:shaders` na konci seznamu `shaders:`.
- Nový Dart test `mirrorbooth/test/shader_contract_test.dart`: pro každý
  `MirrorFilter` s assetem načte `.frag` a regexem ověří, že deklarované uniformy
  odpovídají `needsTime`/`needsFace` a jsou v kontraktním pořadí. Chrání i ručně
  psané shadery.

Pak `pipeline/integrate.py --run-dir output/<run> --enum-name hologram --label Holo --icon "◇" --collection art [--dry-run]`:

1. odmítne run s `license_ok=false`, `validation_passed=false` nebo bez `impellerc` kompilace (přepínač `--force` jen s varováním do stdout),
2. zkopíruje `.frag` do `mirrorbooth/shaders/filter_<snake>.frag`,
3. vloží řádky podle markerů (idempotentně — druhé spuštění nic nezmění),
4. spustí `cd mirrorbooth && flutter pub get && flutter analyze && flutter test`;
   při chybě vrátí změny zpět (`git checkout -- …` jen na dotčené soubory, nikdy `git reset`),
5. vypíše souhrn a připomene: „změna `.frag` vyžaduje full restart, ne hot reload“.

`collection` switch nemá wildcard záměrně — chybějící case = compile error, což
`flutter analyze` chytí. Neměň to.

### Fáze 7 — Dávkový režim a report

- `run.py --batch candidates.json --top 10`: projede kandidáty z harvestu (jen
  permisivní + kategorie ≠ unsupported), seřadí podle `rank_report.overall`,
  vytvoří `output/batch_<ts>/README.md` s náhledy (markdown s obrázky) a tabulkou.
  Paralelizace max. 2 (lokální LLM).
- Přidej `pipeline/README.md`: instalace, `.env`, workflow harvest → run → integrate,
  licenční pravidla, jak dodat vlastní testovací fotky.

---

## Testování (shrnutí)

| Vrstva | Nástroj | Síť/LLM | CI |
|--------|---------|---------|----|
| licence, portability, transpile, contract checks, integrate (na kopiích souborů v tmp) | `pytest`, golden soubory | ne | ano |
| Shadertoy klient + `import_manual` | `pytest` + nahrané fixtury (`respx` pro klienta, lokální JSON pro import) | ne (marker `network` jen pro živý smoke test klienta) | ano |
| kompilace `impellerc` nad 24 stávajícími shadery | `pytest -m flutter` | ne, ale potřebuje SDK | lokálně; v CI skip |
| headless render | `pytest -m gl` | ne, potřebuje EGL | lokálně |
| celý graf | `pytest -m llm` s mock LLM (předpřipravené odpovědi) | ne | ano |
| Dart `shader_contract_test.dart` | `flutter test` | ne | ano (stávající job) |

---

## Rizika a jak s nimi plán počítá

- **Licence** (viz rozhodnutí B) — největší riziko, řešeno tvrdě v kódu a v `integrate.py`.
- **Výkon na mobilu** — většina populárních Shadertoy shaderů jsou těžké raymarchery.
  Řeší rozpočet ve validatoru + preferenece kategorie `image_filter` v harvestu.
  I tak: finální ověření FPS jen na zařízení.
- **Nepodporované konstrukty v Impelleru** (`fwidth`, `bool`, `texelFetch`) — řeší
  kompilace `impellerc`; regexy jsou jen rychlý předfiltr.
- **Y-flip** dvakrát (fragCoord i UV textury) — nejčastější zdroj „obraz vzhůru nohama“.
  Golden test s asymetrickým testovacím obrázkem v headless renderu to musí odhalit.
- **Shadertoy nedává API klíče a je za Cloudflare bot-ochranou** — proto je
  cache-first fallback (`--from-cache`, `load_source_shader`) + ruční import
  (`import_manual.py`) výchozí cesta, ne `ShadertoyClient`: žádné
  automatizované stahování ze stránky, protože by to bylo obcházení
  bezpečnostní kontroly, ne jen riziko ToS. Toto se netestuje, nezkouší se
  to „jen lehce“ ani se nehledá alternativní technika, jak Cloudflare výzvu
  obejít — je to mimo rozsah natrvalo, dokud Shadertoy sám nezmění přístupovou
  politiku. Množství shaderů pro *port* režim je tím limitované na to, co
  uživatel ručně nasbírá — to je přijatelný kompromis, *inspire* režim na tom
  není závislý vůbec. Zkusit o klíč zažádat znovu (e-mail, Shadertoy Discord)
  může běžet souběžně, ale nic na něm nečeká — jakmile klíč přijde, `--query`
  režim `harvest.py` a `ShadertoyClient` fungují beze změny.
- **Shadertoy API** (když klíč přece přijde) — nedokumentované limity, občasné
  403 přes proxy. Cache + backoff; harvest musí být přerušitelný a znovu
  spustitelný.
- **Stínění `fragColor`** — pokud kompilátor odmítne, přejmenovat parametr (viz tabulka).

## Co NEDĚLAT

- Neměnit uniform kontrakt ani `_FilterShaderPainter`.
- Nepřidávat závislost aplikace na pipeline (pipeline zůstává vývojářský nástroj mimo Flutter build).
- Nevkládat do repa žádný Shadertoy kód s nepermisivní licencí, ani „dočasně“.
- Nevkládat do repa fotky lidí bez jasné licence.
- **Nikdy nepsat kód, který dělá HTTP požadavek na shadertoy.com mimo
  oficiální `/api/v1/...` s platným klíčem.** Žádný scraping view-stránky,
  žádný headless prohlížeč, žádný hraný User-Agent, žádný pokus vyřešit
  nebo obejít Cloudflare výzvu — to je obcházení bezpečnostní kontroly a
  je to mimo rozsah bez výjimky, i „jen pro test“, i na M2.
- Neobcházet `flutter analyze`/`flutter test` v `integrate.py`.
- Neimplementovat multi-pass buffery v této iteraci.

## Definition of Done

1. `import_manual.py shadertoy_manual/` + `harvest.py --from-cache` (bez API
   klíče, bez jakéhokoli požadavku na shadertoy.com) vytvoří report s
   licencemi a kategoriemi. ✅ hotovo a ověřeno v cloudu.
2. `run.py --from-shadertoy <permisivní image_filter id>` vyprodukuje `.frag`, který
   projde `impellerc` pro Metal/GLES/Vulkan a má náhledy. — kód hotov (Fáze 3–5),
   **ověření skutečnou kompilací/renderem čeká na M2**.
3. `run.py --style "…"` (inspire) používá Shadertoy RAG s atribucí. — kód hotov (Fáze 2).
4. `integrate.py` zaregistruje filtr, `flutter analyze` i `flutter test` jsou zelené,
   `shader_contract_test.dart` prochází pro všechny filtry. — kód hotov (Fáze 6),
   **`flutter analyze`/`test` ověří jen M2** (v cloudu Flutter SDK není).
5. Alespoň **3 nové filtry** (1× port z permisivního zdroje, 2× inspire) v kolekci
   Art nebo Fantasy, ověřené uživatelem na zařízení (poznámka v PR). — **zbývá udělat
   na M2**, teď když `import_manual.py` dává k portu reálné kandidáty.
6. `pipeline/README.md` popisuje celý workflow; CI má job `pipeline-tests`. — hotovo.

## Doporučené pořadí PR

Fáze 0–7 jsou sloučené (viz banner nahoře); pořadí níže je historický záznam.
Zbývá jen PR s `import_manual.py` (tento) a pak PR s prvními reálnými filtry.

1. `pipeline: tooling, llm provider, state/validator fixes, tests + CI job` (Fáze 0) ✅
2. `pipeline: shadertoy client, license + portability classifier, harvest` (Fáze 1) ✅
3. `pipeline: shadertoy RAG ingest + retriever attribution` (Fáze 2) ✅
4. `pipeline: shadertoy→flutter transpiler, port mode, llm fixer` (Fáze 3) ✅
5. `pipeline: impellerc compile validator + perf budget` (Fáze 4) ✅
6. `pipeline: headless preview + vision ranker` (Fáze 5) ✅
7. `app: shadergen markers + shader_contract_test` a `pipeline: integrate.py` (Fáze 6) ✅
8. `pipeline: batch mode + README` (Fáze 7) ✅
9. `pipeline: import_manual.py — harvest/port bez API klíče` ← **tento PR**
10. PR s prvními 3 filtry (vyžaduje M2: QA na zařízení).
