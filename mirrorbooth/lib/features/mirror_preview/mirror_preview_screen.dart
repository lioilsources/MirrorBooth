import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';

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
import '../../services/shutter_button_channel.dart';
import '../paywall/entitlement_controller.dart';
import '../paywall/paywall_sheet.dart';
import '../video_recording/recording_overlay.dart';
import '../video_recording/video_playback_screen.dart';
import '../video_recording/video_recording_notifier.dart';
import '../video_recording/video_recording_state.dart';
import 'camera_lens_toggle_button.dart';
import 'filter_strip.dart';
import 'filtered_mirror_canvas.dart';
import 'mirror_geometry.dart';
import 'mirror_preview_controller.dart';
import 'photo_composer.dart';
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

  // Hardware shutter (volume buttons)
  StreamSubscription<ShutterPress>? _shutterSub;
  bool _shutterClaimed = false;
  bool _shutterSupported = false;

  // Rotation drag bookkeeping.
  Offset _rotCenter = Offset.zero;
  double _lastGestureAngle = 0.0;
  bool _draggingInnerRing = false;
  static const double _rotDeadZone = 24.0;
  // Fraction of shortest screen side used for each ring's diameter.
  static const double _outerRingDiameterFrac = 0.88;
  static const double _innerRingDiameterFrac = 0.44;

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
      // Deferred to the first frame: the native side attaches to the root
      // view, which only exists once the view hierarchy is up.
      _setShutterClaimed(true);
      ShutterButtonChannel.isSupported().then((supported) {
        if (mounted) setState(() => _shutterSupported = supported);
      });
    });
    _shutterSub = ShutterButtonChannel.presses.listen(_onShutterPress);
  }

  @override
  void dispose() {
    _shutterSub?.cancel();
    if (_shutterClaimed) ShutterButtonChannel.setEnabled(false);
    _flashController.dispose();
    _recordingTicker?.dispose();
    super.dispose();
  }

  // ── Hardware shutter ──────────────────────────────────────────────────────

  /// Claims/releases the volume keys. Released while the playback screen is up
  /// so the keys go back to controlling playback volume.
  void _setShutterClaimed(bool claimed) {
    if (_shutterClaimed == claimed) return;
    _shutterClaimed = claimed;
    ShutterButtonChannel.setEnabled(claimed);
  }

  void _onShutterPress(ShutterPress press) {
    if (!mounted) return;
    final phase = ref.read(videoRecordingProvider).phase;
    if (phase == RecordingPhase.recording) {
      _toggleRecording();
      return;
    }
    if (phase != RecordingPhase.idle) return;
    if (press == ShutterPress.long) {
      _toggleRecording();
    } else {
      _captureAndSave();
    }
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

  /// Returns true if capture may proceed with the current filter; otherwise
  /// opens the paywall for its collection. Trying filters live is free — only
  /// saving is gated.
  bool _ensureEntitledForCapture() {
    final collection =
        ref.read(mirrorPreviewProvider).selectedFilter.collection;
    if (collection == null) return true;
    if (ref.read(entitlementProvider).owns(collection)) return true;
    showPaywallSheet(context, collection);
    return false;
  }

  Future<void> _captureAndSave() async {
    if (_isSaving) return;
    if (!_ensureEntitledForCapture()) return;
    setState(() => _isSaving = true);
    _log('PHOTO');

    File? tempFile;
    try {
      ui.Image image;
      try {
        image = await _composeHighResPhoto();
      } catch (e) {
        _log('still capture failed: $e');
        _log('falling back to screen capture');
        image = await _captureBoundaryImage();
      }
      _log('captured ${image.width}×${image.height}');

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      final height = image.height;
      image.dispose();
      if (byteData == null) throw Exception('toByteData returned null');

      final jpegBytes = await compute(
        encodeToJpeg,
        EncodeJob(
          rgbaBytes: byteData.buffer.asUint8List(),
          width: width,
          height: height,
        ),
      );
      _log('encoded ${jpegBytes.length} B');

      final dir = await getTemporaryDirectory();
      tempFile = File('${dir.path}/mb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(jpegBytes);

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

  /// Full-quality photo path: takes a full-resolution still from the sensor
  /// and recomposes the current mirror/rotation/filter offline at the still's
  /// native pixel density — far sharper than rasterising the preview.
  Future<ui.Image> _composeHighResPhoto() async {
    final state = ref.read(mirrorPreviewProvider);
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('camera not ready');
    }
    final boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final screenSize = boundary.size;

    final xfile = await controller.takePicture();
    final bytes = await xfile.readAsBytes();
    File(xfile.path).delete().ignore();
    final codec = await ui.instantiateImageCodec(bytes);
    final still = (await codec.getNextFrame()).image;
    codec.dispose();
    _log('still ${still.width}×${still.height}');

    final filter = state.selectedFilter;
    final shader =
        ref.read(shaderCacheProvider).valueOrNull?[filter]?.fragmentShader();
    try {
      return await composeMirrorPhoto(PhotoComposeJob(
        still: still,
        mirrorStillHorizontally:
            state.lensDirection == CameraLensDirection.front,
        screenSize: screenSize,
        rotationDeg: state.rotationDeg,
        mirrorAxisDeg: state.mirrorAxisDeg,
        directOnLeft: state.side.isLeft,
        portraitAspect: 1.0 / controller.value.aspectRatio,
        shader: shader,
        shaderNeedsTime: filter.needsTime,
        time: (DateTime.now().millisecondsSinceEpoch / 1000.0) % 100.0,
        shaderNeedsFace: filter.needsFace,
      ));
    } finally {
      still.dispose();
      shader?.dispose();
    }
  }

  /// Fallback: rasterise the on-screen boundary (screen-resolution quality).
  Future<ui.Image> _captureBoundaryImage() {
    final boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: _devicePixelRatio);
  }

  // ── Video recording ───────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    final phase = ref.read(videoRecordingProvider).phase;
    if (phase == RecordingPhase.idle) {
      // Gate only starting — stopping a recording must never be blocked.
      if (!_ensureEntitledForCapture()) return;
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
    // Inner ring gets priority when the drag begins inside its radius (plus
    // a small touch-tolerance margin); otherwise the drag rotates the
    // outer composition.
    final innerRadius = size.shortestSide * _innerRingDiameterFrac / 2;
    _draggingInnerRing = v.distance <= innerRadius + 16.0;
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
    final deltaDeg = delta * 180.0 / pi;
    if (_draggingInnerRing) {
      notifier.nudgeMirrorAxis(deltaDeg);
    } else {
      notifier.nudgeRotation(deltaDeg);
    }
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
      // Hand the volume keys back while the playback screen is up so they
      // control playback volume as usual.
      _setShutterClaimed(next.phase == RecordingPhase.idle ||
          next.phase == RecordingPhase.recording);
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
    final screenSize = MediaQuery.of(context).size;
    // Canvas sized to exactly cover the screen at the current rotation and
    // mirror-axis angles (direct and reflected halves both). At the default
    // state this is the screen itself — the widest possible framing and the
    // most camera detail per screen pixel; it grows toward the screen
    // diagonal as the composition or axis rotates.
    final canvasBox = MirrorGeometry.canvasBoxFor(
        screenSize, state.rotationDeg, state.mirrorAxisDeg);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Mirror canvas sized by MirrorGeometry — no circular clip.
        // RepaintBoundary (keyed) captures the visible W×H area for the
        // recording ticker and the photo fallback path.
        Positioned.fill(
          child: RepaintBoundary(
            key: _canvasKey,
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: state.rotationDeg * pi / 180.0,
                child: SizedBox(
                  width: canvasBox.width,
                  height: canvasBox.height,
                  child: RepaintBoundary(
                    child: FilteredMirrorCanvas(
                      controller: state.controller!,
                      side: state.side,
                      filter: state.selectedFilter,
                      shaderCache: shaderCache,
                      mirrorAxisDeg: state.mirrorAxisDeg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Outer rotation ring overlay — decorative circle showing the drag
        // target for whole-image rotation.
        IgnorePointer(
          child: Center(
            child: _RotationRing(
              rotationDeg: state.rotationDeg,
              diameterFrac: _outerRingDiameterFrac,
            ),
          ),
        ),

        // Inner mirror-axis ring — dashed circle with a thin line indicating
        // the current mirror axis direction through the screen centre.
        IgnorePointer(
          child: Center(
            child: _MirrorAxisRing(
              mirrorAxisDeg: state.mirrorAxisDeg,
              diameterFrac: _innerRingDiameterFrac,
            ),
          ),
        ),

        // Full-screen rotation drag — must be above the camera Texture so it
        // receives pointer events that the Texture would otherwise absorb.
        // Pan gestures don't interfere with taps on buttons above.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _onRotateStart,
            onPanUpdate: _onRotateUpdate,
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
              ownedCollections: ref.watch(entitlementProvider).owned,
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
                      'rot=${state.rotationDeg.toStringAsFixed(1)}°  axis=${state.mirrorAxisDeg.toStringAsFixed(1)}°  side=${state.side.label}  ${_isSaving ? "SAVING…" : "ready"}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_debugLog.isEmpty)
                      Text(
                        'drag = rotate  •  ⊙ = photo  •  ● = video'
                        '${_shutterSupported ? "\nvol = photo  •  vol hold = video" : ""}',
                        style: const TextStyle(
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

class _RotationRing extends StatelessWidget {
  final double rotationDeg;
  final double diameterFrac;
  const _RotationRing({
    required this.rotationDeg,
    required this.diameterFrac,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = size.shortestSide * diameterFrac;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(painter: _RingPainter(rotationDeg: rotationDeg)),
    );
  }
}

class _MirrorAxisRing extends StatelessWidget {
  final double mirrorAxisDeg;
  final double diameterFrac;
  const _MirrorAxisRing({
    required this.mirrorAxisDeg,
    required this.diameterFrac,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = size.shortestSide * diameterFrac;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _MirrorAxisRingPainter(mirrorAxisDeg: mirrorAxisDeg),
      ),
    );
  }
}

class _MirrorAxisRingPainter extends CustomPainter {
  final double mirrorAxisDeg;
  const _MirrorAxisRingPainter({required this.mirrorAxisDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dashed outer ring.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashCount = 48;
    const sweep = 2 * pi / dashCount;
    const gapFrac = 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(rect, start, sweep * (1 - gapFrac), false, ringPaint);
    }

    // Thin axis line through centre at the mirror-axis angle. The axis is
    // a line (both directions) so we draw from -radius to +radius along it.
    final theta = mirrorAxisDeg * pi / 180.0;
    final dir = Offset(cos(theta), sin(theta));
    final axisLength = radius - 4.0;
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center - dir * axisLength, center + dir * axisLength, axisPaint);

    // Tiny centre dot for affordance.
    canvas.drawCircle(
      center,
      2.0,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_MirrorAxisRingPainter old) =>
      old.mirrorAxisDeg != mirrorAxisDeg;
}

class _RingPainter extends CustomPainter {
  final double rotationDeg;
  const _RingPainter({required this.rotationDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );

    // Tick marks every 30°
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - rotationDeg) * pi / 180.0;
      final isMajor = i % 3 == 0;
      final inner = radius - (isMajor ? 14.0 : 8.0);
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inner,
        center + Offset(cos(angle), sin(angle)) * (radius - 2),
        tickPaint,
      );
    }

    // Top indicator dot (shows current 0° position)
    final dotAngle = -rotationDeg * pi / 180.0 - pi / 2;
    canvas.drawCircle(
      center + Offset(cos(dotAngle), sin(dotAngle)) * (radius - 8),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rotationDeg != rotationDeg;
}
