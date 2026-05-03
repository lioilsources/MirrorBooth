import 'package:flutter/material.dart';

import 'video_recording_state.dart';

class AudioEffectStrip extends StatelessWidget {
  final AudioEffect selected;
  final ValueChanged<AudioEffect> onSelect;
  final bool isProcessing;

  const AudioEffectStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AudioEffect.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final effect = AudioEffect.values[i];
          final isActive = effect == selected;
          return GestureDetector(
            onTap: isProcessing ? null : () => onSelect(effect),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.black54,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${effect.icon} ${effect.label}',
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
