import 'dart:io';
import 'dart:math' show pi;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'mirror_canvas.dart';
import 'mirror_preview_controller.dart';
import 'side_toggle_button.dart';

// ── Isolate data (only primitives + Uint8List to ensure safe transfer) ───────

class _PhotoJob {
  final Uint8List jpegBytes;
  final bool sideIsLeft;
  final double displayAspect;
  final bool flipForIos;    // iOS takePicture() = raw sensor; preview is mirrored
  final int   rotateCcwDeg; // extra CCW rotation for landscape (0, 90, or 270)

  const _PhotoJob({
    required this.jpegBytes,
    required this.sideIsLeft,
    required this.displayAspect,
    required this.flipForIos,
    required this.rotateCcwDeg,
  });
}

/// All CPU-heavy work runs inside a single [compute] isolate so no complex
/// objects cross the isolate boundary.
Uint8List _processPhoto(_PhotoJob job) {
  var src = img.decodeImage(job.jpegBytes);
  if (src == null) throw Exception('Could not decode camera image');

  // iOS: live preview is shown mirrored, but takePicture() returns raw sensor
  if (job.flipForIos) src = img.flipHorizontal(src);

  // Compensate for physical device rotation
  if (job.rotateCcwDeg == 90)  src = img.copyRotate(src, angle: 90);
  if (job.rotateCcwDeg == 270) src = img.copyRotate(src, angle: 270);

  // Crop to display aspect ratio (BoxFit.cover equivalent)
  final imgAspect = src.width / src.height;
  int cropW, cropH, cropX, cropY;
  if (imgAspect > job.displayAspect) {
    cropH = src.height;
    cropW = (src.height * job.displayAspect).round().clamp(1, src.width);
    cropX = (src.width - cropW) ~/ 2;
    cropY = 0;
  } else {
    cropW = src.width;
    cropH = (src.width / job.displayAspect).round().clamp(1, src.height);
    cropX = 0;
    cropY = (src.height - cropH) ~/ 2;
  }
  src = img.copyCrop(src, x: cropX, y: cropY, width: cropW, height: cropH);

  // Mirror composition: both panels show the same face half, one flipped
  final panelW = cropW ~/ 2;
  final srcX   = job.sideIsLeft ? 0 : cropW - panelW;
  final panel  = img.copyCrop(src, x: srcX, y: 0, width: panelW, height: cropH);
  final mirror = img.flipHorizontal(panel);

  final output = img.Image(width: cropW, height: cropH);
  if (job.sideIsLeft) {
    img.compositeImage(output, panel,  dstX: 0);
    img.compositeImage(output, mirror, dstX: panelW);
  } else {
    img.compositeImage(output, mirror, dstX: 0);
    img.compositeImage(output, panel,  dstX: panelW);
  }

  return Uint8List.fromList(img.encodeJpg(output, quality: 92));
}

// ── Screen ───────────────────────────────────────────────────────────────────

/// Degrees of CCW rotation applied to camera preview to correct for the phone
/// being held landscape. 0 = portrait (normal), 90 = phone tilted CW (camera
/// on left), 270 = phone tilted CCW (camera on right).
enum _CamTilt { portrait, cw, ccw }

class MirrorPreviewScreen extends ConsumerStatefulWidget {
  const MirrorPreviewScreen({super.key});

  @override
  ConsumerState<MirrorPreviewScreen> createState() => _MirrorPreviewScreenState();
}

class _MirrorPreviewScreenState extends ConsumerState<MirrorPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;
  bool _isSaving = false;

  _CamTilt _tilt = _CamTilt.portrait;
  // Raw stream subscription; listen with a debounce to avoid flutter between states.
  late final _accelSub = accelerometerEventStream(
    samplingPeriod: SensorInterval.normalInterval,
  ).listen(_onAccel);

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
  }

  @override
  void dispose() {
    _accelSub.cancel();
    _flashController.dispose();
    super.dispose();
  }

  void _onAccel(AccelerometerEvent e) {
    // Threshold: |x| must dominate |y| by at least 3 m/s² for a stable read.
    final _CamTilt next;
    if (e.x.abs() > e.y.abs() + 3.0) {
      // Phone tilted: camera goes left (CW rotation) or right (CCW rotation)
      next = e.x > 0 ? _CamTilt.cw : _CamTilt.ccw;
    } else if (e.y.abs() > e.x.abs() + 3.0) {
      next = _CamTilt.portrait;
    } else {
      return; // ambiguous zone, hold current
    }
    if (next != _tilt) setState(() => _tilt = next);
  }

  // ── Capture ──────────────────────────────────────────────────────────────

  Future<void> _captureAndSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    File? tempFile;
    try {
      final state      = ref.read(mirrorPreviewProvider);
      final xfile      = await state.controller!.takePicture();
      final rawBytes   = await xfile.readAsBytes();

      if (!mounted) return;
      final mq = MediaQuery.of(context);

      // When phone is landscape the display aspect ratio seen by the user is
      // still "portrait" (we keep portrait lock), so always use portrait ratio.
      final displayAspect = mq.size.height / mq.size.width;

      final job = _PhotoJob(
        jpegBytes:    rawBytes,
        sideIsLeft:   state.side.isLeft,
        displayAspect: displayAspect,
        flipForIos:   Platform.isIOS,
        rotateCcwDeg: _tilt == _CamTilt.cw  ? 90
                    : _tilt == _CamTilt.ccw ? 270
                    : 0,
      );

      final outBytes = await compute(_processPhoto, job);

      final dir = await getTemporaryDirectory();
      tempFile  = File('${dir.path}/mb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(outBytes);

      if (await Permission.storage.request().isGranted) {
        await Gal.putImage(tempFile.path);
      } else {
        _showError('Storage permission denied');
      }

      _flashController.forward(from: 0.0);
    } on GalException catch (e) {
      _showError(e.type.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      tempFile?.delete().ignore();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Could not save photo'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(mirrorPreviewProvider);
    final notifier = ref.read(mirrorPreviewProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _body(context, state, notifier),
    );
  }

  Widget _body(BuildContext context, MirrorPreviewState state, MirrorPreviewController notifier) {
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(state.error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        ),
      );
    }
    if (!state.isReady || state.controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _captureAndSave,
          child: _cameraView(context, state),
        ),
        Center(child: Container(width: 1, color: Colors.white12)),
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SideToggleButton(current: state.side, onToggle: notifier.toggleSide)],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 20,
          child: _CallButton(),
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

  /// Wraps [MirrorCanvas] with a corrective rotation when the phone is held
  /// landscape, so the face always appears upright in the portrait frame.
  ///
  /// Rotation logic (portrait frame W × H, H > W):
  ///   - Rotate content 90° → it becomes visually H × W
  ///   - Scale by H/W so height fills the portrait screen (width overflows → clipped)
  Widget _cameraView(BuildContext context, MirrorPreviewState state) {
    final canvas = MirrorCanvas(controller: state.controller!, side: state.side);
    if (_tilt == _CamTilt.portrait) return canvas;

    final size  = MediaQuery.of(context).size;
    final scale = size.height / size.width; // > 1 for portrait screen
    // CW tilt (camera went to the left) → rotate preview CCW (-90°) to correct
    // CCW tilt (camera went to the right) → rotate preview CW (+90°) to correct
    final angle = _tilt == _CamTilt.cw ? -pi / 2 : pi / 2;

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(width: size.width, height: size.height, child: canvas),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/call'),
      child: Container(
        width: 52, height: 52,
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
