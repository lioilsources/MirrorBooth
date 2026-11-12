import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/face_anchor.dart';

/// One detection in normalized frame coordinates (0..1, origin top-left):
/// the face bounding box, as returned by Apple Vision on iOS and Google
/// ML Kit on Android.
@immutable
class FaceBox {
  final double left;
  final double top;
  final double width;
  final double height;

  const FaceBox(this.left, this.top, this.width, this.height);

  /// Converts the box to the shader's anchor: center in UV, scale as the face
  /// radius over the shorter frame side. Detector boxes stop at the brows and
  /// chin, so the radius is padded to cover forehead and hair like the
  /// hand-tuned default (0.35 for a face filling ~70% of the width).
  FaceAnchor toAnchor(double frameWidth, double frameHeight) {
    final shortSide = math.min(frameWidth, frameHeight);
    final radiusPx = 0.5 * math.max(width * frameWidth, height * frameHeight);
    final scale = (radiusPx / shortSide * FaceTracker.boxToRadius)
        .clamp(FaceTracker.minScale, FaceTracker.maxScale);
    return FaceAnchor(
      ui.Offset(left + width / 2, top + height / 2),
      scale.toDouble(),
    );
  }
}

/// Follows the face in the mirrored preview so face-anchored shaders
/// (`uFaceCenter`, `uFaceScale`) sit on the real face instead of the frame
/// center. Feed it the frames the filter canvas already captures; it samples
/// a few per second at low resolution, asks the platform detector, smooths
/// the result and falls back to [FaceAnchor.defaults] when no face is seen.
///
/// Platforms without the native channel (desktop, tests) stay on defaults.
class FaceTracker extends ValueNotifier<FaceAnchor> {
  FaceTracker({MethodChannel? channel, this.clock = _now})
      : _channel = channel ?? const MethodChannel(kMethodChannelFace),
        super(FaceAnchor.defaults);

  static const boxToRadius = 1.25;
  static const minScale = 0.12;
  static const maxScale = 0.6;

  /// Detection input width; Vision and ML Kit find faces fine at this size.
  static const sampleWidth = 192;
  static const interval = Duration(milliseconds: 150);

  /// How long the last face is held before easing back to the default.
  static const holdFor = Duration(milliseconds: 1200);

  /// Smoothing toward each new detection (0 = frozen, 1 = no smoothing).
  static const follow = 0.45;

  final MethodChannel _channel;
  final Duration Function() clock;
  bool _busy = false;
  bool _unsupported = false;
  Duration? _lastSample;
  Duration? _lastSeen;

  static final _watch = Stopwatch()..start();
  static Duration _now() => _watch.elapsed;

  bool get isSupported => !_unsupported;

  /// Offers a captured frame. Cheap when skipped; never blocks the caller.
  /// The caller keeps ownership of [frame].
  void offer(ui.Image frame) {
    if (_unsupported || _busy) return;
    final now = clock();
    if (_lastSample != null && now - _lastSample! < interval) return;
    _lastSample = now;
    _busy = true;
    unawaited(_detect(frame).whenComplete(() => _busy = false));
  }

  Future<void> _detect(ui.Image frame) async {
    final w = sampleWidth;
    final h = math.max(1, (frame.height * w / frame.width).round());
    final ByteData? rgba;
    try {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        frame,
        ui.Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.low,
      );
      final small = await recorder.endRecording().toImage(w, h);
      rgba = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
      small.dispose();
    } catch (e) {
      debugPrint('face sample: $e');
      return;
    }
    if (rgba == null) return;

    final Object? result;
    try {
      result = await _channel.invokeMethod<Object?>('detect', {
        'width': w,
        'height': h,
        'rgba': rgba.buffer.asUint8List(),
      });
    } on MissingPluginException {
      _unsupported = true;
      return;
    } on PlatformException catch (e) {
      debugPrint('face detect: ${e.message}');
      return;
    }
    update(parse(result), frame.width.toDouble(), frame.height.toDouble());
  }

  /// Parses the channel reply: a list of `[left, top, width, height]`
  /// (normalized), largest face first, or empty.
  static FaceBox? parse(Object? reply) {
    if (reply is! List || reply.isEmpty) return null;
    final first = reply.first;
    if (first is! List || first.length < 4) return null;
    final v = [for (final x in first.take(4)) (x as num).toDouble()];
    if (v[2] <= 0 || v[3] <= 0) return null;
    return FaceBox(v[0], v[1], v[2], v[3]);
  }

  /// Applies one detection result (null: no face in this sample).
  @visibleForTesting
  void update(FaceBox? box, double frameWidth, double frameHeight) {
    final now = clock();
    final FaceAnchor target;
    final double k;
    if (box != null) {
      _lastSeen = now;
      target = box.toAnchor(frameWidth, frameHeight);
      k = follow;
    } else if (_lastSeen != null && now - _lastSeen! < holdFor) {
      return;
    } else {
      target = FaceAnchor.defaults;
      k = follow / 3;
    }
    if ((target.center - value.center).distance < 0.002 &&
        (target.scale - value.scale).abs() < 0.002) {
      return;
    }
    final next = FaceAnchor(
      ui.Offset.lerp(value.center, target.center, k)!,
      ui.lerpDouble(value.scale, target.scale, k)!,
    );
    value = next;
  }

  /// Back to the default anchor, e.g. after switching cameras.
  void reset() {
    _lastSeen = null;
    value = FaceAnchor.defaults;
  }
}
