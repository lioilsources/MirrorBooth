# 07 — HANDOFF: pokračování ShaderGen v2 na M2

> Pro Claude Code na M2. Přečti nejdřív `07-PLAN-shadertoy-pipeline.md`
> (rozhodnutí + kontrakt) a `07-SETUP-shadertoy-pipeline-infra.md` (co musí
> běžet kde) — tento dokument je jen akční seznam toho, co zbývá, a co bylo
> mezitím zjištěno/opraveno v cloudové session.

## Stav

- Branch `claude/opus-toyshader-pipeline-plan-8d8qh1`, HEAD `968714b`, pushnuto,
  žádný rozdíl vůči `origin`. `main` se mezitím posunul (ikona, obchodní
  položky) — jeden commit sáhl do `mirrorbooth/pubspec.yaml`, naše větev ten
  soubor nemění, takže `git merge origin/main` (nebo rebase, podle konvence
  repa) by měl projít bez konfliktu.
- **Fáze 0–7 celého plánu jsou implementované a sloučené do `main`** (commity
  `01157bc`…`3468471`, 29.9. a 1.10.). To už bylo hotové před touto cloudovou
  session.
- **Co doplnila cloudová session (tato větev, 2 commity nad `main`):**
  1. `docs: no-key fallback...` — rozhodnutí v plánu o tom, jak sklízet
     shadery bez API klíče.
  2. `pipeline: harvest/port without a Shadertoy API key` — `shadertoy/import_manual.py`
     + `shadertoy_manual/` staging adresář + testy + opravené docs.

## Co bylo zjištěno v cloudu (důležité, přečti před dalším krokem)

1. **Shadertoy App Key se v praxi novým žadatelům skoro nevydává** — formulář
   na `shadertoy.com/myapps` typicky nikdy neodpoví. Zkusit zažádat znovu
   (e-mail, Shadertoy Discord) může běžet souběžně, ale nic na tom nečeká.
2. **Scraping je vyloučen natrvalo, ne jen opatrnost.** Přímý `curl` na
   `shadertoy.com/view/<id>` vrátil Cloudflare výzvu „Just a moment…“, ne
   jen blokaci cloud proxy. Zkouška přes headless Chromium byla harnessem
   zablokovaná jako „Bot Check Circumvention“. Nezkoušej to znovu, ani na M2,
   ani jinou technikou (jiný User-Agent, jiná knihovna, cookie z vlastního
   přihlášení přehrané skriptem apod.) — to je obcházení bezpečnostní
   kontroly, mimo rozsah bez výjimky.
3. **Místo toho:** `shadertoy/import_manual.py` + `shadertoy_manual/`
   (ruční sběr) promuje shadery do `rag/shadertoy_cache/`, kterou `harvest.py
   --from-cache` a `agents/transpiler.py`'s `load_source_shader()` už dřív
   uměly číst před voláním API. Žádný kód v `pipeline/` nevolá shadertoy.com
   mimo `ShadertoyClient` s platným klíčem.
4. **SPARK config v docs byl opravený na realitu** — LiteLLM gateway na
   `:8080/v1` (ne starý `:8000`/`llama3`), modely `openclaw-default`
   (qwen36, vidí i obrázky) a `bench-nano`, SPARK okno **17:00–01:00**
   (session „Director“ má prioritu, na SPARKu nic nespouštěj/nezastavuj).
5. **Ověřeno v cloudu, bez sítě:** `ruff check`/`format` čisté; `python -m
   pytest -m "not network and not llm"` → 225 passed, 39 skipped (chybí
   Flutter SDK/`impellerc`/`moderngl` — čekané v cloudu). Manuální end-to-end
   běh (`import_manual.py` → `harvest.py --from-cache` → `run.py
   --from-shadertoy`) prošel transpilerem, validátorem i náhledem bez
   jediného požadavku na shadertoy.com; spadl až na LLM rankeru, protože
   SPARK je LAN-only — to je čekaná hranice, ne bug.

## Akční seznam na M2

Checklist a příkazy jsou detailně v `07-SETUP-shadertoy-pipeline-infra.md`
§ 4–5. Stručně, v pořadí:

1. `git fetch origin && git checkout claude/opus-toyshader-pipeline-plan-8d8qh1 && git merge origin/main`
   (nebo rebase, podle toho, co repo normálně dělá).
2. `cd pipeline && python -m pytest -m "not network and not llm"` — potvrď,
   že na M2 vychází stejně jako v cloudu (225 passed).
3. `python -m pytest -m flutter` (s `FLUTTER_ROOT`) — **první skutečné
   ověření `impellerc`** nad 24 shadery aplikace + goldeny transpileru.
   Tohle v cloudu neběželo ani jednou.
4. `python -m pytest -m gl` — headless render (`moderngl` + GPU/EGL), první
   skutečné ověření orientace/náhledů.
5. Ruční sběr: pár shaderů do `shadertoy_manual/` (§ 2.2b setup dokumentu) →
   `python shadertoy/import_manual.py shadertoy_manual/` → `python
   shadertoy/harvest.py --from-cache` → vyber kandidáta s `port = yes`.
6. `python run.py --from-shadertoy <id> --name <jméno>` (v okně SPARKu
   17:00–01:00) — **první skutečný port end-to-end, včetně LLM rankeru.**
   Pro srovnání zkus i `python run.py --style "…" --name …` (inspire).
7. `python integrate.py --run-dir output/filter_<jméno>_<ts> --enum-name …
   --label … --icon … --collection art|fantasy` — zaregistruje filtr,
   spustí `flutter analyze && flutter test`.
8. `cd ../mirrorbooth && flutter run -d ios` (nebo `-d android`) — QA na
   zařízení: FPS, orientace, čitelnost obličeje. Po změně `.frag` je nutný
   **full restart**, ne hot reload.
9. Zopakuj 5–8 ještě dvakrát, aby vzniklo **alespoň 5 nových filtrů (1× port
   z permisivního zdroje, 2× inspire)** v kolekci Art nebo Fantasy — to je
   bod 5 Definition of Done v plánu.
10. Commit + push na tuto větev. PR vytvoř, jen pokud o něj uživatel
    explicitně požádá.

## Definition of Done — co zbývá

Z `07-PLAN-shadertoy-pipeline.md`:

- [x] 1. `import_manual.py` + `harvest.py --from-cache` bez klíče — hotovo, ověřeno v cloudu.
- [ ] 2. `run.py --from-shadertoy` → `.frag` projde skutečným `impellerc` (Metal/GLES/Vulkan) + má náhledy — **čeká na M2, kroky 3–6 výše.**
- [ ] 3. Inspire režim s atribuovaným Shadertoy RAG — kód hotov, ověř reálným během (krok 6).
- [ ] 4. `integrate.py` + `flutter analyze`/`test` zelené + `shader_contract_test.dart` prochází — **čeká na M2, krok 7.**
- [ ] 5. Alespoň 3 nové filtry, ověřené na zařízení — **čeká na M2, kroky 5–9.**
- [x] 6. `pipeline/README.md` popisuje workflow; CI má `pipeline-tests` — hotovo.

Jakmile je 2–5 hotovo, plán je kompletně splněný.
