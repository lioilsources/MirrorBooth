# Plán: ToyShaders seed korpus + Shadertoy adaptér + auto-integrace do Flutter appky

## Context (proč)

MirrorBooth má funkční LangGraph pipeline v `pipeline/` (`style_architect → rag_retriever → glsl_coder → validator ⇄ retry → ranker`), která z přirozeného popisu vygeneruje GLSL filtr. Dnes ale končí výpisem "ručně zkopíruj `.frag` a zaregistruj v pubspec.yaml + mirror_filter.dart" a RAG báze indexuje pouze 26 vlastních shaderů — generátor se tedy nemá kde učit realtime techniky.

Cíl (dle rozhodnutí uživatele):
1. **ToyShaders** = vestavěný offline korpus Shadertoy-konvenčních realtime shaderů jako znalostní báze.
2. **Plná auto-integrace** vygenerovaného filtru end-to-end do Flutter appky.
3. **Batch CLI** jako dnes — žádný živý náhled/hot-reload, jen rozšíření grafu.

Výsledek: `python run.py --style "..." --name "..."` vyprodukuje filtr inspirovaný realtime Shadertoy technikami a sám ho zaregistruje do běžící appky.

> **Stav (ověřeno v pracovním stromu na větvi `claude/plan-shader-pipeline-filters-axG6R`):** scaffolding tohoto plánu už v repu existuje — `pipeline/agents/shadertoy_adapter.py`, `pipeline/agents/shadertoy_porter.py`, `pipeline/integrator.py`, `pipeline/seed_shaders/` (18 `.glsl` + LICENSE/NOTICE/README), `pipeline/tests/` (conftest + 3 testy) a všech **5 sentinelů v `mirrorbooth/lib/core/mirror_filter.dart`** (řádky 28/58/88/99/130) jsou na místě. Plán tedy nadále slouží jako **specifikace k ověření a dotažení**, ne jako stavba od nuly. Zbývající práce = projet Verification sekci, doplnit případné mezery a potvrdit idempotenci/compile-gate.

## Klíčová rozhodnutí

| Téma | Přístup |
|---|---|
| Seed korpus | `pipeline/seed_shaders/*.glsl`, Shadertoy konvence, **100 % originální CC0** (žádný vendorovaný Shadertoy kód — techniky nejsou chráněné, jen konkrétní výraz). + `LICENSE`/`NOTICE`/`README.md`. |
| Adaptér | Čistá deterministická utilita `pipeline/agents/shadertoy_adapter.py` (bez LLM, bez sítě). Volá ji ingest i nový graf node — jedna implementace, dva voláči. |
| Adaptér v grafu | Nový node `shadertoy_porter` mezi `rag_retriever` a `glsl_coder`. Portuje nejsilnější Shadertoy zásah do `state.port_reference`; finální kód píše dál `glsl_coder`. |
| RAG obsah | Ukládat **obě** varianty chunků: Shadertoy-originál i Flutter-port, rozlišené metadaty `convention` + `origin`. |
| Auto-integrace | Deterministický idempotentní `pipeline/integrator.py`, volaný z `run.py` **po** uložení výstupů (ne jako graf node — FS mutace mimo state machine, snadno testovatelné). Default ON, `--no-install` opt-out, gate na `settings.min_install_score`. |
| Editace Dart | Kotvení přes **sentinel komentáře** (jednorázová ruční úprava přidá 5 kotev), zápis all-or-nothing transakčně. Nikdy slepý regex přes enum. |

## Změny po souborech

