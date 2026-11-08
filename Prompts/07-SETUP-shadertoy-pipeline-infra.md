# 07 — SETUP: co rozjet na SPARK / M2 / JODA pro ShaderGen v2

Doplněk k `07-PLAN-shadertoy-pipeline.md`. Plán říká *co* je naprogramované,
tento dokument říká, *co musí běžet na kterém stroji*, aby šlo pipeline
skutečně spustit a výsledek dostat do aplikace.

> **Stav (2026-11-08):** Fáze 0–7 jsou implementované a sloučené do `main`.
> SPARK už běží (LiteLLM gateway, viz § 1) — sekce níže popisuje reálně
> nasazenou konfiguraci, ne kandidáty na nasazení. Jediné, co ještě nebylo
> ověřené, je běh na M2 samotný (Flutter/`impellerc`/GPU/zařízení) — to je
> těžiště tohoto dokumentu teď.

## Role strojů

| Stroj | Role | Musí na něm být |
|-------|------|-----------------|
| **SPARK** (192.168.88.66) | Inference server. Jediné, co pipeline potřebuje po síti. | LiteLLM gateway na `:8080/v1` (už běží, viz § 1). |
| **M2** (Mac) | Vývojářský a integrační stroj. Tady se pipeline spouští, tady je Flutter, Xcode a připojený telefon. | Python 3.11+, Flutter SDK 3.41.x (kvůli `impellerc`), Xcode + CocoaPods, git, Claude Code CLI, `.env` s klíči. |
| **JODA** | *Předpoklad:* Linux box (GPU/server). Volitelný. Dává smysl jen pro dávkové běhy (`--batch` přes desítky kandidátů) a headless render mimo Mac. Když ho nechceš zapojovat, **SPARK + M2 stačí**. | Totéž jako M2 minus Flutter/Xcode, plus EGL/Mesa pro headless GL. |

Důležité omezení: **Claude Code v cloudu (tato session) nevidí SPARK ani
telefon.** Na shadertoy.com se nevolá vůbec mimo `ShadertoyClient` s platným
klíčem (viz plán, rozhodnutí A — Cloudflare bot-ochrana, ne síťové omezení
cloudu), takže to samo o sobě omezením není. Co v cloudu ověřeno **je**:
`python -m pytest -m "not network and not llm"` (217+ testů zeleně), `ruff
check`/`format`, a end-to-end smoke test `import_manual.py` →
`harvest.py --from-cache` → `run.py --from-shadertoy` až po bod, kde graf
potřebuje SPARK. Co ověřeno **není** a vyžaduje M2: skutečná kompilace
`impellerc`, headless render (chybí `moderngl`/GPU), `flutter analyze`/`test`,
QA na zařízení.

---

## 1. SPARK — inference (už nasazeno)

### 1.1 LiteLLM gateway

Podle `pipeline/config.py`/`.env.example`: SPARK obsluhuje **LiteLLM gateway**
na `http://192.168.88.66:8080/v1`, ne starý přímý `:8000` s `llama3` (ten je
mrtvý, nepočítej s ním). Dva modelové aliasy:

- `openclaw-default` — qwen36, vidí i obrázky (stejný alias pro `coder`,
  `architect`, `ranker`, `fixer` i `vision` roli).
- `bench-nano` — Nano-30B, rychlejší coder alternativa.

**SPARK okno:** LLM pro ShaderGen běží jen **17:00–01:00** (rozvrh SPARKu,
session „Director“ má prioritu). Mimo okno živé běhy selžou na LLM spojení —
to je čekané, ne chyba pipeline. Na SPARKu samotném nic nespouštěj ani
nezastavuj, Directorovi nepřekážej; pipeline jen posílá HTTP na gateway.
Dávkové běhy (`--batch`, hromadný `import_manual.py` + `run.py`) ohlas
Directorovi předem.

Kontrola z M2 (v okně 17:00–01:00):

```bash
curl -s http://192.168.88.66:8080/v1/models | jq '.data[].id'
curl -s http://192.168.88.66:8080/v1/chat/completions \
  -H "Authorization: Bearer $SPARK_API_KEY" -H 'Content-Type: application/json' \
  -d '{"model":"openclaw-default","messages":[{"role":"user","content":"Write a GLSL function that returns luminance of vec3."}],"max_tokens":200}' | jq -r '.choices[0].message.content'
```

### 1.2 Vision ranker

`openclaw-default` (qwen36) vidí obrázky, takže vizuální ranker (Fáze 5) jede
na stejné gateway — žádná druhá instance, žádný extra port. `ANTHROPIC_API_KEY`
zůstává jen jako nepovinná alternativa (`LLM_PROVIDER_VISION=anthropic`,
model `claude-opus-5`) pro případ, že SPARK/qwen36 nestačí na kvalitu.

### 1.3 Co na SPARKu být nemusí

- Embeddingy: `sentence-transformers/all-MiniLM-L6-v2` běží na CPU tam, kde
  běží pipeline (M2/JODA). Na SPARKu nic.
- ChromaDB: lokální adresář `pipeline/rag/db/` na stroji s pipeline. Žádný server.

