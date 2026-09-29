# 07 — SETUP: co rozjet na SPARK / M2 / JODA před spuštěním ShaderGen v2

Doplněk k `07-PLAN-shadertoy-pipeline.md`. Plán říká *co* se má naprogramovat,
tento dokument říká, *co musí běžet na kterém stroji*, aby šlo pipeline
skutečně spustit a výsledek dostat do aplikace.

## Role strojů

| Stroj | Role | Musí na něm být |
|-------|------|-----------------|
| **SPARK** (192.168.88.66) | Inference server. Jediné, co pipeline potřebuje po síti. | OpenAI-kompatibilní endpoint na `:8000/v1` s coder modelem; volitelně druhý (vision) model pro hodnocení náhledů. |
| **M2** (Mac) | Vývojářský a integrační stroj. Tady se pipeline spouští, tady je Flutter, Xcode a připojený telefon. | Python 3.11+, Flutter SDK 3.41.x (kvůli `impellerc`), Xcode + CocoaPods, git, Claude Code CLI, `.env` s klíči. |
| **JODA** | *Předpoklad:* Linux box (GPU/server). Volitelný. Dává smysl jen pro dávkové běhy (harvest + `--batch` přes desítky shaderů) a headless render mimo Mac. Když ho nechceš zapojovat, **SPARK + M2 stačí**. | Totéž jako M2 minus Flutter/Xcode, plus EGL/Mesa pro headless GL. |

Důležité omezení: **Claude Code v cloudu (tato session) nevidí SPARK ani telefon**
a přes proxy se nedostane na Shadertoy (403). Implementaci fází 0–7 lze psát a
testovat v cloudu nad fixturami, ale skutečné běhy (`harvest`, `run.py`,
`integrate.py`, QA na zařízení) se spouštějí z **Claude Code CLI na M2**.

---

## 1. SPARK — inference

### 1.1 LLM endpoint

- Server: vLLM (doporučeno) nebo Ollama s `/v1` kompatibilitou. Musí odpovídat na
  `GET /v1/models` a `POST /v1/chat/completions`.
- **Model:** `llama3` z `config.py` je pro GLSL slabý. Nasaď coder model, který se
  vejde do paměti a zvládne ~16k kontext (RAG snippety + celý shader + chyby
  kompilátoru). Kandidáti podle paměti SPARKu:
  - Qwen2.5-Coder-32B-Instruct (fp8/AWQ) — nejlepší poměr kvalita/velikost pro kód,
  - Llama-3.3-70B-Instruct (4-bit) — když je paměť ≥ 64 GB,
  - DeepSeek-Coder-V2-Lite — když je paměti málo.
- Název modelu, který server hlásí v `/v1/models`, musí být **přesně** hodnota
  `SPARK_MODEL` v `.env` (vLLM je na to striktní, Ollama shovívavější).
- Nastav `--max-model-len 16384` (nebo víc), povol souběh 2 požadavků
  (`--max-num-seqs 2` stačí; pipeline paralelizuje max. 2 běhy).
- Spouštěj jako **systemd službu** (`Restart=always`), ať přežije reboot. Log do
  journalu.
- Firewall: port 8000 otevřený pro M2 (a JODA). Statická IP nebo DNS záznam
  (`spark.lan`) — pipeline má IP zadrátovanou jen v `.env`.

Kontrola z M2:

```bash
curl -s http://192.168.88.66:8000/v1/models | jq '.data[].id'
curl -s http://192.168.88.66:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"<SPARK_MODEL>","messages":[{"role":"user","content":"Write a GLSL function that returns luminance of vec3."}],"max_tokens":200}' | jq -r '.choices[0].message.content'
```

### 1.2 Vision model (volitelné, Fáze 5)

Vizuální ranker potřebuje model, který vidí obrázky. Dvě cesty:

