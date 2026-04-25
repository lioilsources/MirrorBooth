# MirrorBooth — Architektura mobilní aplikace

## Context
Aplikace MirrorBooth zobrazuje symetrický obličej v reálném čase: vezme jednu polovinu obličeje ze selfie kamery, zrcadlí ji a zobrazí obě zrcadlové půlky vedle sebe (live preview). Addon FaceTimeMirrorBooth umožňuje video hovor dvou telefonů, kde každý účastník vidí sebe (i druhého) ve zrcadlové verzi. Repozitář je prázdný — začínáme od nuly.

---

## Framework: Flutter

Flutter vyhrává nad React Native i nativním dual-codebase přístupem díky:
- **Impeller GPU pipeline** — GLSL shadery se kompilují při buildu, žádný runtime jank
- `AnimatedSampler` + `FragmentProgram` — kamera texture → shader → display bez CPU
- `flutter_webrtc` — produkčně zralá WebRTC podpora
- Jeden codebase pro iOS + Android

---

## 1. Core Feature: GPU Mirror Preview

### Pipeline (zero CPU-copy)

```
Camera hardware
  → CameraPreview (External Texture / SurfaceTexture / CVPixelBuffer)
  → Texture widget (textureId)
  → AnimatedSampler (flutter_shaders)
  → FragmentShader: mirror.frag (Impeller, GLSL)
  → CustomPaint → display
```

### Fragment Shader (`shaders/mirror.frag`)

```glsl
#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform float uMirrorLeft;   // 1.0 = zrcadlí levou půlku, 0.0 = pravou
uniform vec2 uResolution;
out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float halfX;
    if (uMirrorLeft > 0.5) {
        halfX = uv.x < 0.5 ? uv.x : (1.0 - uv.x);
    } else {
        halfX = uv.x > 0.5 ? uv.x : (1.0 - uv.x);
    }
    fragColor = texture(uTexture, vec2(halfX, uv.y));
}
```

Výkon: < 0.5ms per frame na moderním GPU. Žádná práce na CPU.

---

## 2. FaceTimeMirrorBooth: Video hovor se zrcadlením

### Architektura

```
Phone A                                    Phone B
 MirrorVideoProcessor (native)              MirrorVideoProcessor (native)
        ↓                                          ↓
 RTCPeerConnection ←——— P2P media ————→ RTCPeerConnection
        ↕                                          ↕
        └——— WebSocket (SDP/ICE) ———————————————┘
                     Signaling Server
                     (Node.js + Socket.IO)
```

### Zrcadlení se aplikuje na SENDER straně (před encodingem)

- Android: `MirrorVideoProcessor.kt` — WebRTC `VideoProcessor`, flip přes `libyuv::I420Mirror()`
- iOS: `MirrorVideoProcessor.swift` — `vImageHorizontalReflect_ARGB8888` z `Accelerate.framework`
- Dart ↔ native komunikace: `MethodChannel('mirrorbooth/mirror')`

### Signaling Server (Node.js + Socket.IO)

Místnosti pro přesně 2 účastníky. Events:
```
join_room / peer_joined / offer / answer / ice / peer_left
```

STUN: `stun.l.google.com:19302`  
TURN: self-hosted Coturn (Docker) — bez TURN selže ~15-20% hovorů za NAT

---

## 3. Struktura projektu

```
mirrorbooth/
├── shaders/
│   └── mirror.frag                          ← GLSL shader (klíčový soubor)
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── mirror_side.dart                 ← enum MirrorSide { left, right }
│   │   └── constants.dart
│   ├── features/
│   │   ├── mirror_preview/
│   │   │   ├── mirror_preview_screen.dart
│   │   │   ├── mirror_preview_controller.dart  ← CameraController lifecycle
│   │   │   ├── mirror_canvas.dart           ← AnimatedSampler + FragmentShader
│   │   │   └── side_toggle_button.dart
│   │   └── video_call/
│   │       ├── call_screen.dart
│   │       ├── call_controller.dart
│   │       ├── signaling_service.dart       ← Socket.IO client
│   │       └── room_entry_screen.dart
│   └── services/
│       ├── mirror_channel.dart              ← MethodChannel wrapper
│       └── webrtc_service.dart
├── android/app/src/main/kotlin/.../
│   ├── MirrorPlugin.kt                      ← MethodChannel registrace
│   └── MirrorVideoProcessor.kt             ← WebRTC VideoProcessor (libyuv)
├── ios/Runner/
│   ├── MirrorPlugin.swift
│   └── MirrorVideoProcessor.swift          ← Accelerate.framework
└── signaling_server/
    ├── server.js                            ← Socket.IO signaling
    └── Dockerfile
```

