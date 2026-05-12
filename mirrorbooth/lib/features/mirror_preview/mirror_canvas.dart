import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../../core/mirror_side.dart';

/// Renders the mirror composition filling the full parent bounds.
/// Two panels meet at a vertical seam — one is the camera feed, the other
/// is a horizontally flipped copy — producing a continuous mirror image.
///
/// Camera content uses BoxFit.cover per panel so there are no black bars.
/// Rotation is applied by the parent via Transform.rotate.
class MirrorCanvas extends StatelessWidget {
  final CameraController controller;
  final MirrorSide side;

  const MirrorCanvas({
    super.key,
    required this.controller,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final panelW = constraints.maxWidth / 2;
      final panelH = constraints.maxHeight;

      // Native sensor is landscape; CameraPreview shown in portrait → invert.
      final portraitAspect = 1.0 / controller.value.aspectRatio;

      // BoxFit.cover per panel: fill the panel without black bars.
      double camW, camH;
      if (panelW / panelH > portraitAspect) {
        camW = panelW;
        camH = panelW / portraitAspect;
      } else {
        camH = panelH;
        camW = panelH * portraitAspect;
      }

      final double denominator = max(camW - panelW, 1.0);
      final double alignX = side.isLeft
          ? -(panelW / denominator).clamp(-1.0, 1.0)
          : (panelW / denominator).clamp(-1.0, 1.0);
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

      return SizedBox(
        width: constraints.maxWidth,
        height: panelH,
        child: Row(children: [
          Expanded(child: panel(flip: !side.isLeft)),
          Expanded(child: panel(flip: side.isLeft)),
        ]),
      );
    });
  }
}
