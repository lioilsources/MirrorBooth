# MirrorBooth — CLAUDE.md

## Overview

Flutter WebRTC app for real-time symmetric face mirroring with shader effects. Uses selfie camera, applies mirror filters and GLSL shaders, supports video calls and recording. Flutter app lives in `mirrorbooth/` subdirectory.

## Commands

```bash
cd mirrorbooth
flutter pub get
flutter run -d ios
flutter run -d android
flutter build ios
flutter build apk
flutter analyze
```

## Structure

```
mirrorbooth/
  lib/
    main.dart
    core/
      constants.dart
      jpeg_encode_utils.dart
      mirror_filter.dart       # Mirror/flip filter logic
      mirror_side.dart         # Left/right mirroring enum
      shader_provider.dart     # GLSL shader loading
    features/
      mirror_preview/          # Live camera preview with mirror effect
      video_call/              # WebRTC video call feature
      video_recording/         # Local recording
    services/
      mirror_channel.dart      # Platform channel for native mirror
      webrtc_service.dart      # WebRTC session management
  shaders/                     # GLSL fragment shaders
  signaling_server/            # WebRTC signaling backend (Go or similar)

pipeline/                      # Asset pipeline (separate from Flutter app)
```

## Key Features

- Real-time GLSL shader pipeline on camera feed
- Mirror effect (left/right flip) applied via shader or platform channel
- WebRTC peer-to-peer video calls (requires signaling server)
- Video recording to device storage
- JPEG encode utils for frame capture

## Signaling Server

WebRTC requires a signaling server for peer connection setup. Located in `mirrorbooth/signaling_server/`. Must be running for video calls.
