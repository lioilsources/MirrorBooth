import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'video_recording_state.dart';

class FFmpegService {
  /// Assembles JPEG frame sequence + audio AAC into a baseline MP4.
  /// Returns output path on success, null on failure.
  static Future<String?> assembleVideo({
    required String framesPattern,
    required String audioPath,
    required double fps,
    required String outputPath,
  }) async {
    final fpsStr = fps.round().clamp(1, 60).toString();
    // trunc(iw/2)*2 ensures width and height are even — required by libx264.
    const scaleFilter = 'scale=trunc(iw/2)*2:trunc(ih/2)*2';
    final args = [
      '-y',
      '-framerate', fpsStr,
      '-i', framesPattern,
      '-i', audioPath,
      '-vf', scaleFilter,
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '23',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-shortest',
      outputPath,
    ];
    return _run(args, outputPath);
  }

  /// Re-encodes [inputPath] with the given [effect] applied to audio (and
  /// optionally video speed). Returns output path on success, null on failure.
  static Future<String?> applyAudioEffect({
    required String inputPath,
    required AudioEffect effect,
    required String outputPath,
  }) async {
    if (effect == AudioEffect.none) {
      // Fast copy, no re-encode needed.
      final args = ['-y', '-i', inputPath, '-c', 'copy', outputPath];
      return _run(args, outputPath);
    }

    final filterSpec = _filterFor(effect);
    final args = [
      '-y',
      '-i', inputPath,
      ...filterSpec,
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-crf', '23',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
      outputPath,
    ];
    return _run(args, outputPath);
  }

  static List<String> _filterFor(AudioEffect effect) {
    switch (effect) {
      case AudioEffect.none:
        return ['-c', 'copy'];

      case AudioEffect.slowMo:
        // Both video and audio at 0.5×
        return [
          '-filter_complex',
          '[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]',
          '-map', '[v]',
          '-map', '[a]',
        ];

      case AudioEffect.chipmunk:
        // Both video and audio at 2×
        return [
          '-filter_complex',
          '[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]',
          '-map', '[v]',
          '-map', '[a]',
        ];

      case AudioEffect.chiptune:
        return [
          '-filter_complex', '[0:a]acrusher=level_in=8:level_out=8:bits=8:mode=log:aa=1[a]',
          '-map', '0:v',
          '-map', '[a]',
        ];

      case AudioEffect.echo:
        return [
          '-filter_complex', '[0:a]aecho=0.8:0.9:500:0.5[a]',
          '-map', '0:v',
          '-map', '[a]',
        ];

      case AudioEffect.underwater:
        return [
          '-filter_complex', '[0:a]lowpass=f=400,aecho=0.8:0.9:200:0.5[a]',
          '-map', '0:v',
          '-map', '[a]',
        ];

      case AudioEffect.robot:
        return [
          '-filter_complex', '[0:a]aphaser=type=t:speed=2.0[a]',
          '-map', '0:v',
          '-map', '[a]',
        ];

      case AudioEffect.reverse:
        return [
          '-filter_complex', '[0:a]areverse[a]',
          '-map', '0:v',
          '-map', '[a]',
        ];
    }
  }

  static Future<String?> _run(List<String> args, String outputPath) async {
    final session = await FFmpegKit.executeWithArguments(args);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return outputPath;
    final log = await session.getAllLogsAsString();
    debugPrintFFmpeg(log ?? '(no log)');
    return null;
  }

  static void debugPrintFFmpeg(String log) {
    // ignore: avoid_print
    print('[FFmpeg] $log');
  }
}
