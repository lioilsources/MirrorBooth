# App Store listing assets

Localized screenshots and keywords for Mirror Booth (`com.ol1n.mirrorbooth`,
Apple ID 6767824892). Google Play materials live in `store/play/`.

## Screenshots

    python3 store/appstore/make_appstore_shots.py              # all locales
    python3 store/appstore/make_appstore_shots.py --locales pt-BR

Writes five scenes per locale to `store/appstore/screenshots/<locale>/`, as
iPhone 6.9" (1320×2868) and iPad 13" (2064×2752) RGB PNGs. The output is about
70 MB per locale, so it is git-ignored and rebuilt from `faces/`. Needs Pillow
and Flutter.

| # | Scene | Content |
|---|---|---|
| 1 | hero | original vs. left + left vs. right + right |
| 2 | live | full symmetric face, original as inset |
| 3 | filters | six filters, through the app's shaders |
| 4 | kaleido | mirror axis turned over a tilted head |
| 5 | video | recording with the voice-effect names |

Faces in `faces/` are fictional adults rendered by `generate_faces.py`. Never
replace them with a real person without a signed release. Headlines live in
`make_appstore_shots.py`; filter and voice-effect names come from the app's ARB
files. `en-GB`, `en-AU` and `en-CA` are copies of `en-US`.

## Upload

Screenshots need a new App Store version; the same build is enough if only
metadata changes. The folder matches the `fastlane deliver` layout:

    fastlane deliver --app_identifier com.ol1n.mirrorbooth --app_version 2.3.4 \
      --api_key_path <key.json> --screenshots_path store/appstore/screenshots \
      --skip_binary_upload --skip_metadata --overwrite_screenshots --force

## pt-BR keywords (100 characters max)

```
simetria,facial,espelho,teste,beleza,filtro,selfie,câmera,caleidoscópio,efeitos,fotos,vídeo,voz
```

Words already in the title (`Mirror Booth: rosto simétrico`) are left out,
because the App Store indexes them anyway and combines single words into
phrases such as "simetria facial" and "filtro espelho". Before pasting, remove
any word that also appears in the current pt-BR subtitle.
