# Video Recording Feature — MirrorBooth

## Context
Uživatel chce přidat nahrávání videa přes long-press na preview. Video musí mít aplikovaný aktivní GLSL filtr (stejný jako pro fotku). Po pustění prstu se video přehraje v aplikaci a uživatel si vybere zvukový efekt. Dalším tapem se video uloží do galerie.

Klíčový problém: `CameraController.startVideoRecording()` nahrává RAW video BEZ shaderového filtru — filtry jsou Flutter widget overlay (CustomPainter + FragmentShader). Proto musíme nahrávat frame-by-frame přes `RenderRepaintBoundary.toImage()` (stejný mechanismus jako existující screenshot).

---

## UX Flow

```
idle → [long press start] → recording (červená tečka + timer)
                                   │
                          [puštění prstu]
                                   │
                               assembling ("Processing…")
                                   │ FFmpeg hotovo
                               playback (video_player + audio strip)
                                   │ [tap Save]
                               idle (camera)
```

- **Tap** v idle = foto (existující chování)
- **Long press** = záznam videa (max 60 s)
- **Playback**: automatické loop přehrávání, audio strip níže
- **Výběr zvukového efektu**: rychlé FFmpeg re-encode
- **Audio-video sync**: pomalý/rychlý efekt změní i rychlost obrazu (setpts)

---

## Závislosti (`pubspec.yaml`)

```yaml
record: ^6.0.0                    # mic → AAC soubor (v5 nekompatibilní s record_platform_interface 1.5.0)
ffmpeg_kit_flutter_new: ^4.1.0   # video encode + audio filtry; sk3llo fork, iOS 14.0+
video_player: ^2.9.2             # přehrávání v aplikaci
```

**Poznámka**: `ffmpeg_kit_flutter_min_gpl` (původní arthenica balíček) je archivovaný, binárky na GitHubu vrací 404. Migrace na `ffmpeg_kit_flutter_new` by sk3llo — identické Dart API, vlastní xcframework (FFmpeg 8.0.0). Vyžaduje iOS 14.0+ (Podfile + project.pbxproj).

---

## Nové soubory

| Soubor | Odpovědnost |
|--------|-------------|
| `lib/core/jpeg_encode_utils.dart` | `EncodeJob` + `encodeToJpeg` — sdílí foto i záznam |
| `lib/features/video_recording/video_recording_state.dart` | `RecordingPhase` enum, `AudioEffect` enum, `VideoRecordingState` data class |
| `lib/features/video_recording/video_recording_notifier.dart` | `VideoRecordingNotifier` (Notifier) + provider — state machine, FFmpeg orchestrace |
| `lib/features/video_recording/frame_recorder.dart` | Ukládání framů na disk (JPEG do temp dir, měření FPS) |
| `lib/features/video_recording/audio_recorder_service.dart` | Wrapper nad `package:record` |
| `lib/features/video_recording/ffmpeg_service.dart` | Všechny FFmpeg příkazy jako statické metody |
| `lib/features/video_recording/recording_overlay.dart` | Pulsující červená tečka + timer |
| `lib/features/video_recording/audio_effect_strip.dart` | Horizontální strip výběru zvukového efektu |
| `lib/features/video_recording/video_playback_screen.dart` | Full-screen playback Scaffold s `VideoPlayer` |

## Modifikované soubory

| Soubor | Změna |
|--------|-------|
| `pubspec.yaml` | +3 závislosti |
| `ios/Podfile` | `platform :ios, '14.0'` |
| `ios/Runner.xcodeproj/project.pbxproj` | `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (3× výskyty) |
| `lib/features/mirror_preview/mirror_preview_screen.dart` | Long-press gesta, recording ticker, phase-based routing, skrytí UI během nahrávání |
| `lib/features/mirror_preview/mirror_preview_controller.dart` | `onForceStop` callback při app backgrounding |

**`filtered_mirror_canvas.dart` — beze změny.** Outer `RepaintBoundary` (`_canvasKey`) ve screenu zachytí shader output přesně stejně jako screenshot.

---

## State Machine

```dart
enum RecordingPhase { idle, recording, assembling, playback }

