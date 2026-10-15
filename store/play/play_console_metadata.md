# Google Play Console — MirrorBooth listing

Everything Play asks for, with its own limits. Every bracketed number is a
character count written by `python3 store/play/check_lengths.py --fix` and
verified by the same script without `--fix` — not eyeballed.

| | |
|---|---|
| Package name | **`com.ab.mirrorbooth`** (`android/app/build.gradle.kts` `applicationId`) |
| Play account | A+B organization account — no closed-testing requirement, straight to **Production** |
| Kotlin namespace | `com.ol1n.mirrorbooth` (unchanged, invisible to Play) |
| In-app product IDs | `com.ol1n.mirrorbooth.collection.art`, `…collection.fantasy` (unchanged — product IDs are per app, any string works) |
| versionName | `2.3.1` (pubspec) — next tag should be `v2.3.2` |

Three Play differences worth knowing before starting:

- **No keywords field.** Play indexes the app name, short and full description,
  so the search terms (symmetric, face, mirror, filters, selfie) are in the prose.
- **A feature graphic is mandatory** — `store/play/graphics/feature-1024x500.png`.
- **Screenshots are capped at 2:1.** The raw iPhone captures are 2.165:1, so the
  Play sets are framed to 9:16 on a dark wash rather than cropped.

## 0. Create the app (new package = new app)

Play package names are permanent and cannot be renamed or reused. The old
`com.ol1n.mirrorbooth` draft cannot become `com.ab.mirrorbooth`, so the listing
is created again in the A+B organization account:

1. Play Console (A+B account) → **All apps** → **Create app**.
2. App name `MirrorBooth: Symmetric Face`, default language **English (United
   States) – en-US**, **App**, **Free**, tick the two declarations → **Create app**.
   (Free is correct even with in-app purchases — paid means a price to install.)
3. The package name is *not* typed anywhere: it is fixed by the **first AAB
   uploaded**. That AAB must be built from commit `7fde082` or later — the
   v2.3.1 release AAB on GitHub is still `com.ol1n.mirrorbooth` and will be
   accepted only as the wrong app. See §10.
4. Optional: delete or leave the old `com.ol1n.mirrorbooth` draft in the
   personal account. A draft that was never published costs nothing, but delete
   it to avoid uploading there by mistake.

## 1. Store listing

| Field | Limit | Value |
|---|---|---|
| App name | 30 | `MirrorBooth: Symmetric Face` [27] |
| Short description | 80 | see below |
| Full description | 4000 | see below |
| App category | — | **Photography** |
| Tags (up to 5) | — | Photography, Selfie camera, Photo filters, Video editor, Entertainment — pick whichever of these Play offers |
| Contact email | — | `oldrich.vorechovsky.jr@gmail.com` |
| Website | — | `https://lioilsources.github.io/MirrorBooth/` |
| Privacy policy | — | `https://lioilsources.github.io/MirrorBooth/privacy.html` |

The name carries "Symmetric Face" because Play has no keyword field and
"MirrorBooth" alone says nothing to a search. The same name works in Czech;
Play allows a translated name per language but it is not needed.

### Short description (80)

English [73]:

```
See your perfectly symmetric face, live. 24 filters, photos and voice FX.
```

Czech [73]:

```
Uvidíte svou dokonale souměrnou tvář živě. 24 filtrů, fotky a video s FX.
```

### Full description (4000)

English [1579]:

```
MirrorBooth turns your selfie camera into a live, perfectly symmetric mirror.

Pick the left or the right half of your face and MirrorBooth mirrors it across the middle in real time, so you see what a perfectly symmetrical you would look like. Surprising, often hilarious, always a little uncanny.

PLAY WITH THE MIRROR
• Switch between the left and the right half with one tap
• Drag to rotate the picture and the mirror axis for kaleidoscope faces
• Use the front or the back camera to mirror friends, pets or anything else
• Take photos with the on-screen shutter or the volume button

24 LIVE FILTERS IN FOUR COLLECTIONS
Every filter runs live on the camera feed, right on your phone.
• Pretty (free): Glow, Slim, Doll, Chibi, Lips
• Ugly (free): Nose, Alien, Melt, Ears, Neck
• Art: Pencil, Comic, Glitch, Neon, Heat, Oil, CRT, Pop
• Fantasy: Vampire, Zombie, Ghost, Demon, Cyborg, Frost

Every filter can be previewed for free. Art and Fantasy are one-time purchases that unlock saving photos and videos with those filters. No subscription.

VIDEO WITH VOICE EFFECTS
Record clips of up to 60 seconds with sound, then give your voice a twist: 8-bit, Slow, Chipmunk, Echo, Underwater, Robot or Reverse. Save the result to your gallery and share it anywhere.

PRIVATE BY DESIGN
All image processing happens on your phone. No account, no ads, no analytics, no tracking. Photos and videos are saved to your gallery only when you choose to save them, and MirrorBooth never uploads them.

Camera access is required. The microphone is used only while you record a video with sound.
```

