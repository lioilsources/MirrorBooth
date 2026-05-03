import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_recorder_service.dart';
import 'ffmpeg_service.dart';
import 'frame_recorder.dart';
import 'video_recording_state.dart';

class VideoRecordingNotifier extends Notifier<VideoRecordingState> {
  static const _maxDuration = Duration(seconds: 60);
  static const _minFrames = 10;

  final _audio = AudioRecorderService();
  FrameRecorder? _frameRecorder;
  Timer? _elapsedTimer;
  bool _stopping = false;

  @override
  VideoRecordingState build() => const VideoRecordingState();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by the screen when long press begins.
  Future<void> startRecording() async {
    if (state.phase != RecordingPhase.idle) return;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      state = state.copyWith(
        errorMessage: 'Microphone permission required for video recording.',
      );
      return;
    }

    _stopping = false;
    _frameRecorder = await FrameRecorder.create();
    final audioPath = '${_frameRecorder!.sessionDir}/audio.aac';
    await _audio.start(audioPath);

    state = state.copyWith(
      phase: RecordingPhase.recording,
      elapsed: Duration.zero,
      rawVideoPath: null,
      finalVideoPath: null,
      selectedEffect: AudioEffect.none,
      isSaved: false,
      errorMessage: null,
    );

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != RecordingPhase.recording) return;
      final next = state.elapsed + const Duration(seconds: 1);
      state = state.copyWith(elapsed: next);
      if (next >= _maxDuration) stopRecording();
    });
  }

  /// Called from the screen's recording ticker to persist a captured frame.
  Future<void> saveFrame(ui.Image image) async {
    await _frameRecorder?.saveFrame(image);
  }

  /// Called by the screen when long press ends.
  Future<void> stopRecording() async {
    if (state.phase != RecordingPhase.recording || _stopping) return;
    _stopping = true;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final audioPath = await _audio.stop();
    final recorder = _frameRecorder;
    _frameRecorder = null;

    if (recorder == null || recorder.frameCount < _minFrames) {
      await recorder?.deleteAll();
      state = const VideoRecordingState(
        errorMessage: 'Recording too short — hold longer.',
      );
      return;
    }

    state = state.copyWith(phase: RecordingPhase.assembling);

    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rawPath = '${tmp.path}/mb_raw_$ts.mp4';

    final result = await FFmpegService.assembleVideo(
      framesPattern: recorder.framesPattern,
      audioPath: audioPath ?? '${recorder.sessionDir}/audio.aac',
      fps: recorder.measuredFps,
      outputPath: rawPath,
    );

    await recorder.deleteAll();

    if (result == null) {
      state = const VideoRecordingState(
        errorMessage: 'Video assembly failed. Please try again.',
      );
      return;
    }

    state = state.copyWith(
      phase: RecordingPhase.playback,
      rawVideoPath: rawPath,
      finalVideoPath: null,
    );
  }

  /// Called when user selects an audio effect chip.
  Future<void> applyAudioEffect(AudioEffect effect) async {
    final raw = state.rawVideoPath;
    if (raw == null || state.phase != RecordingPhase.playback) return;
    if (state.selectedEffect == effect) return;

    state = state.copyWith(
      selectedEffect: effect,
      isApplyingEffect: true,
      errorMessage: null,
    );

    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tmp.path}/mb_effect_${effect.name}_$ts.mp4';

    final result = await FFmpegService.applyAudioEffect(
      inputPath: raw,
      effect: effect,
      outputPath: outPath,
    );

    final oldFinal = state.finalVideoPath;
    if (oldFinal != null && oldFinal != raw) {
      File(oldFinal).delete().ignore();
    }

    if (result == null) {
      state = state.copyWith(
        isApplyingEffect: false,
        errorMessage: 'Audio effect failed.',
      );
      return;
    }

    state = state.copyWith(
      finalVideoPath: result,
      isApplyingEffect: false,
    );
  }

  /// Save current video to gallery.
  Future<void> saveVideo() async {
    final path = state.playbackPath;
    if (path == null) return;
    try {
      await Gal.putVideo(path);
      state = state.copyWith(isSaved: true);
    } on GalException catch (e) {
      state = state.copyWith(errorMessage: '${e.type.code}: ${e.type.message}');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Discard recording and return to camera, cleaning up all temp files.
  Future<void> discardAndReturnToCamera() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    unawaited(_audio.stop());
    await _frameRecorder?.deleteAll();
    _frameRecorder = null;

    final raw = state.rawVideoPath;
    final final_ = state.finalVideoPath;
    if (raw != null) unawaited(File(raw).delete());
    if (final_ != null && final_ != raw) unawaited(File(final_).delete());

    state = const VideoRecordingState();
  }

  /// Hard reset on app lifecycle events (e.g. app goes to background).
  Future<void> forceStop() async {
    if (state.phase == RecordingPhase.idle) return;
    await discardAndReturnToCamera();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}


final videoRecordingProvider =
    NotifierProvider<VideoRecordingNotifier, VideoRecordingState>(
  VideoRecordingNotifier.new,
);
