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
///
/// [cameraRotationDeg] (0/90/180/270) wraps the inner CameraPreview in a
/// RotatedBox, used when the phone is held landscape — the camera content gets
/// rotated to upright **inside** the panel, so the mirror seam stays vertical.
class MirrorCanvas extends StatelessWidget {
  final CameraController controller;
  final MirrorSide side;
  final int cameraRotationDeg;

  const MirrorCanvas({
    super.key,
    required this.controller,
    required this.side,
    this.cameraRotationDeg = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final panelW = constraints.maxWidth / 2;
      final panelH = constraints.maxHeight;

      // Aspect ratio of the (possibly rotated) camera preview as it will be
      // displayed (width / height). Without rotation: native camera is
      // landscape, CameraPreview displays it portrait → invert. With ±90°
      // rotation: post-rotation aspect equals the native landscape aspect.
      final isQuarter = cameraRotationDeg == 90 || cameraRotationDeg == 270;
      final portraitAspect = isQuarter
          ? controller.value.aspectRatio
          : 1.0 / controller.value.aspectRatio;

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

      final double denominator = max(camW - panelW, 1.0);
      final double alignX = side.isLeft
          ? -(panelW / denominator).clamp(-1.0, 1.0)
          : (panelW / denominator).clamp(-1.0, 1.0);
      final alignment = Alignment(alignX, 0);

      Widget cameraView() {
        Widget cam = CameraPreview(controller);
        if (cameraRotationDeg != 0) {
          cam = RotatedBox(
            quarterTurns: (cameraRotationDeg ~/ 90) % 4,
            child: cam,
          );
        }
        return cam;
      }

      Widget panel({required bool flip}) {
        Widget w = ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: alignment,
            child: SizedBox(
              width: camW,
              height: camH,
              child: cameraView(),
            ),
          ),
        );
        return flip ? Transform.flip(flipX: true, child: w) : w;
      }

      return Row(children: [
        Expanded(child: panel(flip: !side.isLeft)),
        Expanded(child: panel(flip: side.isLeft)),
      ]);
    });
  }
}