Czech [1551]:

```
MirrorBooth promění selfie kameru v živé, dokonale souměrné zrcadlo.

Vyberte levou nebo pravou polovinu obličeje a MirrorBooth ji v reálném čase zrcadlí přes střed, takže uvidíte, jak byste vypadali s dokonale souměrnou tváří. Překvapivé, často k smíchu, vždycky trochu podivné.

HRAJTE SI SE ZRCADLEM
• Jedním klepnutím přepnete levou a pravou polovinu
• Tažením otočíte obraz i osu zrcadla a vzniknou kaleidoskopické tváře
• Přední i zadní kamera – zrcadlete kamarády, mazlíčky nebo cokoli jiného
• Fotky pořídíte spouští na obrazovce nebo tlačítkem hlasitosti

24 ŽIVÝCH FILTRŮ VE ČTYŘECH KOLEKCÍCH
Každý filtr běží živě přímo v telefonu.
• Pretty (zdarma): Glow, Slim, Doll, Chibi, Lips
• Ugly (zdarma): Nose, Alien, Melt, Ears, Neck
• Art: Pencil, Comic, Glitch, Neon, Heat, Oil, CRT, Pop
• Fantasy: Vampire, Zombie, Ghost, Demon, Cyborg, Frost

Náhled každého filtru je zdarma. Kolekce Art a Fantasy jsou jednorázové nákupy, které odemknou ukládání fotek a videí s těmito filtry. Žádné předplatné.

VIDEO S HLASOVÝMI EFEKTY
Natočte klip až na 60 sekund se zvukem a pak hlasu přidejte efekt: 8-bit, Slow, Chipmunk, Echo, Underwater, Robot nebo Reverse. Výsledek uložíte do galerie a můžete ho sdílet kamkoli.

SOUKROMÍ NA PRVNÍM MÍSTĚ
Veškeré zpracování obrazu probíhá v telefonu. Žádný účet, žádné reklamy, žádná analytika, žádné sledování. Fotky a videa se ukládají do galerie jen tehdy, když je uložit chcete, a MirrorBooth je nikdy nikam neodesílá.

Aplikace potřebuje přístup ke kameře. Mikrofon se používá jen při natáčení videa se zvukem.
```

Filter and voice-effect names are left in English in the Czech text on purpose:
the app UI shows them in English (`MirrorFilter.label`, `AudioEffect.label`).

To add Czech: **Grow users → Store presence → Store listings → Manage
translations → Add your own translations → Czech – cs-CZ**, paste the two Czech
blocks; the name, graphics and screenshots fall back to English.

## 2. In-app products

**Monetize with Play → Products → In-app products → Create product**
(only possible after an AAB containing the Play Billing library has been uploaded
to any track; `in_app_purchase` pulls it in). Also requires a payments profile
on the A+B account.

| Product ID | Name (55) | Description (200) | Type |
|---|---|---|---|
| `com.ol1n.mirrorbooth.collection.art` | `Art filters` [11] | `Unlock saving photos and videos with Pencil, Comic, Glitch, Neon, Heat, Oil, CRT and Pop.` [89] | One-time, non-consumable |
| `com.ol1n.mirrorbooth.collection.fantasy` | `Fantasy filters` [15] | `Unlock saving photos and videos with Vampire, Zombie, Ghost, Demon, Cyborg and Frost.` [85] | One-time, non-consumable |

The IDs must match `FilterCollection.productId` in
`mirrorbooth/lib/core/mirror_filter.dart` exactly — a mismatch does not fail
loudly, the paywall just shows "Loading price…" forever. Price is your choice;
**Activate** each product after saving.

## 3. Graphics

| Asset | Requirement | File |
|---|---|---|
| App icon | 512×512 PNG, no alpha | `store/play/graphics/icon-512.png` |
| Feature graphic | 1024×500 PNG/JPEG | `store/play/graphics/feature-1024x500.png` |
| Phone screenshots | 2–8, max 2:1 | `store/play/screenshots/phone/` — 4 × 1080×1920 |
| 7" / 10" tablet screenshots | optional | `store/play/screenshots/tablet/` — 4 × 1920×1200 (use for both) |

Regenerate with `python3 store/play/make_play_assets.py` (needs Pillow; ffmpeg
for shot 01, which is a frame from the echo-effect demo clip). Sources: the
iPhone captures in `ol1n.now/apps/mirrorbooth/screenshots/raw/mobile/ios/` and
`mirrorbooth/assets/icon/icon.png`.

