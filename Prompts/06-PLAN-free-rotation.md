# 06 — Free rotation: full-screen mirror without circular crop

## Goal

Remove the circular viewport and fill the entire display with the mirror
composition. The user can rotate the image freely; at any rotation angle
(including ±90°) the camera feed must cover the full screen — no black areas.

## Changes

### Android package rename
`com.mirrorbooth.mirrorbooth` → `com.ol1n.mirrorbooth` to match the
`applicationId` / `namespace` declared in `build.gradle.kts`.

Affected files (moved + package declaration updated):
- `MainActivity.kt`
- `MirrorPlugin.kt`
- `MirrorVideoProcessor.kt`

### Remove circular crop (`mirror_preview_screen.dart`)
- Removed `ClipOval` wrapping the camera canvas.
- Canvas changed from `Positioned` with `diameter × diameter` to `Positioned.fill`.
- Camera canvas is now oversized to the **screen diagonal**
  (`sqrt(W² + H²)`), wrapped in `OverflowBox`, so that rotating by any
  angle keeps the full screen covered.
- Outer `RepaintBoundary` (keyed, used for photo capture) stays at screen
  size → saved photos capture only the visible area; saving behaviour unchanged.

### Full-screen mirror composition (`mirror_canvas.dart`)
- Removed square constraint (`min(width, height)`).
- Canvas now fills whatever bounds it receives via `LayoutBuilder`.
- Each half-panel is `(parentWidth / 2) × parentHeight`.
- BoxFit.cover calculation updated per panel (was per square).

### Rotation ring overlay
- Added `_RotationRing` widget: a `CustomPaint` circle (88 % of shortest
  screen side) drawn as a semi-transparent overlay above the camera canvas.
- Tick marks every 30° rotate with the current rotation angle, giving
  visual feedback while dragging.
- `IgnorePointer` so the ring does not intercept gestures.

### Gesture fix
- `GestureDetector` (pan → rotate) moved above the camera canvas in the
  `Stack` so that `CameraPreview`'s `Texture` widget no longer absorbs all
  pointer events before the detector can see them.
