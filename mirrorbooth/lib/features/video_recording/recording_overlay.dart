import 'package:flutter/material.dart';

class RecordingOverlay extends StatefulWidget {
  final Duration elapsed;
  const RecordingOverlay({super.key, required this.elapsed});

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _format(widget.elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
