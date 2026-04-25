import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../../core/mirror_side.dart';

/// Realtime face mirror using two CameraPreview widgets sharing the same
/// underlying GPU texture (textureId).
///
/// Each panel uses OverflowBox to position a full-size CameraPreview so that
/// the face center (camera midpoint) sits exactly at the seam between the two
/// panels. One panel is then flipped with Transform.flip to create the mirror.
/// Everything runs in Flutter's compositor — no pixel copies, no snapshots.
class MirrorCanvas extends StatelessWidget {
  final CameraController controller;
  final MirrorSide side;

  const MirrorCanvas({super.key, required this.controller, required this.side});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final panelW = constraints.maxWidth / 2;
      final panelH = constraints.maxHeight;

      // Portrait aspect ratio of the camera preview widget (width / height).
      // controller.value.aspectRatio is the landscape sensor ratio (w/h);
      // CameraPreview displays it in portrait so we invert it.
      final portraitAspect = 1.0 / controller.value.aspectRatio;

      // Scale the camera to cover the FULL SCREEN (both panels) using
      // BoxFit.cover semantics.
      final fullW = panelW * 2;
      double camW, camH;
      if (fullW / panelH > portraitAspect) {
        camW = fullW;
        camH = fullW / portraitAspect;
      } else {
        camH = panelH;
        camW = panelH * portraitAspect;
      }

      // OverflowBox alignment that places the camera so that:
      //   side=left  → camera x=(camW/2 − panelW)..(camW/2) visible in panel
      //                (face left side ending exactly at the seam)
      //   side=right → camera x=(camW/2)..(camW/2 + panelW) visible
      //                (face right side starting exactly at the seam)
      //
      // Formula: alignX = ±panelW / (camW − panelW)
      // Clamped to [-1, 1] so it degrades gracefully if camW ≤ 2·panelW.
      final double denominator = max(camW - panelW, 1.0);
      final double alignX = side.isLeft
          ? (panelW / denominator).clamp(-1.0, 1.0)
          : -(panelW / denominator).clamp(-1.0, 1.0);
      final alignment = Alignment(alignX, 0);

      Widget panel({required bool flip}) {
        Widget w = ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: alignment,
            child: SizedBox(
              width: camW,
              height: camH,
              child: CameraPreview(controller),
            ),
          ),
        );
        return flip ? Transform.flip(flipX: true, child: w) : w;
      }

      // Left panel is "original", right panel is mirrored when side=left.
      // Left panel is mirrored, right panel is "original" when side=right.
      return Row(children: [
        Expanded(child: panel(flip: !side.isLeft)),
        Expanded(child: panel(flip: side.isLeft)),
      ]);
    });
  }
}