---

## 2. M2 — pipeline, Flutter, integrace, QA

### 2.1 Jednorázová instalace

```bash
# Nástroje
brew install python@3.11 glslang jq        # glslang = fallback validátor
xcode-select --install                     # pokud Xcode CLT chybí
sudo gem install cocoapods                  # nebo brew install cocoapods

# Flutter 3.41.x (stejná verze jako CI) + stažení engine artefaktů včetně impellerc
flutter --version                           # musí být 3.41.x, channel stable
flutter precache --ios --macos
find "$(dirname "$(dirname "$(which flutter)")")/bin/cache/artifacts/engine" -name impellerc
#  → očekávaná cesta …/engine/darwin-x64/impellerc ; tuto cestu ověřuje checks/compile.py

# Repo + Python prostředí
git clone git@github.com:lioilsources/MirrorBooth.git && cd MirrorBooth/pipeline
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt            # vše: RAG, náhledy, Anthropic
pip install -r requirements-dev.txt         # testy + ruff
cp .env.example .env                        # a vyplnit, viz § 2.2
```

První `pip install` a první běh stáhnou z internetu embedding model
(~90 MB) a PyTorch pro CPU (~200 MB). Potom je offline vše kromě: `harvest.py`
s `--query` (oficiální Shadertoy API, volitelné), a případného Anthropic API.
`import_manual.py` a `--from-cache` nikdy nic nestahují.

### 2.2 `.env`

| Proměnná | Odkud | Nutná pro |
|----------|-------|-----------|
| `SPARK_BASE_URL=http://192.168.88.66:8080/v1` | SPARK, viz § 1.1 | vše |
| `SPARK_MODEL=openclaw-default` (nebo `bench-nano`) | SPARK, viz § 1.1 | vše |
| `SPARK_API_KEY=…` | LiteLLM gateway klíč (ne „dummy“ — gateway auth vyžaduje) | vše |
| `SPARK_VISION_MODEL=openclaw-default` | SPARK, viz § 1.2 | vizuální ranker (volitelné) |
| `SHADERTOY_API_KEY=…` (volitelné) | shadertoy.com → *Profile → Apps* → *Create app*. **V praxi se novým žadatelům dlouho nevydává** — formulář běžně nikdy neodpoví. Zkus zažádat (nebo napsat na Shadertoy Discord), ale neblokuj na tom — bez klíče funguje výchozí cesta přes `--from-cache`/`import_manual.py` (§ 2.2b). | jen volitelný `--query` režim `harvest.py` |
| `FLUTTER_ROOT=$(dirname $(dirname $(readlink -f $(which flutter))))` | M2, absolutní cesta | `impellerc` validace |
| `LLM_PROVIDER=spark` | – | výchozí |
| `ANTHROPIC_API_KEY` | volitelné | vizuální ranker přes Anthropic místo SPARKu |

Bez klíče nikam nic nevoláš — pipeline na shadertoy.com nic nezkouší mimo
`ShadertoyClient` (viz plán, rozhodnutí A: Cloudflare bot-ochrana, žádný
`curl`/headless prohlížeč na view-stránku, to je obcházení bezpečnostní
kontroly, ne jen ToS riziko). Shadery se sbírají ručně, viz § 2.2b.

Pokud App Key přece dorazí, ověření oficiálního API:

```bash
curl -s "https://www.shadertoy.com/api/v1/shaders/query/webcam?num=3&key=$SHADERTOY_API_KEY"
```

### 2.2b Sestavení `pipeline/shadertoy_manual/` (ruční sběr, bez automatizace)

Bez API klíče je sběr kandidátů ruční, jednou za čas, přímo na webu ve tvém
běžném prohlížeči — to není totéž jako to, co pipeline nesmí dělat: ty si
stránku otevíráš jako člověk, nic ji nenutí předstírat, že je někdo jiný.

1. Procházej shadertoy.com ve svém prohlížeči (přihlášený vlastním účtem),
   hledej podle tipů v `07-PLAN-shadertoy-pipeline.md` Fáze 1 (`webcam`,
   `postprocessing`, `kaleidoscope`, `vhs`, `halftone`…).
2. U každého kandidáta hned na stránce zkontroluj licenci v popisu / hlavičce
   kódu — MIT/CC0/public domain/Unlicense/BSD/čisté CC BY je ok pro *port*,
   cokoli jiné (včetně chybějící hlavičky) jde jen do *inspire* (RAG).
3. Ulož shader do `pipeline/shadertoy_manual/<cokoli>.json`:
   - **Network panel (nejjednodušší):** F12 → záložka *Network* → znovu načti
     stránku → najdi request, který vrací JSON shaderu → *Copy response* →
     ulož. Přesný tvar, který pak přímo čte `shadertoy/model.py`.
   - **Ruční přepis:** zkopíruj `pipeline/shadertoy_manual/_TEMPLATE.json`,
     vyplň `id` (z URL za `/view/`), `author`, `code`, `description` (popis
     nebo licenční text) a `channel0_ctype`, pokud shader čte `iChannel0`.
