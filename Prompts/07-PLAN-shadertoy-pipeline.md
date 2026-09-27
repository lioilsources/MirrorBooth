# 07 — ShaderGen v2: pipeline generující nové MirrorBooth filtry z knihovny Shadertoy

> Plán pro implementaci (Opus). Provozní příprava strojů (SPARK/M2/JODA) je v `07-SETUP-shadertoy-pipeline-infra.md`. Pracuj po fázích, každou fázi uzavři zeleným CI
> a samostatným PR. Nepřeskakuj testy a nikdy nesahej do souborů mimo `pipeline/`
> a mimo sekci **Fáze 6** bez explicitního rozhodnutí v tomto plánu.

## Kontext

`pipeline/` už obsahuje první verzi generátoru GLSL filtrů (LangGraph, 5 agentů:
`style_architect → rag_retriever → glsl_coder → validator ⟲ → ranker`). RAG je
naplněný jen 24 vlastními shadery z `mirrorbooth/shaders/`, validace je regex +
volitelný `glslangValidator`, hodnocení je čistě textové (LLM nevidí výsledek)
a integrace do aplikace je ruční („zkopíruj .frag, zaregistruj v pubspec a
`mirror_filter.dart`“).

Cíl v2: napojit pipeline na **Shadertoy** (největší veřejná knihovna GLSL
shaderů, oficiální REST API) a udělat z ní end-to-end nástroj, který

1. sklízí kandidátní shadery ze Shadertoy (vyhledávání, cache, licenční filtr),
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
| A | „ToyShader knihovna“ = **Shadertoy** (shadertoy.com), přístup přes oficiální API `https://www.shadertoy.com/api/v1/…?key=APPKEY`. App key si uživatel vytvoří na `shadertoy.com/myapps` a uloží do `pipeline/.env` jako `SHADERTOY_API_KEY`. | Jiná knihovna s tímto jménem neexistuje. Pokud se ukáže, že autor myslel jiný zdroj, změní se pouze modul `shadertoy/client.py`. |
| B | **Výchozí licence Shadertoy je CC BY-NC-SA 3.0 — nekomerční.** MirrorBooth prodává kolekce Art/Fantasy jako IAP. Proto: režim *port* smí přímo převzít kód **pouze** ze shaderů, které mají v hlavičce explicitně permisivní licenci (MIT, CC0, public domain, CC BY, Unlicense, BSD). Vše ostatní jde jen do RAG jako inspirace (technika, ne kód) a výstupní shader píše LLM od nuly. Každý portovaný `.frag` má povinnou atribuční hlavičku (autor, URL, licence). | Právní riziko pro placené kolekce. Toto pravidlo nesmí obejít žádný CLI přepínač; jen `--i-accept-nc-license` pro lokální experimenty, který zapíše `license_ok=false` do metadat a `integrate.py` takový shader odmítne. |
| C | LLM zůstává na lokálním OpenAI-kompatibilním endpointu („Spark“, viz `config.py`). Přidej ale abstrakci `llm.py` s providerem `spark` (výchozí) a volitelně `anthropic` (oficiální `anthropic` SDK, model `claude-opus-5`) — ten je potřeba hlavně pro vizuálního rankera (Fáze 5), protože lokální llama3 nevidí obrázky. Bez nastaveného `ANTHROPIC_API_KEY` se vizuální ranker vypne a pipeline funguje jako dnes. | Uživatel má lokální inferenci; nechceme tvrdou závislost na cloudu. |
| D | Cílová Flutter verze je ta z CI (`FLUTTER_VERSION: '3.41.x'`, Impeller). Kompilační validace používá `impellerc` z Flutter SDK (`FLUTTER_ROOT`), ne `glslangValidator`. `glslangValidator` zůstává jen jako fallback, když `FLUTTER_ROOT` není nastaven. | Regex validace dnes propouští konstrukty, které Impeller odmítne (`fwidth`, `texelFetch`, `bool` uniformy, `uint`…). |
| E | Uniform kontrakt aplikace se **nemění**. Pořadí float slotů v `_FilterShaderPainter` (`filtered_mirror_canvas.dart`) je pevné: `uResolution(2) → uTime(1, jen needsTime) → uFaceCenter(2)+uFaceScale(1) (jen needsFace)`. Sampler je vždy jen `uTexture`. Každý nový shader musí uniformy deklarovat přesně v tomto pořadí a nesmí mít žádné jiné. Shadertoy `iMouse` se mapuje na `uFaceCenter` (viz tabulka níže). | Painter nastavuje uniformy podle indexů; jiné pořadí = tichý rozbitý shader na zařízení. |
| F | Zařízení v cloudu není. Headless render (Fáze 5) je náhrada, ne důkaz. Finální QA na iOS/Android dělá uživatel; plán to bere jako součást Definition of Done s poznámkou „ověřeno uživatelem“. | |

---

## Cílová architektura

