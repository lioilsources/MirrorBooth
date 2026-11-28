# Anonymous usage statistics

MirrorBooth sends a small set of anonymous events through
[`ol1n_telemetry`](https://github.com/lioilsources/Ol1nTelemetry) so the
owner can see what new users do after the first launch, where they stop,
which filters and features advanced users use, and where saving, sharing or
buying goes wrong. This file is the **event dictionary**: the constant
`appDictionary` (`mirrorbooth/lib/telemetry/telemetry_dictionary.dart`) and
this document list exactly the same events and properties, and
`mirrorbooth/test/telemetry_test.dart` fails when they drift apart. The plan
behind it is `DevConventions/Prompts/04-PLAN-analytika.md`.

Adding an event or a property is a change to the privacy policy
(`docs/privacy.html`) and to the store privacy answers. Ask the owner first.

## Rules

The rules of `ol1n_telemetry` apply unchanged: no persistent identifier
(a random session id kept in memory only), cohorts computed on the device
(only bands leave it), only enums, bands and numbers, no key → no network,
the app never waits, an offline queue of at most 500 events, off wipes the
queue at once, and nothing in the app reads what was measured.

Camera and photos: **nothing about the content of a photo or a video ever
leaves the device.** No image, no frame, no face data, no file name, no
size or location. Events carry only which filter, collection or audio
effect was on, counts, durations and outcomes.

## Configuration

| `--dart-define` | Meaning |
|---|---|
| `TELEMETRY_KEY` | MirrorBooth's key at the collector. Empty → nothing is sent. |
| `TELEMETRY_HOST` | The collector, `https` only. Empty → nothing is sent. |
| `TELEMETRY_DEBUG` | `true` prints events to the console instead of sending them. |
| `MB_LAB` | TestFlight lab builds; they report `tester: true`. |

The release workflows (`release-ios`, `release-android`, `release-macos`,
`release-windows`, `release-linux`) pass both from the GitHub secrets of the
same names. An absent secret expands to an empty string and the build is
silent; the settings button that holds the switch is then hidden too. The
key and the collector address never go into this public repository.

## Transport and storage

Protocol v1 (`POST {TELEMETRY_HOST}/v1/batch`) to the owner's own collector
(StoreMetrics, in the EU), app id `mirrorbooth`. No third party receives
the events. The collector stores no IP address, only the country. Raw
events are kept 12 months. The queue and the few local counters live in
the app's existing `shared_preferences` under `telemetry_*` keys.

`days_band` is `pre` and `first_session` is false on a device that used
MirrorBooth before measuring (review-prompt counters or cached purchases
already present).

## Activation

The first photo saved to the gallery (`photo_save_end` with `result: ok`),
or a shared photo if that ever comes first. Once per install.

## Features

`col_pretty`, `col_ugly`, `col_art`, `col_fantasy`, `col_packs` (a filter
from that collection was picked; all packs count as one), `video` (a
recording started), `audio_effect` (an audio effect was applied to a
video), `rotate` (the composition was turned), `mirror_axis` (the mirror
axis was turned), `side_toggle`, `lens_toggle`, `volume_shutter` (a photo
or video started with a volume button).

## Campaign (Android)

The first `app_open` of a new Android install carries `campaign` when the
Play install-referrer capture of `ol1n_store_kit` has stored one under the
`ol1n_campaign` preference (`utm_campaign` of a QR or share link). The
capture makes no network call of its own; the campaign leaves the device
only inside this event, and only in the shape `^[a-z0-9-]{1,24}$`.

## Common properties

Sent with every event.

| Property | Type | Values |
|---|---|---|
| `app_version` | enum | the app version (`kAppVersion`, checked against `pubspec.yaml`) |
| `platform` | enum | `ios`, `android`, `macos`, `windows`, `linux`, `other` |
| `lang` | enum | `ar`, `cs`, `de`, `en`, `es`, `fr`, `hi`, `id`, `it`, `ja`, `ko`, `pt`, `tr` |
| `session_band` | enum | `1`, `2`, `3-5`, `6-10`, `11+` |
| `days_band` | enum | `0`, `1`, `2-6`, `7-29`, `30+`, `pre` |
| `first_session` | bool | yes/no |
| `tester` | bool | yes/no |
| `buyer` | bool | owns at least one paid collection (from the local purchase cache; always no on desktop) |

## Events

### `app_open`

Cold start, or a new session after more than 30 minutes in the background. Answers: what a new user does after the first launch (funnel start), whether they come back (`session_band_first`, `days_band_first`), and how many downloads turn into a first launch. `campaign` is the QR / share campaign of a new Android install, read from the Play install referrer.

| Property | Type | Values |
|---|---|---|
| `start` | enum | `cold`, `resume` |
| `session_band_first` | bool | yes/no |
| `days_band_first` | bool | yes/no |
| `campaign` | campaign | optional, `^[a-z0-9-]{1,24}$` |

### `screen_view`

A screen appeared. `camera` and `call` come from route names; `playback` (the recorded video) and `paywall` (the purchase sheet) report themselves. Answers: the first-session path, A → B → A bouncing.

| Property | Type | Values |
|---|---|---|
| `screen` | enum | `camera`, `call`, `playback`, `paywall`, `other` |
| `prev` | enum | `camera`, `call`, `playback`, `paywall`, `other`, `none` |

### `screen_leave`

A screen was left. Answers: how long people stay on which screen, and screens with a long stay and no action.

| Property | Type | Values |
|---|---|---|
| `screen` | enum | `camera`, `call`, `playback`, `paywall`, `other` |
| `secs` | int | 0–86400 |
| `actions` | int | 0–100000 |

### `session_pause`

The app went to the background or is closing. Sent at once. Answers: when and where people stop.

| Property | Type | Values |
|---|---|---|
| `active_secs` | int | 0–86400 |
| `screen` | enum | `camera`, `call`, `playback`, `paywall`, `other`, `none` |
| `screen_secs` | int | 0–86400 |

### `activation`

The first saved photo on this install (or the first shared one, should saving ever be skipped). Once per install. Answers: how long a new user takes to get the first result.

| Property | Type | Values |
|---|---|---|
| `secs` | int | 0–86400 |

### `feature_use`

The first use of a feature in a session. Answers: which features are used.

| Property | Type | Values |
|---|---|---|
| `feature` | enum | `col_pretty`, `col_ugly`, `col_art`, `col_fantasy`, `col_packs`, `video`, `audio_effect`, `rotate`, `mirror_axis`, `side_toggle`, `lens_toggle`, `volume_shutter` |

### `feature_snapshot`

After `app_open` of the 3rd, 6th and 11th session: which features this install has ever used. Answers: what advanced users never touch.

| Property | Type | Values |
|---|---|---|
| `f_col_pretty` | bool | yes/no |
| `f_col_ugly` | bool | yes/no |
| `f_col_art` | bool | yes/no |
| `f_col_fantasy` | bool | yes/no |
| `f_col_packs` | bool | yes/no |
| `f_video` | bool | yes/no |
| `f_audio_effect` | bool | yes/no |
| `f_rotate` | bool | yes/no |
| `f_mirror_axis` | bool | yes/no |
| `f_side_toggle` | bool | yes/no |
| `f_lens_toggle` | bool | yes/no |
| `f_volume_shutter` | bool | yes/no |
| `features_used` | int | 0–12 |

### `error_shown`

The user saw an error: camera, gallery, microphone, recording, sharing or purchase. Answers: where advanced users struggle.

| Property | Type | Values |
|---|---|---|
| `kind` | enum | `camera_denied`, `camera_missing`, `camera_failed`, `photo_failed`, `gallery_denied`, `gallery_space`, `gallery_format`, `mic_denied`, `video_short`, `video_failed`, `audio_effect`, `share_failed`, `purchase_failed` |
| `screen` | enum | `camera`, `call`, `playback`, `paywall`, `other`, `none` |

### `locked_tap`

Saving a photo or starting a video with a filter from a paid collection the user does not own; the paywall opens. Answers: which locked collections people want.

| Property | Type | Values |
|---|---|---|
| `target` | enum | `art`, `fantasy`, `mosaic`, `halftone`, `sketch`, `optics`, `kaleido`, `tiles`, `glitch`, `vhs`, `face`, `layers`, `paint`, `color`, `light` |

### `filter_select`

A filter was picked in the filter strip (a pack chip picks a random filter of the pack). `locked`: the collection is paid and not owned (trying is free, saving is gated). Answers: which filters and collections people use, and how much they browse locked ones.

| Property | Type | Values |
|---|---|---|
| `filter` | enum | the filter's `MirrorFilter` enum name (`lib/core/mirror_filter.dart`), e.g. `glow`, `popArt`, `r2MosaicC0025`; `none` without a filter |
| `collection` | enum | `pretty`, `ugly`, `art`, `fantasy`, `mosaic`, `halftone`, `sketch`, `optics`, `kaleido`, `tiles`, `glitch`, `vhs`, `face`, `layers`, `paint`, `color`, `light`, `experimental`, `none` |
| `locked` | bool | yes/no |

### `link_open`

A deep link opened the app (In-App Event, Custom Product Page, custom Play listing, shared post). `filter`: the link named a filter or collection this build knows. Answers: whether store campaigns bring people into the app.

| Property | Type | Values |
|---|---|---|
| `filter` | bool | yes/no |

### `photo_save_start`

The shutter was pressed and saving to the gallery began (after the paywall check).

| Property | Type | Values |
|---|---|---|
| `collection` | enum | `pretty`, `ugly`, `art`, `fantasy`, `mosaic`, `halftone`, `sketch`, `optics`, `kaleido`, `tiles`, `glitch`, `vhs`, `face`, `layers`, `paint`, `color`, `light`, `experimental`, `none` |

### `photo_save_end`

Saving ended. `denied`: no gallery access; `no_space`: the device is full. `fallback`: the full-resolution still failed and the screen was captured instead. Answers: how often the main action fails and how long it takes (a cheap load time).

| Property | Type | Values |
|---|---|---|
| `result` | enum | `ok`, `cancel`, `error`, `background`, `denied`, `no_space` |
| `secs` | int | 0–86400 |
| `fallback` | bool | yes/no |

### `video_record_start`

Recording began (after the paywall check).

| Property | Type | Values |
|---|---|---|
| `collection` | enum | `pretty`, `ugly`, `art`, `fantasy`, `mosaic`, `halftone`, `sketch`, `optics`, `kaleido`, `tiles`, `glitch`, `vhs`, `face`, `layers`, `paint`, `color`, `light`, `experimental`, `none` |

### `video_record_end`

Recording ended. `ok`: the video was assembled and playback opened; `short`: too few frames; `denied`: no microphone access; `background`: the app left the foreground mid-recording; `cancel`: a new recording replaced an unfinished one. Answers: whether recording works and how long videos are.

| Property | Type | Values |
|---|---|---|
| `result` | enum | `ok`, `cancel`, `error`, `background`, `denied`, `short` |
| `secs` | int | 0–86400 |

### `video_save_start`

Saving the recorded video began. `effect` is the chosen audio effect.

| Property | Type | Values |
|---|---|---|
| `effect` | enum | `none`, `chiptune`, `slowMo`, `chipmunk`, `echo`, `underwater`, `robot`, `reverse` |

### `video_save_end`

Saving the video ended; results as in `photo_save_end`. Answers: whether people keep their videos.

| Property | Type | Values |
|---|---|---|
| `result` | enum | `ok`, `cancel`, `error`, `background`, `denied`, `no_space` |
| `secs` | int | 0–86400 |

### `share_start`

The share sheet opened for a saved photo (snackbar action) or a recorded video.

| Property | Type | Values |
|---|---|---|
| `media` | enum | `photo`, `video` |

### `share_end`

The share sheet closed. `unknown`: the system did not say what happened (usual on Android). Answers: how often a result is shared, i.e. the growth loop.

| Property | Type | Values |
|---|---|---|
| `result` | enum | `ok`, `cancel`, `error`, `background`, `unknown` |
| `secs` | int | 0–86400 |

### `purchase_start`

A purchase began, from the paywall or from the App Store product page (promoted purchase). `item` is the collection or `bundle`.

| Property | Type | Values |
|---|---|---|
| `item` | enum | `art`, `fantasy`, `mosaic`, `halftone`, `sketch`, `optics`, `kaleido`, `tiles`, `glitch`, `vhs`, `face`, `layers`, `paint`, `color`, `light`, `bundle` |
| `source` | enum | `paywall`, `store_page` |

### `purchase_end`

The store answered for that product. Ask to Buy and other pending purchases stay open until they resolve. Answers: how many paywall visits end in a purchase, and where buying fails.

| Property | Type | Values |
|---|---|---|
| `result` | enum | `ok`, `cancel`, `error`, `background` |
| `secs` | int | 0–86400 |

## Reading the data

`store-metrics report mirrorbooth` (on the collector host). Exclude
`tester = true`. Useful cuts beyond the shared report:

1. **First-session funnel:** `app_open` → `filter_select` →
   `photo_save_start` → `activation` → second session.
2. **Paywall:** `locked_tap` by `target` → `screen_view` `paywall` →
   `purchase_start` → `purchase_end` by `result`, split by `source`.
3. **Failing saves:** `photo_save_end` and `video_save_end` by `result`
   and `platform`; `fallback = true` share; `error_shown` by `kind`.
4. **Growth loop:** `share_end` by `media` and `result` against
   `app_open` with a `campaign`, and `link_open`.
5. **Filters:** `filter_select` by `collection` and `filter`, split by
   `buyer` and `session_band`.

Filter names follow `MirrorFilter`. A release that adds shaders adds
values to `filter` (catalogue constants, no new property).

## Checking a build by hand

```bash
cd mirrorbooth
flutter run --dart-define=TELEMETRY_DEBUG=true
```

prints every event instead of sending it. With a test key: one full
session, then check that the collector holds exactly what this dictionary
lists and nothing more.
