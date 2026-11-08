# Ruční sběr shaderů (bez API klíče)

Shadertoy App Key se v praxi novým žadatelům skoro nevydává a scraping webu je
mimo rozsah — shadertoy.com je za Cloudflare bot-ochranou a cokoli, co by se ji
snažilo obejít, je obcházení bezpečnostní kontroly, ne jen otázka ToS (viz
`Prompts/07-PLAN-shadertoy-pipeline.md`, rozhodnutí A). Žádný kód v `pipeline/`
tedy sám nevolá shadertoy.com. Místo toho si shadery sbíráš ty, jako člověk,
běžným prohlížením webu — a sem je uložíš.

## Dvě cesty

1. **Network panel (nejjednodušší).** Otevři shader na shadertoy.com, F12 →
   záložka *Network* → znovu načti stránku → najdi request, který vrací JSON
   shaderu (žádost, kterou si stránka pro sebe udělala sama) → *Copy response*
   → ulož jako `<id>.json` do tohoto adresáře. Přesně tenhle tvar vrací i
   oficiální API, takže se použije beze změny.
2. **Ruční přepis.** Zkopíruj `_TEMPLATE.json`, vyplň `id` (z URL za `/view/`),
   `author`, `code` (z editoru na stránce) a `description` (popis, nebo rovnou
   licenční text/`SPDX-License-Identifier: ...`). `channel0_ctype` vyplň jen
   pokud shader čte `iChannel0` (`webcam`/`video`/`texture`).

## Import

```bash
cd pipeline
python shadertoy/import_manual.py shadertoy_manual/
#   → ověří tvar, vypíše licenci/kategorii/portovatelnost a uloží do rag/shadertoy_cache/

python shadertoy/harvest.py --from-cache     # report přes vše, co je v cache
python run.py --from-shadertoy <id>          # port konkrétního shaderu, bez klíče
```

Soubory v tomto adresáři (kromě `_TEMPLATE.json` a tohoto README) se
nekomitují — stejné pravidlo jako u testovacích fotek: ruční sběr je lokální,
ne součást repa.
