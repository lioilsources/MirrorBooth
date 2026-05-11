import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../../core/mirror_side.dart';

/// Renders the mirror composition as a SQUARE bounded by the parent's shortest
/// side. The composition is the same as before — two panels meeting at a
/// vertical seam, one flipped — but laid out edge-to-edge in a square so the
/// inscribed circle around the seam captures the full mirrored frame.
///
/// Camera content is scaled with BoxFit.cover within the square: the natural
/// portrait camera display (typically 9:16) is widened to fill the square, and
/// the extra horizontal extent is filled by the existing mirror-overflow logic
/// (so the result inside the inscribed circle is a continuous mirror).
///
/// Rotation is no longer applied here — the parent wraps this widget in a
/// Transform.rotate so the entire composition (seam included) rotates as one.
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
      final dim = min(constraints.maxWidth, constraints.maxHeight);
      final panelW = dim / 2;
      final panelH = dim;

      // Native sensor is landscape; CameraPreview shown in portrait → invert.
      final portraitAspect = 1.0 / controller.value.aspectRatio;

      // BoxFit.cover semantics within the square.
      final fullW = dim;
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
        width: dim,
        height: dim,
        child: Row(children: [
          Expanded(child: panel(flip: !side.isLeft)),
          Expanded(child: panel(flip: side.isLeft)),
        ]),
      );
    });
  }
}
