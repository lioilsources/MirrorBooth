import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/jpeg_encode_utils.dart';
import '../core/store_links.dart';
import '../features/video_recording/ffmpeg_service.dart';

/// Shares a finished photo or video with the app name burned in and a store
/// link in the message, so a post leads back to the app. Only the shared copy
/// is marked: files saved to the gallery stay clean.
class ShareService {
  static const brand = 'Mirror Booth';

  /// The Linux share path only opens a mailto: link, which can't carry a file.
  static bool get isSupported => !kIsWeb && !Platform.isLinux;

  /// Store link sent with a shared post, tagged so the install is counted
  /// as coming from sharing.
  static String get storeUrl => (Platform.isAndroid
          ? StoreLinks.play()
          : StoreLinks.appStore())
      .toString();

  /// Paints the brand, with the short web address in small type under it,
  /// into a transparent [width]×[height] layer, bottom-right. Sized from the
  /// image width so it reads the same at any resolution.
  static ui.Image watermarkLayer(int width, int height) {
    final fontSize = width * 0.042;
    final margin = width * 0.03;
    final shadows = [
      Shadow(color: const Color(0x99000000), blurRadius: fontSize / 4),
    ];
    final text = TextPainter(
      text: TextSpan(
        text: brand,
        style: TextStyle(
          color: const Color(0xE6FFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: shadows,
        ),
        children: [
          TextSpan(
            text: '\n${StoreLinks.shortUrl}',
            style: TextStyle(
              color: const Color(0xCCFFFFFF),
              fontSize: fontSize * 0.55,
              fontWeight: FontWeight.w500,
              shadows: shadows,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final recorder = ui.PictureRecorder();
    text.paint(
      ui.Canvas(recorder),
      ui.Offset(width - text.width - margin, height - text.height - margin),
    );
    text.dispose();
    final picture = recorder.endRecording();
    final layer = picture.toImageSync(width, height);
    picture.dispose();
    return layer;
  }

  /// Returns a temp copy of the JPEG at [path] carrying the watermark.
  static Future<File> _stampPhoto(String path) async {
    final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
    final photo = (await codec.getNextFrame()).image;
    codec.dispose();
    final width = photo.width;
    final height = photo.height;
    final layer = watermarkLayer(width, height);

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawImage(photo, ui.Offset.zero, ui.Paint())
      ..drawImage(layer, ui.Offset.zero, ui.Paint());
    final picture = recorder.endRecording();
    final stamped = await picture.toImage(width, height);
    picture.dispose();
    photo.dispose();
    layer.dispose();

    final rgba = await stamped.toByteData(format: ui.ImageByteFormat.rawRgba);
    stamped.dispose();
    final jpeg = await compute(
      encodeToJpeg,
      EncodeJob(
          rgbaBytes: rgba!.buffer.asUint8List(), width: width, height: height),
    );
    return File(await _tempPath('jpg')).writeAsBytes(jpeg);
  }

  /// Returns a temp copy of the video at [path] carrying the watermark, or
  /// null if FFmpeg failed.
  static Future<File?> _stampVideo(String path, ui.Size size) async {
    final layer = watermarkLayer(size.width.round(), size.height.round());
    final bytes = await layer.toByteData(format: ui.ImageByteFormat.png);
    layer.dispose();
    final overlay = await File(await _tempPath('png'))
        .writeAsBytes(bytes!.buffer.asUint8List());
    try {
      final output = await FFmpegService.overlayImage(
        inputPath: path,
        overlayPath: overlay.path,
        outputPath: await _tempPath('mp4'),
      );
      return output == null ? null : File(output);
    } finally {
      overlay.delete().ignore();
    }
  }

  static Future<String> _tempPath(String extension) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${dir.path}/mb_share_$ts.$extension';
  }

  /// The share sheet's outcome; Android usually reports `unavailable`.
  static Future<ShareResultStatus> sharePhoto(
    String path, {
    required String message,
    ui.Rect? origin,
  }) async {
    final stamped = await _stampPhoto(path);
    return _share(stamped, message, origin);
  }

  /// [size] is the video's pixel size. Falls back to the unmarked file if
  /// burning in the watermark fails: sharing matters more than the mark.
  static Future<ShareResultStatus> shareVideo(
    String path, {
    required ui.Size size,
    required String message,
    ui.Rect? origin,
  }) async {
    final stamped = await _stampVideo(path, size);
    return _share(stamped ?? File(path), message, origin,
        deleteAfter: stamped != null);
  }

  static Future<ShareResultStatus> _share(
    File file,
    String message,
    ui.Rect? origin, {
    bool deleteAfter = true,
  }) async {
    try {
      final result = await SharePlus.instance.share(ShareParams(
        text: message,
        files: [XFile(file.path)],
        sharePositionOrigin: origin,
      ));
      return result.status;
    } finally {
      if (deleteAfter) file.delete().ignore();
    }
  }
}