4. Naimportuj a zkontroluj výsledek:

   ```bash
   python shadertoy/import_manual.py shadertoy_manual/
   #   → ověří tvar, vypíše licenci/kategorii/port=yes|no, uloží do rag/shadertoy_cache/
   ```

20–50 shaderů stačí na první harvest. Soubory v `shadertoy_manual/` (kromě
`_TEMPLATE.json`/`README.md`) se nekomitují — stejné pravidlo jako u
testovacích fotek.

### 2.3 Telefon a Flutter

- iPhone/Android připojený kabelem, `flutter devices` ho vidí, iOS signing v
  Xcode funguje (`flutter run -d ios` na aktuálním `main` projde ještě
  **před** jakoukoli změnou — jinak ladíš dvě věci najednou).
- Po každé změně `.frag` je nutný full restart aplikace, hot reload shadery
  nepřekompiluje.

### 2.4 Claude Code CLI

- `claude` nainstalovaný a přihlášený na M2; spouštěj ho z kořene repa, aby
  načetl `CLAUDE.md`.
- Předej mu explicitně: SPARK je dostupný jen z M2 (a jen v okně 17:00–01:00),
  a pro živé testy (`-m network`, `-m llm`, `-m flutter`, `-m gl`) má použít
  lokální prostředí: `python -m pytest -m flutter`, `-m gl`, `-m network`
  (viz `pipeline/README.md` § Testy).

---

## 3. JODA — volitelný dávkový stroj (předpoklad: Linux)

Zapoj jen pokud chceš pouštět `--batch` přes desítky kandidátů mimo Mac.

```bash
sudo apt install -y python3.11 python3.11-venv git glslang-tools \
     libegl1 libgl1-mesa-dri libgles2 mesa-utils          # headless GL (llvmpipe stačí)
git clone git@github.com:lioilsources/MirrorBooth.git && cd MirrorBooth/pipeline
python3.11 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
cp .env.example .env    # stejné hodnoty jako na M2, FLUTTER_ROOT nech prázdný → fallback glslang
export PYOPENGL_PLATFORM=egl
```

- Bez Flutter SDK tu **neběží** `impellerc` ani `integrate.py`. JODA tedy
  produkuje `output/<run>/` adresáře; přenos na M2 přes `rsync` a integrace
  až tam. Pokud chceš i kompilaci na JODA, nainstaluj Flutter pro Linux
  (`flutter precache --linux`, `impellerc` je v `engine/linux-x64/`).
- ChromaDB je lokální — po `rag/ingest*.py` na JODA nemá M2 stejná data. Buď
  ingest pouštěj na obou, nebo `rag/db/` synchronizuj (`rsync`), nikdy
  nesdílej po NFS za běhu.
- Když má JODA GPU s NVIDIA driverem, headless render poběží na něm (rychlejší
  metriky), jinak `llvmpipe` — pro 540×960 a 3 snímky pořád v pořádku.

---

## 4. Checklist před prvním během na M2

1. V okně 17:00–01:00: `curl …/v1/models` vrací `openclaw-default`/`bench-nano`. ☐
2. `find … -name impellerc` na M2 najde binárku; `flutter --version` = 3.41.x. ☐
3. `cd pipeline && source .venv/bin/activate && python -m pytest -m "not network and not llm"`
   proběhne zeleně (totéž, co už prošlo v cloudu — potvrzuje, že M2 prostředí sedí). ☐
4. `python shadertoy/import_manual.py shadertoy_manual/` na pár ručně sebraných
   shaderech (§ 2.2b) nahlásí alespoň jeden `port=yes`. ☐
5. `python -m pytest -m flutter` (potřebuje `FLUTTER_ROOT`) — všech 24 shaderů
   aplikace + goldeny transpileru projdou přes skutečný `impellerc`. ☐
6. `python -m pytest -m gl` — headless render (potřebuje `moderngl` + GPU/EGL). ☐
7. `cd ../mirrorbooth && flutter analyze && flutter test && flutter run -d ios`
   prochází na nezměněném `main`. ☐

## 5. Cílový příkazový sled (bez API klíče)

```bash
cd MirrorBooth/pipeline && source .venv/bin/activate

python shadertoy/import_manual.py shadertoy_manual/
python shadertoy/harvest.py --from-cache
#   → output/harvest_<ts>/harvest_report.md ; vyber permisivní image_filter id (port = yes)

python run.py --from-shadertoy <id> --name hologram
#   → output/filter_hologram_<ts>/{filter_hologram.frag, preview_t0.png, rank_report.json, provenance.json}

python integrate.py --run-dir output/filter_hologram_<ts> \
    --enum-name hologram --label Holo --icon "◇" --collection art
#   → kopie .frag, pubspec, mirror_filter.dart, flutter analyze + test

cd ../mirrorbooth && flutter run -d ios        # QA na zařízení, poté commit
```

S App Key (pokud přijde) navíc funguje `python shadertoy/harvest.py --query
webcam --sort popular --num 50`. Inspire režim beze změny: `python run.py
--style "…" --name …`, jen s bohatším RAG (Shadertoy snippety z cache).
