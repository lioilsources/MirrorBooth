import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/jpeg_encode_utils.dart';

class FrameRecorder {
  final String sessionDir;
  int _frameIndex = 0;
  final DateTime _startTime = DateTime.now();

  FrameRecorder._(this.sessionDir);

  static Future<FrameRecorder> create() async {
    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dir = '${tmp.path}/mirrorbooth_rec_$ts';
    await Directory(dir).create(recursive: true);
    return FrameRecorder._(dir);
  }

  /// Save a filtered frame to disk. Disposes [image] after reading.
  Future<void> saveFrame(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return;

    final idx = _frameIndex++;
    final path = '$sessionDir/frame_${idx.toString().padLeft(6, '0')}.jpg';
    final jpegBytes = await compute(
      encodeToJpeg,
      EncodeJob(
        rgbaBytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      ),
    );
    await File(path).writeAsBytes(jpegBytes, flush: false);
  }

  int get frameCount => _frameIndex;

  /// Measured fps based on elapsed wall time.
  double get measuredFps {
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds / 1000.0;
    if (elapsed <= 0 || _frameIndex == 0) return 20.0;
    return (_frameIndex / elapsed).clamp(1.0, 60.0);
  }

  /// FFmpeg-style input pattern, e.g. /tmp/.../frame_%06d.jpg
  String get framesPattern => '$sessionDir/frame_%06d.jpg';

  Future<void> deleteAll() async {
    try {
      await Directory(sessionDir).delete(recursive: true);
    } catch (_) {}
  }
}