1. **Na SPARKu** druhá instance vLLM s multimodálním modelem (Qwen2.5-VL-7B/32B
   nebo Llama-3.2-Vision-11B) na jiném portu, např. `:8001/v1`. Do `.env` přidat
   `SPARK_VISION_BASE_URL` a `SPARK_VISION_MODEL`; `llm.py` z Fáze 0 pak má roli
   `vision` i pro providera `spark` (plán počítal jen s Anthropic — rozšiř to).
2. **Anthropic API** (`LLM_PROVIDER_VISION=anthropic`, model `claude-opus-5`),
   vyžaduje `ANTHROPIC_API_KEY` a internet z M2. Žádná instalace na SPARKu.

Bez vision modelu pipeline běží, jen `rank_report.json` nemá vizuální skóre.

### 1.3 Co na SPARKu být nemusí

- Embeddingy: `sentence-transformers/all-MiniLM-L6-v2` běží na CPU tam, kde běží
  pipeline (M2/JODA). Na SPARKu nic.
- ChromaDB: lokální adresář `pipeline/rag/db/` na stroji s pipeline. Žádný server.

---

## 2. M2 — pipeline, Flutter, integrace, QA

### 2.1 Jednorázová instalace

```bash
# Nástroje
brew install python@3.11 glslang jq        # glslang = fallback validátor
xcode-select --install                     # pokud Xcode CLT chybí
sudo gem install cocoapods                 # nebo brew install cocoapods

# Flutter 3.41.x (stejná verze jako CI) + stažení engine artefaktů včetně impellerc
flutter --version                          # musí být 3.41.x, channel stable
flutter precache --ios --macos
find "$(dirname "$(dirname "$(which flutter)")")/bin/cache/artifacts/engine" -name impellerc
#  → očekávaná cesta …/engine/darwin-x64/impellerc ; tuto cestu ověřuje checks/compile.py

# Repo + Python prostředí
git clone git@github.com:lioilsources/MirrorBooth.git && cd MirrorBooth
cd pipeline
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt            # po Fázi 0 navíc: pip install -e ".[dev,preview]"
```

První `pip install` a první běh stáhnou z internetu embedding model z Hugging
Face (~90 MB) a PyTorch pro CPU (~200 MB). Potom pipeline běží offline, s výjimkou
Shadertoy API a případného Anthropic API.

### 2.2 Klíče a `.env`

```bash
cp .env.example .env
```

| Proměnná | Odkud | Nutná pro |
|----------|-------|-----------|
| `SPARK_BASE_URL=http://192.168.88.66:8000/v1` | SPARK | vše |
| `SPARK_MODEL=<id z /v1/models>` | SPARK | vše |
| `SPARK_API_KEY=dummy` | – | vLLM bez auth; jinak skutečný token |
| `SHADERTOY_API_KEY=…` | shadertoy.com → přihlásit → *Profile → Apps* → *Create app* → zkopírovat App Key | harvest, port režim (Fáze 1+) |
| `FLUTTER_ROOT=$(dirname $(dirname $(which flutter)))` | M2 | `impellerc` validace (Fáze 4) |
| `LLM_PROVIDER=spark` | – | výchozí |
| `SPARK_VISION_BASE_URL`, `SPARK_VISION_MODEL` **nebo** `ANTHROPIC_API_KEY` | viz 1.2 | vision ranker (Fáze 5), volitelné |

Shadertoy: účet je zdarma, App Key vzniká okamžitě. Ověření:

```bash
curl -s "https://www.shadertoy.com/api/v1/shaders/query/webcam?num=3&key=$SHADERTOY_API_KEY"
```

### 2.3 Telefon a Flutter

- iPhone/Android připojený kabelem, `flutter devices` ho vidí, iOS signing v Xcode
  funguje (`flutter run -d ios` na aktuálním `main` projde ještě **před** jakoukoli
  změnou — jinak ladíš dvě věci najednou).
- Po každé změně `.frag` je nutný full restart aplikace, hot reload shadery
  nepřekompiluje.