enum AudioEffect {
  none,
  chiptune,    // acrusher=level_in=8:level_out=8:bits=8:mode=log:aa=1
  slowMo,      // atempo=0.5 + setpts=2.0*PTS
  chipmunk,    // atempo=2.0 + setpts=0.5*PTS
  echo,        // aecho=0.8:0.9:500:0.5
  underwater,  // lowpass=f=400,aecho=0.8:0.9:200:0.5
  robot,       // aphaser=type=t:speed=2.0
  reverse,     // areverse
}
```

---

## Frame Capture — klíčový detail

`_MirrorPreviewScreenState` používá `TickerProviderStateMixin` (místo Single) pro druhý ticker nahrávání:

```dart
Future<void> _captureFrame() async {
  if (_isCapturingFrame) return;
  _isCapturingFrame = true;
  try {
    final boundary = _canvasKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _recordingPixelRatio);
    await ref.read(videoRecordingProvider.notifier).saveFrame(image);
  } catch (_) {
    // skip frame on error
  } finally {
    _isCapturingFrame = false;
  }
}
```

`_devicePixelRatio` uložit při `build()` do field (ne volat MediaQuery v async kontextu).

`_recordingPixelRatio = 1.5` (místo devicePixelRatio 3.0) → framy ~4× menší → ~20 fps místo 3 fps.

Měřený FPS z `FrameRecorder.measuredFps` se předá FFmpegu jako `-framerate`.

---

## FFmpeg příkazy

### Krok 1 — sestavení videa z framů + audio
```
ffmpeg -y
  -framerate <fps>
  -i <sessionDir>/frame_%06d.jpg
  -i <audioPath>.aac
  -vf scale=trunc(iw/2)*2:trunc(ih/2)*2   ← libx264 vyžaduje sudé rozměry
  -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p
  -c:a aac -b:a 128k
  -shortest
  raw.mp4
```

### Krok 2 — audio efekty

**Slow (0.5×)** — video + audio se zpomalí:
```
-filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" -map "[v]" -map "[a]"
```

**Chipmunk (2×)** — video + audio se zrychlí:
```
-filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]"
```

**Chiptune** — bit-crusher (8-bit zvuk), pouze audio:
```
-filter_complex "[0:a]acrusher=level_in=8:level_out=8:bits=8:mode=log:aa=1[a]" -map "0:v" -map "[a]"
```
> Poznámka: `vibrato=f=7:d=0.8` způsobuje NaN/Inf → AAC encoder selhává. `acrusher` je stabilní alternativa.

**Echo, Underwater, Robot, Reverse** — pouze audio filter, video beze změny:
```
-filter_complex "[0:a]<filter>[a]" -map "0:v" -map "[a]"
```

---

## UI Stack (camera view)

```
Stack
├── RepaintBoundary(_canvasKey) → FilteredMirrorCanvas  ← outer boundary pro capture
├── GestureDetector
│     onTap          → _captureAndSave() [jen idle]
│     onLongPressStart → notifier.startRecording() + start ticker
│     onLongPressEnd   → stop ticker + notifier.stopRecording()
├── if (!isRecording) → FilterStrip + controls + debug
├── if isRecording    → RecordingOverlay (pulsing red dot + timer)
└── flash overlay (beze změny)
```

Když `phase == assembling || playback` → render `VideoPlaybackScreen` místo camera stacku.

---

## Oprávnění

- **Mikrofon**: `Permission.microphone.request()` v `startRecording()` přes `permission_handler`
- iOS `NSMicrophoneUsageDescription` — doplnit do `Info.plist`
- Android `RECORD_AUDIO` — doplnit do `AndroidManifest.xml`

---

## Edge Cases & Memory Management

- Framy na disk okamžitě (compute() isolate), `ui.Image` se předává do notifieru — dispose voláno po encode
- Max 60 s nahrávání (auto-stop)
- Min 10 framů — jinak "Too short" + reset
- Při app background → `onForceStop` callback → `FFmpegKit.cancel()` + cleanup temp dir
- Discard bez uložení → confirmation dialog
- FFmpeg chyba → SnackBar + reset do idle

---

## Implementační pořadí

1. `pubspec.yaml` — přidat závislosti
2. `jpeg_encode_utils.dart` — extrahovat z `mirror_preview_screen.dart`
3. `frame_recorder.dart` + `audio_recorder_service.dart`
4. `ffmpeg_service.dart`
5. `video_recording_state.dart` + `video_recording_notifier.dart`
6. `recording_overlay.dart` + `audio_effect_strip.dart` + `video_playback_screen.dart`
7. Upravit `mirror_preview_screen.dart` (gesta, ticker, routing)
8. Upravit `mirror_preview_controller.dart` (lifecycle)
9. Ověřit oprávnění v `Info.plist` + `AndroidManifest.xml`
10. iOS deployment target: Podfile + project.pbxproj → 14.0

---

## Ověření

1. Long press → červená tečka + timer
2. Pustit → "Processing…" overlay → video se přehraje v loopu
3. Vybrat audio efekt → rychlé re-encode → přehrávání pokračuje s efektem
4. Tap Save → video v galerii obsahuje shader filtr + audio efekt
5. Tap zpět bez uložení → confirmation dialog
6. App background při nahrávání → čistý cleanup, žádný crash
