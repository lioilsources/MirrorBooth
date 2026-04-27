import 'package:flutter/material.dart';
import '../../core/mirror_filter.dart';

class FilterStrip extends StatelessWidget {
  final MirrorFilter selected;
  final ValueChanged<MirrorFilter> onSelect;

  const FilterStrip({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: MirrorFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = MirrorFilter.values[i];
          final isActive = f == selected;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.black54,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${f.icon} ${f.label}',
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontSize: 12,
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