The captures are full-screen filter output with no app UI on them. That is
allowed, but a later pass with real Android captures that show the filter strip
and shutter would sell the app better.

## 4. App content (Policy → App content)

### Privacy policy

`https://lioilsources.github.io/MirrorBooth/privacy.html` — served by GitHub
Pages from `main:/docs`. This branch updates it (adds a **Purchases** section
and the WebRTC IP-address note, date → October 15, 2026); it goes live only
once the branch is merged to `main`.

### App access

**All functionality is available without any access restrictions.** No login,
no account. Instructions field (optional):

```
No account needed. Grant camera permission on first launch. Tap the filter strip at the bottom to switch filters; Art and Fantasy filters preview for free and ask for a purchase only when saving.
```

If the video-call button stays in the build (see Blockers), add:
`The video-call button (top right) is an experimental feature and is not functional in this release.`
— better to hide the button instead.

### Ads

**No**, the app does not contain ads.

### Content rating (IARC questionnaire)

Category: **All other app types** (it is not a game, social network or
reference app; Photography/entertainment utility).

| Question | Answer |
|---|---|
| Violence, blood, gore | No — Vampire/Zombie/Demon are colour grades of the user's own face, no blood or gore |
| Fear / horror content | No |
| Sexuality, nudity | No |
| Profanity / crude humour | No |
| Controlled substances | No |
| Gambling, simulated gambling | No |
| Users can interact or exchange content | **No** if the call button is hidden (recommended). If it ships as-is the honest answer is **Yes** (in-app video call between two users by room code) |
| Shares user's physical location | No |
| Allows purchase of digital goods | **Yes** (two one-time in-app purchases) |
| Unrestricted internet access / web browser | No |
| Collects or shares personal info | No |

Expected result: PEGI 3 / ESRB Everyone / IARC 3+, with the interactive
element "In-App Purchases" (plus "Users Interact" if the call ships).

### Target audience and content

Age groups: **13–15, 16–17, 18+**. Do **not** include under-13 groups: that
opts the app into the Families policy (teacher-approved requirements, stricter
review of camera/microphone use and of the paid filters). Answer **No** to "Could
the store listing unintentionally appeal to children?" — the listing shows
adult faces and horror-ish filters, no cartoon characters.

### Data safety

Declare **no data collected and no data shared** → the questionnaire ends after
the first page.

Why that is true for this build (checked against the code, not the old docs):

- Permissions: `CAMERA`, `RECORD_AUDIO`, `INTERNET` only
  (`android/app/src/main/AndroidManifest.xml`). No location, contacts, storage.
- Camera frames and audio are processed on-device (Flutter shaders, FFmpegKit);
  photos/videos go to the device gallery via `gal`, never uploaded.
- No analytics, crash reporting, ads or Firebase SDK in `pubspec.yaml`. The
  `google-services.json` file is a leftover: the `com.google.gms.google-services`
  Gradle plugin is not applied, so it is not compiled in.
- Purchases go through Google Play Billing; the app stores only "which
  collections are owned" in SharedPreferences. Google processes payment data,
  not us.
- Video call: the signaling URL is hard-coded to `http://localhost:3000`
  (`lib/features/video_call/call_controller.dart`), so the shipped build never
  reaches a developer server. Even a working call is WebRTC peer-to-peer with
  DTLS-SRTP (end-to-end encrypted, not readable by us), which Play's guidance
  exempts from "collected". If a real signaling server is ever deployed,
  revisit this section.

### Other declarations

| Declaration | Answer |
|---|---|
| Government app | No |
| News app | No |
| Financial features | My app doesn't provide any financial features |
| Health | No health features |
| COVID-19 contact tracing | No |
| Advertising ID | **No** — no ad or analytics SDK uses it (Android 13+ requires this answer for targetSdk 33+) |
| Foreground service / exact alarm / photo & video permissions | Not applicable — the manifest declares none of them |

## 5. Store settings

**Grow users → Store presence → Store settings**: App category Photography,
contact email as above, website as above. External marketing: leave on.

## 6. Countries and pricing

**Monetize with Play → App pricing**: Free. **Test and release → Production →
Countries/regions → Add countries/regions**: all (or start with Czechia + the
markets you care about).

## 7. Release straight to Production

The A+B organization account has **no** "12 testers for 14 days" closed-test
requirement, so no closed testing and no tester invites. Order:

1. Finish every item on **Dashboard → Set up your app** (sections 1–6 above).
2. **Test and release → Setup → App signing**: accept **Play App Signing**
   (default). Google generates the app signing key; your keystore becomes the
   *upload* key.