```
                     ┌──────────────── harvest.py (dávkově) ────────────────┐
Shadertoy API ──────►│ client (cache JSON) → license_classifier            │
                     │        → portability_classifier → harvest_report.md │
                     └──────────────┬─────────────────────┬────────────────┘
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

### Fáze 1 — Shadertoy klient, licence, klasifikace, harvest

Nový balíček `pipeline/shadertoy/`:

- `client.py` — `list_ids()`, `search(query, sort="popular"|"newest"|"love"|"hot", filter=…, from_=0, num=25)`,
  `get(id)`. Endpointy: `GET /api/v1/shaders`, `GET /api/v1/shaders/query/{q}`,
  `GET /api/v1/shaders/{id}`, vždy s `?key=`. API vrací jen shadery s viditelností
  „public + API“. Cache surového JSON do `pipeline/rag/shadertoy_cache/<id>.json`
  (gitignore). Zdvořilý rate limit (≤ 1 req/s, exponenciální backoff na 429/5xx).
  Bez klíče: jasná chybová hláška s odkazem na `shadertoy.com/myapps`.
- `model.py` — pydantic modely pro odpověď: `Shader.info` (id, name, username, description,
  tags, likes, viewed, date), `renderpass[]` (`type`: image/common/buffer/sound/cubemap,
  `code`, `inputs[].ctype`: texture/webcam/video/buffer/cubemap/keyboard/music/musicstream/
  mic/volume, `inputs[].sampler.{wrap,vflip,filter}`, `inputs[].channel`).
- `license.py` — klasifikátor z hlavičkových komentářů kódu + description:
  regexy pro MIT, CC0, „public domain“, Unlicense, BSD, „CC BY 4.0/3.0“ (bez NC/SA)
  → `permissive=True`; cokoli jiné (včetně absence hlavičky) → `permissive=False`,
  `license="CC BY-NC-SA 3.0 (default)"`. Testy na fixturách (min. 10 reálných hlaviček).
- `portability.py` — kategorizace podle tabulky výše + `portability_score` 0–100
  (odečty za každý problematický konstrukt, počet řádků, odhad smyček).
- `harvest.py` (CLI): `--query webcam --sort popular --num 50 [--tags postprocessing]`
  → stáhne, klasifikuje, zapíše `output/harvest_<ts>/harvest_report.md` (tabulka:
  id, název, autor, licence, kategorie, skóre, URL) a `candidates.json`.
  Doporučené dotazy pro první běh: `webcam`, `postprocessing`, `filter`, `image`,
  `cartoon`, `pixel`, `halftone`, `kaleidoscope`, `vhs`, `thermal`, `sketch`.

**Hotovo, když:** `harvest.py` na 50 shaderech proběhne, report ukazuje rozdělení
licencí a kategorií; testy klienta běží na nahraných fixturách (`responses`/`respx`), bez sítě.

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
| Shadertoy klient | `pytest` + nahrané fixtury (`respx`) | ne (marker `network` pro živý smoke test) | ano |
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
- **Shadertoy API** — nedokumentované limity, občasné 403 přes proxy. Cache + backoff;
  harvest musí být přerušitelný a znovu spustitelný.
- **Stínění `fragColor`** — pokud kompilátor odmítne, přejmenovat parametr (viz tabulka).

## Co NEDĚLAT

- Neměnit uniform kontrakt ani `_FilterShaderPainter`.
- Nepřidávat závislost aplikace na pipeline (pipeline zůstává vývojářský nástroj mimo Flutter build).
- Nevkládat do repa žádný Shadertoy kód s nepermisivní licencí, ani „dočasně“.
- Nevkládat do repa fotky lidí bez jasné licence.
- Neobcházet `flutter analyze`/`flutter test` v `integrate.py`.
- Neimplementovat multi-pass buffery v této iteraci.

## Definition of Done

1. `harvest.py --query webcam --num 50` vytvoří report s licencemi a kategoriemi.
2. `run.py --from-shadertoy <permisivní image_filter id>` vyprodukuje `.frag`, který
   projde `impellerc` pro Metal/GLES/Vulkan a má náhledy.
3. `run.py --style "…"` (inspire) používá Shadertoy RAG s atribucí.
4. `integrate.py` zaregistruje filtr, `flutter analyze` i `flutter test` jsou zelené,
   `shader_contract_test.dart` prochází pro všechny filtry.
5. Alespoň **3 nové filtry** (1× port z permisivního zdroje, 2× inspire) v kolekci
   Art nebo Fantasy, ověřené uživatelem na zařízení (poznámka v PR).
6. `pipeline/README.md` popisuje celý workflow; CI má job `pipeline-tests`.

## Doporučené pořadí PR

1. `pipeline: tooling, llm provider, state/validator fixes, tests + CI job` (Fáze 0)
2. `pipeline: shadertoy client, license + portability classifier, harvest` (Fáze 1)
3. `pipeline: shadertoy RAG ingest + retriever attribution` (Fáze 2)
4. `pipeline: shadertoy→flutter transpiler, port mode, llm fixer` (Fáze 3)
5. `pipeline: impellerc compile validator + perf budget` (Fáze 4)
6. `pipeline: headless preview + vision ranker` (Fáze 5)
7. `app: shadergen markers + shader_contract_test` a `pipeline: integrate.py` (Fáze 6)
8. `pipeline: batch mode + README` (Fáze 7), následně PR s prvními 3 filtry.
