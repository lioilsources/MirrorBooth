import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'mirror_canvas.dart';
import 'mirror_preview_controller.dart';
import 'side_toggle_button.dart';

// ── Isolate payload (only primitives + Uint8List, safe across isolate) ───────

class _PhotoJob {
  final Uint8List jpegBytes;
  final bool sideIsLeft;
  final double displayAspect; // portrait W/H (< 1)
  final bool flipForIos;      // iOS takePicture() = un-mirrored sensor
  final int rotateCcwDeg;     // 0/90/180/270 — match preview rotation

  const _PhotoJob({
    required this.jpegBytes,
    required this.sideIsLeft,
    required this.displayAspect,
    required this.flipForIos,
    required this.rotateCcwDeg,
  });
}

Uint8List _processPhoto(_PhotoJob job) {
  var src = img.decodeImage(job.jpegBytes);
  if (src == null) throw Exception('decodeImage returned null');

  if (job.flipForIos) src = img.flipHorizontal(src);

  if (job.rotateCcwDeg == 90) src = img.copyRotate(src, angle: 90);
  if (job.rotateCcwDeg == 180) src = img.copyRotate(src, angle: 180);
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

  // Mirror split: both panels show same face half, one flipped
  final panelW = cropW ~/ 2;
  if (panelW < 1) throw Exception('panelW=$panelW after crop ${cropW}x$cropH');
  final srcX = job.sideIsLeft ? 0 : cropW - panelW;
  final panel = img.copyCrop(src, x: srcX, y: 0, width: panelW, height: cropH);
  final mirror = img.flipHorizontal(panel);

  final output = img.Image(width: cropW, height: cropH);
  if (job.sideIsLeft) {
    img.compositeImage(output, panel, dstX: 0);
    img.compositeImage(output, mirror, dstX: panelW);
  } else {
    img.compositeImage(output, mirror, dstX: 0);
    img.compositeImage(output, panel, dstX: panelW);
  }

  return Uint8List.fromList(img.encodeJpg(output, quality: 92));
}

// ── Screen ───────────────────────────────────────────────────────────────────

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
  bool _showDebug = true;
  final List<String> _debugLog = <String>[];

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
    _flashController.dispose();
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

  // ── Capture ──────────────────────────────────────────────────────────────

  Future<void> _captureAndSave() async {
    if (_isSaving) {
      _log('tap ignored — already saving');
      return;
    }
    setState(() => _isSaving = true);
    _log('TAP');

    File? tempFile;
    try {
      final state = ref.read(mirrorPreviewProvider);
      if (state.controller == null) {
        _log('controller is null');
        return;
      }

      _log('takePicture()…');
      final xfile = await state.controller!.takePicture();
      _log('xfile: ${xfile.path.split('/').last}');

      final rawBytes = await xfile.readAsBytes();
      _log('read ${rawBytes.length} B');

      if (!mounted) return;
      final mq = MediaQuery.of(context);
      // Portrait W/H (< 1). Screen stays portrait regardless of physical phone tilt.
      final displayAspect = mq.size.width / mq.size.height;

      _log('compose rot=${state.rotationDeg}…');
      final job = _PhotoJob(
        jpegBytes: rawBytes,
        sideIsLeft: state.side.isLeft,
        displayAspect: displayAspect,
        flipForIos: Platform.isIOS,
        rotateCcwDeg: state.rotationDeg,
      );
      final outBytes = await compute(_processPhoto, job);
      _log('composed ${outBytes.length} B');

      final dir = await getTemporaryDirectory();
      tempFile = File('${dir.path}/mb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(outBytes);
      _log('wrote temp');

      // gal handles the platform permission internally; don't pre-check with
      // permission_handler — Permission.storage is deprecated/blocked on
      // Android 13+, manual checks just cause silent failures.
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
    final state = ref.watch(mirrorPreviewProvider);
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
          child: Text(
            state.error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!state.isReady || state.controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera + mirror — rotation applied INSIDE each panel so the seam stays vertical.
        MirrorCanvas(
          controller: state.controller!,
          side: state.side,
          cameraRotationDeg: state.rotationDeg,
        ),

        // Vertical seam indicator
        Center(child: Container(width: 1, color: Colors.white12)),

        // Top-level tap target — reliable hit testing regardless of inner transforms.
        // Sits BELOW the controls in the stack so they capture their own taps first.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _captureAndSave,
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SideToggleButton(current: state.side, onToggle: notifier.toggleSide),
              const SizedBox(width: 16),
              _RotateButton(
                deg: state.rotationDeg,
                onTap: notifier.cycleRotation,
              ),
            ],
          ),
        ),

        // Top-right: call button + debug toggle
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
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

        // Debug overlay (top-left)
        if (_showDebug)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
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
                      'rot=${state.rotationDeg}°  side=${state.side.label}  ${_isSaving ? "SAVING…" : "ready"}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_debugLog.isEmpty)
                      const Text(
                        'tap anywhere to take a photo',
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

        // Flash overlay
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

class _RotateButton extends StatelessWidget {
  final int deg;
  final VoidCallback onTap;
  const _RotateButton({required this.deg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.screen_rotation_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              '$deg°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
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