---

## 4. Závislosti (pubspec.yaml)

```yaml
dependencies:
  camera: ^0.12.0                # front camera, External Texture path
  flutter_shaders: ^0.1.3        # AnimatedSampler
  flutter_webrtc: ^0.14.0        # RTCPeerConnection, getUserMedia
  socket_io_client: ^2.0.3+1     # signaling
  flutter_riverpod: ^2.5.1       # state management
  permission_handler: ^11.3.1    # kamera + mikrofon runtime permissions

flutter:
  shaders:
    - shaders/mirror.frag         # Impeller kompiluje při buildu
```

---

## 5. Implementační sekvence

**Fáze 1 — Mirror Preview (core):** ✅
1. `flutter create --platforms=ios,android mirrorbooth`
2. `mirror.frag` shader + zápis do pubspec `shaders:` sekce
3. `MirrorPreviewController` — `CameraController`, permise, lifecycle (WidgetsBindingObserver)
4. `MirrorCanvas` — `AnimatedSampler` + `FragmentProgram` + `CustomPaint`
5. `SideToggleButton` — přepíná `uMirrorLeft` uniform
6. Test na zařízení: ověřit < 100ms latenci a 60fps v DevTools

**Fáze 2 — Native VideoProcessor plugin:** ✅
7. `MirrorPlugin` (Kotlin + Swift) — MethodChannel registrace
8. `MirrorVideoProcessor.kt` — I420 horizontal flip přes libyuv
9. `MirrorVideoProcessor.swift` — CVPixelBuffer flip přes Accelerate
10. `MirrorChannel` Dart service — `setMirrorSide()`, `setEnabled()`

**Fáze 3 — Signaling server:** ✅
11. `server.js` — Express + Socket.IO, room management, SDP/ICE relay
12. Dockerfile + deploy konfigurace

**Fáze 4 — FaceTimeMirrorBooth:** ✅
13. `SignalingService` — Socket.IO client, room join/leave
14. `WebRtcService` — `RTCPeerConnection`, `getUserMedia`, attach `MirrorVideoProcessor`
15. `CallController` — offer/answer orchestrace
16. `CallScreen` — 2× `RTCVideoRenderer`, end/mute controls
17. `RoomEntryScreen` — zadání room ID

---

## 6. Klíčové gotchas

| Problém | Řešení |
|---|---|
| `AnimatedSampler` + External Texture může být černý na Androidu | Fallback: `startImageStream()` → YUV→RGBA konverze → `ui.Image` (CPU, ~2ms) — viz `MirrorCanvasCpuFallback` v `mirror_canvas.dart` |
| Impeller Vulkan nepodporuje external textures (issue #137639) | `camera ^0.12.0` + `camera_android_camerax ^0.7.2+` (Impeller-aware surface producer) |
| `flutter_webrtc` neexposes `VideoProcessor` v Dartu | Nutné native plugin (Kotlin/Swift) — viz `MirrorVideoProcessor.kt` / `.swift` |
| YUV420 flip chroma misalignment | Použít `libyuv::I420Mirror()` / `vImageHorizontalReflect` per plane, ne vlastní byte-swap |
| Symmetric NAT → ~20% hovorů selže bez TURN | Self-hosted Coturn na $5/měsíc VPS |
| `createPeerConnection` v Dartu koliduje s názvem metody třídy | Metoda třídy pojmenována `setupPeerConnection()` |

---

## 7. Před spuštěním na zařízení

1. Nastav signaling server URL v `lib/features/video_call/call_controller.dart`:
   ```dart
   const _signalingServerUrl = 'http://YOUR_SERVER:3000';
   ```

2. Spusť signaling server:
   ```bash
   cd mirrorbooth/signaling_server
   npm install && npm start
   ```

3. Pro produkci: nasaď Docker kontejner + Coturn TURN server.

---

## 8. Ověření funkčnosti

- **Mirror preview**: Live kamera, L/R toggle mění stranu okamžitě, DevTools GPU graph ≥ 60fps, frame time < 16ms
- **Latence**: Video pipeline profiler — od camera frame do display < 100ms
- **WebRTC call**: Dva fyzické telefony, oba vidí zrcadlený obličej, přepínání L/R mid-call bez zahltění
- **NAT traversal**: Test na mobilní síti (ne WiFi) — TURN zajistí spojení
