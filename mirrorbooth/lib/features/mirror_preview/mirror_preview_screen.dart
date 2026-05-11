import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/jpeg_encode_utils.dart';
import '../../core/shader_provider.dart';
import '../video_recording/recording_overlay.dart';
import '../video_recording/video_playback_screen.dart';
import '../video_recording/video_recording_notifier.dart';
import '../video_recording/video_recording_state.dart';
import 'camera_lens_toggle_button.dart';
import 'filter_strip.dart';
import 'filtered_mirror_canvas.dart';
import 'mirror_preview_controller.dart';
import 'side_toggle_button.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class MirrorPreviewScreen extends ConsumerStatefulWidget {
  const MirrorPreviewScreen({super.key});

  @override
  ConsumerState<MirrorPreviewScreen> createState() => _MirrorPreviewScreenState();
}

class _MirrorPreviewScreenState extends ConsumerState<MirrorPreviewScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;
  bool _isSaving = false;
  bool _showDebug = true;
  final List<String> _debugLog = <String>[];
  final _canvasKey = GlobalKey();

  // Recording
  Ticker? _recordingTicker;
  bool _isCapturingFrame = false;
  double _devicePixelRatio = 1.0;

  // Rotation drag bookkeeping.
  Offset _rotCenter = Offset.zero;
  double _lastGestureAngle = 0.0;
  static const double _rotDeadZone = 24.0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mirrorPreviewProvider.notifier).onForceStop = () {
        _stopRecordingTicker();
        ref.read(videoRecordingProvider.notifier).forceStop();
      };
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    _recordingTicker?.dispose();
    super.dispose();
  }

  void _log(String msg) {
    debugPrint('[MirrorBooth] $msg');
    if (!mounted) return;
    setState(() {
      final ts = DateTime.now().toIso8601String().substring(11, 19);
      _debugLog.insert(0, '$ts  $msg');
      while (_debugLog.length > 8) {
        _debugLog.removeLast();
      }
    });
  }

  // ── Photo capture ─────────────────────────────────────────────────────────

  Future<void> _captureAndSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    _log('PHOTO');

    File? tempFile;
    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final pixelRatio = _devicePixelRatio;
      _log('capturing ${(boundary.size.width * pixelRatio).round()}×'
          '${(boundary.size.height * pixelRatio).round()}…');

      final uiImage = await boundary.toImage(pixelRatio: pixelRatio);
      _log('captured ${uiImage.width}×${uiImage.height}');

      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('toByteData returned null');
      uiImage.dispose();

      final pngBytes = await compute(
        encodeToPng,
        EncodeJob(
          rgbaBytes: byteData.buffer.asUint8List(),
          width: uiImage.width,
          height: uiImage.height,
        ),
      );
      _log('encoded ${pngBytes.length} B');

      final dir = await getTemporaryDirectory();
      tempFile = File('${dir.path}/mb_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      await Gal.putImage(tempFile.path);
      _log('Gal.putImage OK ✓');
      _flashController.forward(from: 0.0);
    } on GalException catch (e) {
      _log('GalException: ${e.type.code}');
      _showError('${e.type.code}: ${e.type.message}');
    } catch (e, st) {
      _log('ERROR: $e');
      debugPrint(st.toString());
      _showError(e.toString());
    } finally {
      tempFile?.delete().ignore();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Video recording ───────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    final phase = ref.read(videoRecordingProvider).phase;
    if (phase == RecordingPhase.idle) {
      final notifier = ref.read(videoRecordingProvider.notifier);
      await notifier.startRecording();
      if (ref.read(videoRecordingProvider).phase != RecordingPhase.recording) {
        return;
      }
      HapticFeedback.mediumImpact();
      _recordingTicker?.dispose();
      _recordingTicker = createTicker((_) => _captureFrame())..start();
    } else if (phase == RecordingPhase.recording) {
      _stopRecordingTicker();
      HapticFeedback.mediumImpact();
      await ref.read(videoRecordingProvider.notifier).stopRecording();
    }
  }

  void _stopRecordingTicker() {
    _recordingTicker?.stop();
    _recordingTicker?.dispose();
    _recordingTicker = null;
  }

  // Lower pixel ratio for recording: balances quality vs. encode speed.
  static const _recordingPixelRatio = 1.5;

  Future<void> _captureFrame() async {
    if (_isCapturingFrame) return;
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return;
    _isCapturingFrame = true;
    try {
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _recordingPixelRatio);
      await ref.read(videoRecordingProvider.notifier).saveFrame(image);
    } catch (_) {
      // Skip frame on error — recording continues.
    } finally {
      _isCapturingFrame = false;
    }
  }

  // ── Rotation drag ─────────────────────────────────────────────────────────

  void _onRotateStart(DragStartDetails d) {
    final size = MediaQuery.of(context).size;
    _rotCenter = Offset(size.width / 2, size.height / 2);
    final v = d.globalPosition - _rotCenter;
    _lastGestureAngle = atan2(v.dy, v.dx);
  }

  void _onRotateUpdate(DragUpdateDetails d) {
    final v = d.globalPosition - _rotCenter;
    if (v.distance < _rotDeadZone) return;
    final angle = atan2(v.dy, v.dx);
    var delta = angle - _lastGestureAngle;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    _lastGestureAngle = angle;
    final notifier = ref.read(mirrorPreviewProvider.notifier);
    notifier.nudgeRotation(delta * 180.0 / pi);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Could not save photo'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final recordingState = ref.watch(videoRecordingProvider);

    ref.listen<VideoRecordingState>(videoRecordingProvider, (_, next) {
      if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: ref.read(videoRecordingProvider.notifier).clearError,
            ),
          ),
        );
      }
    });

    if (recordingState.phase == RecordingPhase.assembling ||
        recordingState.phase == RecordingPhase.playback) {
      return const VideoPlaybackScreen();
    }

    final previewState = ref.watch(mirrorPreviewProvider);
    final previewNotifier = ref.read(mirrorPreviewProvider.notifier);
    final shaderCacheAsync = ref.watch(shaderCacheProvider);

    return shaderCacheAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Shader load error: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
      ),
      data: (shaderCache) => Scaffold(
        backgroundColor: Colors.black,
        body: _body(context, previewState, previewNotifier, shaderCache, recordingState),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MirrorPreviewState state,
    MirrorPreviewController notifier,
    ShaderCache shaderCache,
    VideoRecordingState recordingState,
  ) {
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(state.error!,
              style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        ),
      );
    }
    if (!state.isReady || state.controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final isRecording = recordingState.phase == RecordingPhase.recording;
    final safeTop = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen rotation drag. Translucent so taps on buttons above pass.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _onRotateStart,
            onPanUpdate: _onRotateUpdate,
          ),
        ),

        // Circular mirror canvas — centered, square, rotates with content.
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: RepaintBoundary(
              key: _canvasKey,
              child: ClipOval(
                child: Transform.rotate(
                  angle: state.rotationDeg * pi / 180.0,
                  child: FilteredMirrorCanvas(
                    controller: state.controller!,
                    side: state.side,
                    filter: state.selectedFilter,
                    shaderCache: shaderCache,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controls hidden during recording (except the rec button itself).
        if (!isRecording)
          Positioned(
            bottom: 148,
            left: 0,
            right: 0,
            child: FilterStrip(
              selected: state.selectedFilter,
              onSelect: notifier.setFilter,
            ),
          ),

        // Bottom row: side | photo (big) | rec | lens
        Positioned(
          bottom: 44,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isRecording) ...[
                SideToggleButton(current: state.side, onToggle: notifier.toggleSide),
                const SizedBox(width: 14),
                _PhotoButton(
                  enabled: !_isSaving,
                  onTap: _captureAndSave,
                ),
                const SizedBox(width: 14),
                _RecButton(isRecording: false, onTap: _toggleRecording),
                if (state.canToggleLens) ...[
                  const SizedBox(width: 14),
                  CameraLensToggleButton(
                    current: state.lensDirection,
                    onToggle: notifier.toggleLens,
                  ),
                ],
              ] else
                _RecButton(isRecording: true, onTap: _toggleRecording),
            ],
          ),
        ),

        if (!isRecording)
          Positioned(
            top: safeTop + 16,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CallButton(),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showDebug = !_showDebug),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Icon(
                      _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
                      color: _showDebug ? Colors.greenAccent : Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (!isRecording && _showDebug)
          Positioned(
            top: safeTop + 16,
            left: 12,
            right: 80,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'rot=${state.rotationDeg.toStringAsFixed(1)}°  side=${state.side.label}  ${_isSaving ? "SAVING…" : "ready"}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_debugLog.isEmpty)
                      const Text(
                        'drag = rotate  •  ⊙ = photo  •  ● = video',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      ..._debugLog.map((l) => Text(
                            l,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                  ],
                ),
              ),
            ),
          ),

        if (isRecording)
          Positioned(
            top: safeTop + 16,
            left: 0,
            right: 0,
            child: Center(
              child: RecordingOverlay(elapsed: recordingState.elapsed),
            ),
          ),

        IgnorePointer(
          child: FadeTransition(
            opacity: _flashOpacity,
            child: AnimatedBuilder(
              animation: _flashController,
              builder: (context, child) => _flashController.isAnimating
                  ? const ColoredBox(color: Colors.white, child: SizedBox.expand())
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _PhotoButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _PhotoButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;
  const _RecButton({required this.isRecording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecording ? Colors.redAccent : Colors.white70,
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isRecording ? 22 : 28,
            height: isRecording ? 22 : 28,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(isRecording ? 4 : 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/call'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: const Icon(Icons.video_call_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
