import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../../core/mirror_side.dart';

/// Renders the mirror composition filling the full parent bounds.
///
/// The mirror axis passes through the canvas centre at [mirrorAxisDeg] degrees
/// from horizontal (default 90 = vertical seam). One half shows the camera
/// feed directly; the other half shows it reflected across that axis. The
/// camera image itself does not rotate when [mirrorAxisDeg] changes — only the
/// fold line moves.
///
/// [side] selects which angular half of the canvas shows the direct feed vs
/// the reflected copy.
class MirrorCanvas extends StatelessWidget {
  final CameraController controller;
  final MirrorSide side;
  final double mirrorAxisDeg;

  const MirrorCanvas({
    super.key,
    required this.controller,
    required this.side,
    this.mirrorAxisDeg = 90.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Cover-fit the camera over the full canvas.
      final portraitAspect = 1.0 / controller.value.aspectRatio;
      double camW, camH;
      if (w / h > portraitAspect) {
        camW = w;
        camH = w / portraitAspect;
      } else {
        camH = h;
        camW = h * portraitAspect;
      }

      final theta = mirrorAxisDeg * pi / 180.0;

      // Shared camera widget, centred over the full canvas.
      Widget cam = OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: SizedBox(
          width: camW,
          height: camH,
          child: CameraPreview(controller),
        ),
      );

      // Reflection of the camera across the axis through the canvas centre.
      // 2-D reflection matrix across a line at angle θ:
      //   [ cos2θ   sin2θ ]
      //   [ sin2θ  -cos2θ ]
      final cos2t = cos(2 * theta);
      final sin2t = sin(2 * theta);
      final reflectM = Matrix4.identity()
        ..setEntry(0, 0, cos2t)
        ..setEntry(0, 1, sin2t)
        ..setEntry(1, 0, sin2t)
        ..setEntry(1, 1, -cos2t);
      Widget camReflected = Transform(
        alignment: Alignment.center,
        transform: reflectM,
        child: cam,
      );

      // For side.isLeft the direct feed occupies the left half of the axis
      // (the half in the direction of the left-normal of the axis vector).
      final directOnLeft = side.isLeft;

      return Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _AxisClipper(theta: theta, clipLeft: directOnLeft),
            child: cam,
          ),
          ClipPath(
            clipper: _AxisClipper(theta: theta, clipLeft: !directOnLeft),
            child: camReflected,
          ),
        ],
      );
    });
  }
}

/// Clips to one half-plane divided by a line through the widget centre at
/// [theta] radians from horizontal. [clipLeft] = true keeps the left side
/// (relative to the axis direction vector).
class _AxisClipper extends CustomClipper<Path> {
  final double theta;
  final bool clipLeft;

  const _AxisClipper({required this.theta, required this.clipLeft});

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final axisDir = Offset(cos(theta), sin(theta));
    // Left-normal: 90° CCW from axisDir.
    final leftNormal = Offset(-sin(theta), cos(theta));
    final sign = clipLeft ? 1.0 : -1.0;
    final far = size.longestSide * 2;

    final p1 = center + axisDir * far;
    final p2 = center - axisDir * far;
    final p3 = p2 + leftNormal * sign * far;
    final p4 = p1 + leftNormal * sign * far;

    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
  }

  @override
  bool shouldReclip(_AxisClipper old) =>
      old.theta != theta || old.clipLeft != clipLeft;
}
