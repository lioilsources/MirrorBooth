# 10 — Handoff pro MacBook: App Preview do storů a promo Shorts

Pro session na MacBooku (Xcode, simulátory, ffmpeg). Videa se na M2 nedělají: MacBook je na LAN
a na nahrávání ze simulátoru a střih je lepší stroj (DevConventions `shared/stacks/flutter.md`).

## Co vznikne

| Výstup | Formát | Kam |
|---|---|---|
| **App Preview iOS**, 1–3 klipy | 886×1920 na výšku, 15–30 s, H.264, 30 fps, AAC stereo stopa (smí být tichá), ≤ 500 MB | `store/videos/appstore/` |
| **Play promo video**, 1 klip | 1080×1920 nebo 1920×1080, 30 s – 2 min, H.264 | `store/videos/play/` (na YouTube ho nahraje Olin) |
| **Shorts**, aspoň 3 | 1080×1920 na výšku, 15–30 s, H.264 + AAC, hook v první sekundě | `store/videos/shorts/` + promo assets `mirrorbooth/shorts/` |
| **Web**, 1 klip | libovolné mp4 na výšku | `ol1n.now/apps/mirrorbooth/screenshots/raw/mobile/ios/` (`make screenshots` ho přepočítá) |

Pojmenování: `<YYYY-MM-DD>-<téma>.mp4`, např. `2026-11-22-new-shaders.mp4`.

## Co natočit

- **Filtry naživo** (Shorts + App Preview 1): rychlé přepínání shaderů. Simulátor nemá kameru: použij testovací vstup appky (obrázek/video místo kamery), pokud ho appka má; jinak natoč na fyzickém iPhonu přes QuickTime (Soubor → Nový záznam filmu → iPhone) a export stejně.
- **Kolekce a paywall** (App Preview 2): procházení kolekcí, „All filters“ se slevou.
- **Nový balík shaderů** (Short): po merge nového obsahu jen nové shadery, každý 1–2 s.
- **Fotka a sdílení** (Short): snímek, uložení, sdílecí list.

App Preview smí ukazovat jen to, co je v appce a ve verzi, ke které se přiloží: žádné ruce,
rámečky zařízení ani ceny v textu. Shorts můžou mít titulky a CTA na konci („Free on the App Store“).

## Postup

1. `git pull` na `main`. **Nový obsah:** nová ikona a balík nových shaderů. Pokud ještě není na `main`, natoč teď jen Shorts
   a App Preview odlož, až bude: preview se přikládá k verzi, která s tím obsahem vyjde.
2. Simulátor **iPhone 6.9"** (iPhone 16 Pro Max), angličtina, status bar vyčistit:
   `xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100 --cellularBars 4`.
   Build `--profile` nebo `--release`, ne debug (žádný debug banner, plynulé fps).
3. Nahrávej `xcrun simctl io booted recordVideo --codec=h264 raw/<jméno>.mov` (Ctrl-C ukončí).
   Syrové nahrávky drž mimo repo (složka Movies na MacBooku), necommituj je.
4. Střih a export přes ffmpeg, např. App Preview:
   `ffmpeg -i raw.mov -ss 2 -t 25 -vf "scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2,fps=30" -c:v libx264 -pix_fmt yuv420p -c:a aac -ac 2 -shortest out.mp4`
   (bez zvuku přidej `-f lavfi -i anullsrc=r=44100:cl=stereo` jako druhý vstup).
   Ověř `ffprobe`: rozměr, délka, fps.
5. Hotová videa: do repa commitni jen ta pod 20 MB (soubory jmenovitě, žádné `git add -A`).
   Větší nech mimo repo a napiš jejich cestu ve zprávě.
6. Shorts nahraj do promo assets na JODĚ (`<promo assets>/mirrorbooth/shorts/`, cesta je v
   `PromoClown/docs/RUNBOOK.md`). Když `ssh joda` z MacBooku nejde, napiš to ve zprávě a M2 je
   tam zkopíruje.
   Mirror Booth zatím není v `PromoClown/projects.yaml`: nahraj Shorts do `mirrorbooth/shorts/`
   a ve zprávě to připomeň, projekt doplní Olin.
7. Pošli zprávu session na **M2** (Pass / 10), co vzniklo a kde. Session **Store** pošli cesty
   App Preview klipů.

## Hotovo, když

Klipy splňují formáty z tabulky, jsou v repu nebo mimo repo s cestou ve zprávě a M2 i Store mají cesty.

Nic neodesílej k review, nenahrávej do App Store Connect ani na Play a nic nepublikuj
(YouTube, TikTok, Instagram). Publikace jde jen přes schválení v promo botovi.