3. **Test and release → Production → Create new release**.
4. Upload the AAB (§10). The first upload fixes the package name to
   `com.ab.mirrorbooth` and registers the upload key.
5. Release name: `2.3.2` (auto-filled from versionName). Release notes:

   ```
   <en-US>
   First release on Google Play: live symmetric face mirror, 24 filters, photos and videos with voice effects.
   </en-US>
   <cs-CZ>
   První vydání na Google Play: živé souměrné zrcadlo obličeje, 24 filtrů, fotky a videa s hlasovými efekty.
   </cs-CZ>
   ```
6. **Next** → fix any errors (warnings are fine) → **Save** → **Publishing
   overview → Send changes for review**. A first review on a new account
   typically takes a few days, not hours — "submit today" means it is in review
   today.
7. Optional **managed publishing** (Publishing overview) if you want to pick the
   moment it goes live after approval.

In-app products (§2) can be created only after step 4 — the Console needs to
see the billing permission in an uploaded bundle. Create and activate them
before sending for review, or the paywall shows "Store unavailable" to the
reviewer.

## 8. Signing

| | |
|---|---|
| Local | `mirrorbooth/android/key.properties` (git-ignored) → `/Users/ol1n/Dev/Distribution/Android/MirrorBooth/upload-keystore.jks`, alias `upload` |
| CI | `release-android.yml` writes `key.properties` from secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` |
| Fallback | if `key.properties` is missing, release builds are signed with the **debug** key — Play rejects that AAB |

Because this is a new app with Play App Signing, whichever key signs the first
AAB becomes the upload key. Make sure local and CI use the same keystore
(compare `keytool -list -v -keystore upload-keystore.jks -alias upload` SHA-256
with the certificate Play shows after upload), otherwise later CI builds will be
rejected with "signed with the wrong key". A lost upload key can be reset via
Play support, but it takes days.

## 9. versionCode

`pubspec.yaml` is `version: 2.3.1` with no `+build`, so:

| Build | versionName | versionCode |
|---|---|---|
| local `flutter build appbundle` | 2.3.1 | **1** |
| CI tag build | from pubspec | `github.run_number` (last run: **31** for v2.3.1, next will be ≥ 32) |

For a brand-new app any versionCode is accepted. The trap is mixing sources
later: if the first upload is a CI build with code 32, a later local build with
code 1 is refused. Pick one source (CI recommended) and stay with it, or pass
`--build-number` explicitly locally.

## 10. Getting the AAB

The v2.3.1 GitHub Release AAB predates the applicationId change — it is
`com.ol1n.mirrorbooth` and **must not** be uploaded to the new app. Either:

- **CI (recommended):** bump `pubspec.yaml` to `2.3.2`, merge, `git tag v2.3.2 &&
  git push origin v2.3.2`. The AAB lands on the GitHub Release as
  `app-release.aab`. Expect the last step (**Firebase App Distribution**) to fail:
  `FIREBASE_ANDROID_APP_ID` points at the Firebase app registered for
  `com.ol1n.mirrorbooth`, and the APK is now `com.ab.mirrorbooth`. The GitHub
  Release upload runs before it, so the AAB is still there; register a new
  Android app in Firebase (or drop that step) to make the run green.
- **Local:** `cd mirrorbooth && flutter build appbundle --release --build-number=32`
  → `build/app/outputs/bundle/release/app-release.aab`. Check the package first:
  `unzip -p …/app-release.aab base/manifest/AndroidManifest.xml | strings | grep mirrorbooth`
  should show `com.ab.mirrorbooth`.

## Blockers and open decisions

1. **Video-call button is broken in release builds.** `_CallButton` is always
   shown on the camera screen (`mirror_preview_screen.dart` ~line 561) and opens
   `RoomEntryScreen`, but the signaling server URL is `http://localhost:3000`, so
   joining can never connect on a phone. Play's "broken functionality" policy is
   a common first-review rejection, and leaving it in also forces "Users
   interact: Yes" in IARC. Recommended before building the AAB: hide the button
   on mobile (e.g. wrap it in `if (kDebugMode)`) and keep the `/call` route.
2. **No AAB with the new package exists yet** — cut `v2.3.2` (or build locally,
   §10). The v2.3.1 AAB is `com.ol1n.mirrorbooth`.
3. **Privacy policy update is on this branch only** — merge to `main` so
   GitHub Pages publishes it before sending for review.
4. **Upload key consistency** local vs CI secrets (§8).
5. Payments profile on the A+B account before the in-app products can be
   created (§2).
6. Cosmetic: the launcher label is lowercase `mirrorbooth`
   (`AndroidManifest.xml` `android:label`); consider `MirrorBooth`.
