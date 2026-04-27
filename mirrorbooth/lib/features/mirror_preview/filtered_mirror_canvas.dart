import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../core/mirror_filter.dart';
import '../../core/mirror_side.dart';
import '../../core/shader_provider.dart';
import 'mirror_canvas.dart';

class FilteredMirrorCanvas extends StatefulWidget {
  final CameraController controller;
  final MirrorSide side;
  final int cameraRotationDeg;
  final MirrorFilter filter;
  final ShaderCache shaderCache;

  const FilteredMirrorCanvas({
    super.key,
    required this.controller,
    required this.side,
    required this.cameraRotationDeg,
    required this.filter,
    required this.shaderCache,
  });

  @override
  State<FilteredMirrorCanvas> createState() => _FilteredMirrorCanvasState();
}

class _FilteredMirrorCanvasState extends State<FilteredMirrorCanvas>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  late final Ticker _ticker;
  ui.Image? _frame;
  bool _capturing = false;
  double _devicePixelRatio = 1.0;
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (widget.filter == MirrorFilter.none) return;
    if (_capturing) return;
    _captureFrame();
  }

  Future<void> _captureFrame() async {
    _capturing = true;
    try {
      final ctx = _repaintKey.currentContext;
      if (ctx == null) return;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: _devicePixelRatio);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _frame?.dispose();
        _frame = image;
      });
    } catch (e) {
      debugPrint('filter capture: $e');
    } finally {
      _capturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final mirrorCanvas = MirrorCanvas(
      controller: widget.controller,
      side: widget.side,
      cameraRotationDeg: widget.cameraRotationDeg,
    );

    if (widget.filter == MirrorFilter.none) return mirrorCanvas;

    final program = widget.shaderCache[widget.filter];
    final frame = _frame;

    return Stack(
      fit: StackFit.expand,
      children: [
        // MirrorCanvas stays composited so the Texture widget keeps receiving
        // camera frames. RepaintBoundary isolates it for toImage() captures.
        RepaintBoundary(key: _repaintKey, child: mirrorCanvas),

        // Shader overlay drawn once we have a captured frame.
        if (program != null && frame != null)
          CustomPaint(
            painter: _FilterShaderPainter(
              image: frame,
              program: program,
              needsTime: widget.filter.needsTime,
              time: (_stopwatch.elapsedMilliseconds / 1000.0) % 100.0,
            ),
          ),
      ],
    );
  }
}

class _FilterShaderPainter extends CustomPainter {
  final ui.Image image;
  final ui.FragmentProgram program;
  final bool needsTime;
  final double time;

  _FilterShaderPainter({
    required this.image,
    required this.program,
    required this.needsTime,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setImageSampler(0, image);
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    if (needsTime) shader.setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FilterShaderPainter old) =>
      old.image != image ||
      old.program != program ||
      (needsTime && old.time != time);
}