### 2.4 Claude Code CLI

- `claude` nainstalovaný a přihlášený na M2; spouštěj ho z kořene repa, aby načetl
  `CLAUDE.md`. Opus dostane jako vstup `Prompts/07-PLAN-shadertoy-pipeline.md`
  a tento soubor.
- Předej mu explicitně, že SPARK je dostupný jen z M2 a že pro živé testy
  (`-m network`, `-m llm`, `-m flutter`, `-m gl`) má použít lokální prostředí.

---

## 3. JODA — volitelný dávkový stroj (předpoklad: Linux)

Zapoj jen pokud chceš pouštět harvest a `--batch` přes desítky shaderů mimo Mac.

```bash
sudo apt install -y python3.11 python3.11-venv git glslang-tools \
     libegl1 libgl1-mesa-dri libgles2 mesa-utils          # headless GL (llvmpipe stačí)
git clone git@github.com:lioilsources/MirrorBooth.git && cd MirrorBooth/pipeline
python3.11 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
cp .env.example .env    # stejné hodnoty jako na M2, FLUTTER_ROOT nech prázdný → fallback glslang
export PYOPENGL_PLATFORM=egl
```

- Bez Flutter SDK tu **neběží** `impellerc` ani `integrate.py`. JODA tedy produkuje
  `output/<run>/` adresáře; přenos na M2 přes `rsync` a integrace až tam. Pokud
  chceš i kompilaci na JODA, nainstaluj Flutter pro Linux (`flutter precache --linux`,
  `impellerc` je v `engine/linux-x64/`).
- ChromaDB je lokální — po `rag/ingest*.py` na JODA nemá M2 stejná data. Buď ingest
  pouštěj na obou, nebo `rag/db/` synchronizuj (`rsync`), nikdy nesdílej po NFS
  za běhu.
- Když má JODA GPU s NVIDIA driverem, headless render poběží na něm (rychlejší
  metriky), jinak `llvmpipe` — pro 540×960 a 3 snímky pořád v pořádku.

---

## 4. Checklist před prvním „spusť to“

1. `curl …/v1/models` ze M2 vrací tvůj coder model. ☐
2. `find … -name impellerc` na M2 najde binárku; `flutter --version` = 3.41.x. ☐
3. `curl` na Shadertoy API s klíčem vrací JSON, ne 401. ☐
4. `cd pipeline && source .venv/bin/activate && python rag/ingest.py` proběhne
   (stáhne embedding model, naplní `rag/db/`). ☐
5. `python run.py --style "kaleidoscope mirror" --name kaleido_test` doběhne na
   **dnešní** verzi pipeline (ověření SPARK + Python prostředí, nezávisle na v2). ☐
6. `cd ../mirrorbooth && flutter analyze && flutter test && flutter run -d ios`
   prochází na nezměněném `main`. ☐
7. (Fáze 5) vision endpoint odpovídá nebo je nastavený `ANTHROPIC_API_KEY`. ☐

## 5. Cílový příkazový sled (po dokončení fází 1–6)

```bash
cd MirrorBooth/pipeline && source .venv/bin/activate

python shadertoy/harvest.py --query webcam --sort popular --num 50
#   → output/harvest_<ts>/harvest_report.md ; vyber permisivní image_filter id

python run.py --from-shadertoy <id> --name hologram
#   → output/filter_hologram_<ts>/{filter_hologram.frag, preview_t0.png, rank_report.json, provenance.json}

python integrate.py --run-dir output/filter_hologram_<ts> \
    --enum-name hologram --label Holo --icon "◇" --collection art
#   → kopie .frag, pubspec, mirror_filter.dart, flutter analyze + test

cd ../mirrorbooth && flutter run -d ios        # QA na zařízení, poté commit
```

Inspire režim beze změny: `python run.py --style "…" --name …`, jen s bohatším RAG.
