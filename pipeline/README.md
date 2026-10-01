# ShaderGen — generátor filtrů pro MirrorBooth

Vývojářský nástroj (není součástí Flutter buildu), který vyrábí GLSL filtry pro
aplikaci. Dva režimy:

- **inspire** — `run.py --style "…"`: LLM navrhne a napíše nový shader; RAG mu dává
  techniky z vlastních shaderů aplikace a ze Shadertoy (jen jako inspiraci).
- **port** — `run.py --from-shadertoy <id>`: deterministický převod shaderu ze
  Shadertoy na kontrakt aplikace; LLM jen opravuje vyjmenované problémy.

Výsledek se ověří kompilátorem Flutteru (`impellerc`), vyrenderuje headless nad
testovací selfie, ohodnotí a jedním příkazem (`integrate.py`) zaregistruje do aplikace.

```
harvest.py ─► rag/ingest_shadertoy.py ─► run.py (inspire | port | --batch) ─► integrate.py ─► QA na zařízení
```

Plán a rozhodnutí: `Prompts/07-PLAN-shadertoy-pipeline.md`, příprava strojů:
`Prompts/07-SETUP-shadertoy-pipeline-infra.md`.

---

## Instalace

```bash
cd pipeline
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt          # vše (RAG, náhledy, Anthropic)
pip install -r requirements-dev.txt      # testy + ruff
cp .env.example .env                     # a vyplnit (viz níže)
```

`requirements.txt` stáhne při prvním běhu embedding model (~90 MB) a PyTorch pro CPU.
Náhledy potřebují OpenGL 3.3 bez okna: na macOS funguje rovnou, na Linuxu
`apt install libegl1 libgl1-mesa-dri` (llvmpipe stačí).

### `.env`

| Proměnná | K čemu | Poznámka |
|---|---|---|
| `SPARK_BASE_URL` | LiteLLM gateway na SPARKu | `http://192.168.88.66:8080/v1` |
| `SPARK_MODEL` | coder/architect/ranker/fixer | `openclaw-default` (qwen36) nebo `bench-nano` |
| `SPARK_API_KEY` | klíč gateway | |
| `SPARK_VISION_MODEL` | vizuální ranker | `openclaw-default` (qwen36 vidí obrázky) |
| `LLM_PROVIDER`, `LLM_PROVIDER_VISION` | `spark` (výchozí) nebo `anthropic` | Anthropic potřebuje `ANTHROPIC_API_KEY` |
| `SHADERTOY_API_KEY` | harvest, port | zdarma na <https://www.shadertoy.com/myapps> |
| `FLUTTER_ROOT` | `impellerc` validace | `$(dirname $(dirname $(readlink -f $(which flutter))))` — absolutní cesta |

**SPARK okno:** LLM pro ShaderGen běží jen **17:00–01:00** (rozvrh SPARKu, session
„Director“). Mimo okno živé běhy selžou na LLM; dávky ohlašuj Directorovi. Na SPARKu nic
nespouštěj ani nezastavuj — pipeline jen posílá HTTP na gateway.

Bez `FLUTTER_ROOT` se validuje fallbackem `glslangValidator` a výstup je výrazně
označen „NOT verified by impellerc“ — `integrate.py` takový běh odmítne.

---

## Workflow

### 1. Harvest ze Shadertoy

```bash
python shadertoy/harvest.py --query webcam --query postprocessing --sort popular --num 50
python shadertoy/harvest.py --from-cache        # jen překlasifikovat cache (offline)
```

Výstup `output/harvest_<ts>/harvest_report.md` (licence, kategorie, skóre, URL) a
`candidates.json`. Stažené shadery jsou v `rag/shadertoy_cache/` — přerušený harvest
stačí pustit znovu. Doporučené dotazy: `webcam`, `postprocessing`, `filter`, `image`,
`cartoon`, `pixel`, `halftone`, `kaleidoscope`, `vhs`, `thermal`, `sketch`.

Kategorie: `image_filter` (vzorkuje kameru, přímý port) › `procedural` (fraktály,
plasma… — míchá se s kamerou přes kompozitní šablonu) › `data_texture` (šumová
textura → procedurální šum, také kompozit) › `unsupported` (multi-pass, cubemap,
klávesnice, zvuk… — jen RAG).

### 2. RAG

```bash
python rag/ingest.py              # vlastní shadery aplikace -> kolekce glsl_shaders
python rag/ingest_shadertoy.py    # cache ze Shadertoy -> kolekce shadertoy_shaders (idempotentní)
```

### 3a. Inspire

```bash
python run.py --style "kaleidoscope mirror with neon edges" --name neon_kaleido
```

### 3b. Port

```bash
python run.py --from-shadertoy <id> [--name hologram] [--blend multiply|screen|overlay|luma_mask|edge_mask]
```

`--blend` platí pro procedurální/šumové shadery (výchozí `screen`). Licence nebo
nepodporovaná kategorie = srozumitelné odmítnutí (exit 2).

### 3c. Dávka

