import 'package:flutter/material.dart';
import '../../core/mirror_side.dart';

class SideToggleButton extends StatelessWidget {
  final MirrorSide current;
  final VoidCallback onToggle;

  const SideToggleButton({
    super.key,
    required this.current,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
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
            Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              current.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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