### Nově vytvořit
- `pipeline/seed_shaders/` — ~18 `.glsl` Shadertoy-konvenčních shaderů (plasma, value_noise, fbm, voronoi, kaleidoscope, tunnel, raymarch_lite, domain_warp, chromatic_glow, scanline_crt, palette_cycle, hex_grid, curl_flow, starfield, metaballs, truchet, polar_warp, vignette_grain). Každý: hlavička (`SPDX-License-Identifier: CC0-1.0`, autor=MirrorBooth, shrnutí techniky) + `void mainImage(out vec4 fragColor, in vec2 fragCoord)`, aspoň jedna větev samplující `iChannel0` (aby port na kameru `uTexture` dával smysl). + `LICENSE` (CC0 1.0), `NOTICE` (originální díla, žádný Shadertoy obsah), `README.md` (konvence).
- `pipeline/agents/shadertoy_adapter.py` — `port_shadertoy(src, needs_time=None) -> PortResult` (ported GLSL + applied transforms + `unported_constructs`), `is_shadertoy_source(src) -> bool`. Transform pipeline: strip `#version`; detekce nepodporovaných (`iChannel1..3`, `iMouse`, `iChannelResolution`, `texelFetch`, `iDate`, `iFrame`) → `unported_constructs`; prepend Flutter hlavičky (`#include <flutter/runtime_effect.glsl>`, `uniform sampler2D uTexture`, `uniform vec2 uResolution`, `uniform float uTime` jen když je `iTime`/needs_time, `out vec4 fragColor`); word-boundary substituce `iResolution`→`uResolution`/`vec3(uResolution,0.0)`, `iTime`/`iGlobalTime`→`uTime`, `texture(iChannel0,X)`→`texture(uTexture,X)`; konverze entry-pointu `mainImage(out vec4 a, in vec2 b)`→`void main()` s injektovaným `vec2 b = FlutterFragCoord().xy;` a přejmenováním `a`→`fragColor` přes **brace-balanced** tělo (počítadlo závorek, ne regex).
- `pipeline/agents/shadertoy_porter.py` — `shadertoy_porter_node(state)`: projde `state["rag_context"]`, na `is_shadertoy_source` zásahy zavolá `port_shadertoy`, vybere nejsilnější bez `unported_constructs` do `port_reference` (+ `port_techniques`), jinak `port_reference=""`. Bez LLM/sítě.
- `pipeline/integrator.py` — idempotentní instalátor: (1) kopie `filter_<snake>.frag` → `mirrorbooth/shaders/`; (2) vložení `    - shaders/filter_<snake>.frag` do `pubspec.yaml` shaders bloku; (3) vložení záznamů do 5 míst v `mirror_filter.dart` (enum, label, icon, needsTime, shaderAsset) nad odpovídající sentinel. Odvození identifikátoru: `enumName`=lowerCamelCase z `--name`, při kolizi s existujícími enum identifikátory číselný suffix aplikovaný **konzistentně** na enum/5 míst/filename; `label` z `tech_spec.effect_name` (≤6 znaků), `icon` první ASCII písmeno (jinak fallback z poolu mimo použité), `needsTime`=`bool(tech_spec["needs_time"])`. Transakčně: postav vše v paměti, ověř všech 5 kotev → jinak `IntegrationError` a nezapisuj nic.
- `pipeline/tests/` — `__init__.py`, `conftest.py` (fixture s fake Flutter stromem + 5 sentinely; `fake_llm` monkeypatch `ChatOpenAI.invoke`; deterministický hash-embedder místo SentenceTransformer), `fixtures/` (shadertoy_basic/with_ichannel/unportable `.glsl` + golden `.frag`), `test_shadertoy_adapter.py`, `test_integrator.py`, `test_graph_offline.py`.

### Modifikovat
- `pipeline/config.py` — `SEED_SHADERS_DIR = PIPELINE_DIR / "seed_shaders"`; `Settings.min_install_score: float = 7.0`; `Settings.auto_install: bool = True`.
- `pipeline/state.py` — přidat `port_reference: str`, `port_techniques: list[str]` do `ShaderGenState`.
- `pipeline/graph.py` — vložit `shadertoy_porter` mezi `rag_retriever` a `glsl_coder` (retry smyčka se nemění; `port_reference` přežívá v state napříč retry).
- `pipeline/agents/glsl_coder.py` — když `port_reference` neprázdné, přidat distinktní prompt blok ("portovatelná Flutter-contract reference, adaptuj věrně") vedle/místo generického `rag_block`. `FLUTTER_CONTRACT` zůstává.
- `pipeline/rag/ingest.py` — generalizovat `ingest_directory(dir, collection, *, glob="*.frag", convention="flutter")`, přidat metadata `convention`+`origin`; nová `ingest_seed_directory` (glob `*.glsl`, uloží originál `_st{idx}` i `port_shadertoy` výstup `_fl{idx}`); rozšířit `TECHNIQUE_TAGS` (plasma, voronoi, fbm, kaleidoscope, tunnel, raymarch, domain_warp, palette_cycle, truchet, metaballs, flow_field, hex_grid, mainimage→shadertoy_port); `main()` ingestuje navíc `SEED_SHADERS_DIR`, přidat `--seed-dir` a `--reset`.
- `pipeline/run.py` — argy `--no-install`, `--min-install-score`; seed nových state polí; po uložení výstupů gate (`rank_report.overall >= effective_min` a ne `--no-install`) → `integrator.install(...)`; zapsat `install_report.json`; nahradit hard-coded "Next step: copy…" výpis reportem/hintem; non-zero exit při `IntegrationError`.
- `pipeline/requirements.txt` — přidat `pytest`. `pipeline/.env.example` — dokumentovat nové klíče. `pipeline/.gitignore` — ignorovat `tests/.pytest_cache/`, ponechat `seed_shaders/` trackované.
- `mirrorbooth/lib/core/mirror_filter.dart` — **HOTOVO**: všech 5 sentinelů už v souboru je (`// >>> generated-filters-enum <<<` ř.28, `-label` ř.58, `-icon` ř.88, `-needstime` ř.99, `-shaderasset` ř.130). Žádná další ruční editace; jen ověřit, že je integrator kotví správně. `shader_provider.dart` se needituje (auto-load každého filtru s ne-null `shaderAsset` přes `shaderCacheProvider`).