```bash
python run.py --batch output/harvest_<ts>/candidates.json --top 10
```

Projede nejlepší přenositelné kandidáty (max. 2 souběžně), seřadí podle
`rank_report.overall` a zapíše `output/batch_<ts>/README.md` s náhledy a příkazy pro
integraci.

### Výstup jednoho běhu — `output/filter_<name>_<ts>/`

| Soubor | Obsah |
|---|---|
| `filter_<name>.frag` | shader (u portu s atribuční hlavičkou) |
| `validation.json` | `validation_passed`, chyby, výsledek `impellerc` per target |
| `provenance.json` | zdroj, licence, `license_ok`, kategorie, transformace, kola fixeru |
| `rank_report.json` | skóre (text + vize), `flutter_compliance` z kompilátoru |
| `preview_t*.png` | headless náhledy (t = 0 / 0.7 / 1.9 s u animovaných) |
| `fixer_diff.patch` | co změnil LLM fixer (port) |
| `FAILED` | jen když validace neprošla — neintegrovat |

### 4. Integrace do aplikace

```bash
python integrate.py --run-dir output/filter_hologram_<ts> \
    --enum-name hologram --label Holo --icon "◇" --collection art [--dry-run]
```

Zkopíruje `.frag`, vloží řádky u markerů `// @shadergen:*` v `mirror_filter.dart` a
`# @shadergen:shaders` v `pubspec.yaml`, pak `flutter pub get && flutter analyze &&
flutter test`. Při chybě vrátí všechny dotčené soubory přesně do původního stavu.
Druhé spuštění nic nezmění. Markery v aplikaci neodstraňuj.

### 5. QA na zařízení

`cd ../mirrorbooth && flutter run -d ios` — po změně `.frag` je nutný **full restart**
(hot reload shadery nepřekompiluje). Zkontroluj FPS, orientaci, čitelnost obličeje.
Headless náhled je náhrada, ne důkaz.

---

## Licence (tvrdé pravidlo)

Shadertoy má výchozí licenci **CC BY-NC-SA 3.0 (nekomerční)** a MirrorBooth prodává
kolekce Art/Fantasy. Proto:

- **port** přijme jen shader s explicitně permisivní licencí v hlavičce (MIT, CC0,
  public domain, CC BY, Unlicense, BSD). Restriktivní znak (NC, SA, GPL, „all rights
  reserved“…) vždy vyhrává; odvozené dílo („based on shadertoy.com/view/…“, „Fork …“)
  není permisivní.
- každý portovaný `.frag` nese atribuční hlavičku (autor, URL, licence) — nemaž ji.
- nepermisivní shadery jdou do RAG jen jako **reference techniky**; coder má zákaz
  kopírovat jejich kód.
- `--i-accept-nc-license` je jen pro lokální experiment: zapíše `license_ok=false` a
  `integrate.py` takový běh **odmítne bez možnosti přepsání**.
- do repa nepatří žádný Shadertoy kód s nepermisivní licencí, ani „dočasně“.

---

## Vlastní testovací fotky

Náhledy se renderují nad `assets/test_input/`. V repu je jen syntetický
`placeholder_selfie.png` (`assets/make_placeholder.py`) — žádný člověk, žádný cizí
obrázek. Vlastní fotku vlož jako `assets/test_input/<cokoli>.png`:

- **540×960**, portrét, **zrcadlově zkomponovaná** (tak, jak ji shader vidí v aplikaci),
- použije se první (abecedně) soubor, který nezačíná na `placeholder`,
- fotky lidí **necommituj** (repo nesmí obsahovat fotky s nejasnou licencí) — přidej je
  do `.git/info/exclude`.

---

## Testy

```bash
python -m pytest -m "not network and not llm"   # offline, totéž běží v CI (job pipeline-tests)
FLUTTER_ROOT=… python -m pytest -m flutter       # impellerc: všech 24 shaderů aplikace + goldeny
python -m pytest -m gl                           # headless render (orientace, náhledy)
python -m pytest -m network                      # živé Shadertoy API (potřebuje klíč)
ruff check . && ruff format --check .
```

Goldeny transpileru po záměrné změně: `UPDATE_GOLDEN=1 python -m pytest tests/test_transpile.py`.

## Mapa kódu

| Cesta | Co dělá |
|---|---|
| `shadertoy/` | API klient + cache, licence, přenositelnost, harvest, transpiler |
| `agents/` | uzly grafu: architect, retriever, coder, transpiler, fixer, validator, preview, ranker, vision ranker |
| `checks/` | validator v2: kontrakt (regexy + pořadí uniformů), výkonový rozpočet, `impellerc` |
| `preview/` | headless render (moderngl) + metriky |
| `rag/` | chunking, ingest vlastních a Shadertoy shaderů |
| `templates/`, `snippets/` | kompozitní `main()`, procedurální náhrada šumové textury |
| `graph.py`, `run.py`, `batch.py`, `integrate.py` | LangGraph, CLI, dávka, integrace |
