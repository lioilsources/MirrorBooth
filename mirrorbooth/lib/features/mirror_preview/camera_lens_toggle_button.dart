import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraLensToggleButton extends StatelessWidget {
  final CameraLensDirection current;
  final VoidCallback onToggle;
  final bool enabled;

  const CameraLensToggleButton({
    super.key,
    required this.current,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFront = current == CameraLensDirection.front;
    final label = isFront ? 'FRONT' : 'BACK';
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onToggle : null,
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
              const Icon(
                Icons.cameraswitch_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