## Pořadí prací (verifikace-first — scaffolding existuje)
1. **Audit existujícího kódu** proti tomuto spec: `shadertoy_adapter.py`, `shadertoy_porter.py`, `integrator.py`, `graph.py`, `glsl_coder.py`, `run.py`, `ingest.py`, `config.py`, `state.py`, seed korpus — zaznamenat odchylky od plánu.
2. `cd pipeline && pytest -q` → musí projít `test_shadertoy_adapter.py`, `test_integrator.py`, `test_graph_offline.py`. Selhání = mezera k dotažení v příslušném modulu.
3. Doplnit jen to, co audit/testy odhalí jako chybějící nebo nesprávné (nepřepisovat funkční kód).
4. Idempotence integratoru: dvojitý běh `integrator.install(...)` proti `tmp_path` fake stromu = zero diff; kolizní `enumName` → konzistentní suffix; chybějící sentinel → `IntegrationError` bez mutace.
5. Dart compile-gate na throwaway kopii: `cd mirrorbooth && flutter analyze && flutter test` (exhaustive-switch chyba je nejtvrdší kontrola 4 switchů).
6. Reálný e2e dry-run jen na této větvi → revert dotčených souborů.

## Verification (bez živého LLM — `spark_base_url` je LAN, zde nedostupné)

- **Adaptér**: `test_shadertoy_adapter.py` — port byte-equals golden; ported výstup projde `agents.validator._contract_check`; unportable fixture hlásí `unported_constructs` a porter dá `port_reference==""`.
- **Integrator**: `test_integrator.py` proti fake stromu — frag zkopírován, pubspec přidán jednou, všech 5 Dart míst vloženo, `enumName` správný; druhý běh = zero diff (idempotence); předseednutý `oilWarm` → `oilWarm2` konzistentně všude; chybějící sentinel → `IntegrationError`, žádná mutace.
- **Graf offline**: `test_graph_offline.py` — graf s `fake_llm`, `glsl_code` projde `_contract_check`; seednutý Shadertoy snippet v `rag_context` ověří port cestu; stub embedder → bez stahování modelu.
- **Dart compile guard**: na throwaway kopii `cd mirrorbooth && flutter analyze && flutter test` — Dartí exhaustive-switch chyba je nejsilnější kontrola 4 switchů.
- **Network caveat**: `sentence-transformers/all-MiniLM-L6-v2` se stahuje při prvním `rag/ingest.py`; když je HF blokované/necachované, RAG se nepostaví, ale `rag_retriever_node` vrací `[]` při výjimce a porter pasuje dál → end-to-end běží i offline (bez RAG inspirace). Testy stub embedder obcházejí.
- **Revert**: testy přes pytest `tmp_path`; reálný `mirrorbooth/` a `rag/db/` netknuté. Reálný e2e jen na git větvi → `git checkout -- mirrorbooth/pubspec.yaml mirrorbooth/lib/core/mirror_filter.dart` + smazat testovací `.frag`.

## Rizika
- **Dart fragilita** → sentinel kotvy + transakční all-or-nothing zápis + exhaustive-switch compile error jako tvrdý gate.
- **Kolize identifikátorů** → deterministický číselný suffix uniformně na enum/5 míst/filename, detekce parsováním existujících enum identifikátorů.
- **`.glsl` vs `.frag`** → oddělené ingest entrypointy; porter běží jen na Shadertoy zdrojích; app `.frag` se nikdy nere-portuje.
- **Licence** → 100 % originální CC0 korpus, explicitní LICENSE/NOTICE, per-file SPDX; třetí strana jen ověřené MIT/CC0 + záznam v NOTICE.
- **State purity** → integrator mimo LangGraph (post-graph v `run.py`), FS mutace neprovázané s retry.

## Kritické soubory
- `pipeline/agents/shadertoy_adapter.py` (nový — deterministické jádro portu)
- `pipeline/integrator.py` (nový — idempotentní Flutter auto-integrace)
- `mirrorbooth/lib/core/mirror_filter.dart` (jednorázové sentinely; 5 edit bodů)
- `pipeline/rag/ingest.py` (seed ingest, obě konvence, metadata)
- `pipeline/run.py` (flagy, score gate, volání integratoru)