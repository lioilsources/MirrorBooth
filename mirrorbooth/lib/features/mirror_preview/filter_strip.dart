import 'package:flutter/material.dart';
import '../../core/mirror_filter.dart';

class FilterStrip extends StatefulWidget {
  final MirrorFilter selected;
  final ValueChanged<MirrorFilter> onSelect;

  const FilterStrip({super.key, required this.selected, required this.onSelect});

  @override
  State<FilterStrip> createState() => _FilterStripState();
}

class _FilterStripState extends State<FilterStrip> {
  late FilterCollection _activeCollection =
      widget.selected.collection ?? FilterCollection.pretty;

  @override
  void didUpdateWidget(FilterStrip old) {
    super.didUpdateWidget(old);
    // Follow programmatic filter changes; selecting `none` keeps the current
    // tab so browsing isn't reset.
    final c = widget.selected.collection;
    if (c != null && c != _activeCollection) {
      setState(() => _activeCollection = c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = MirrorFilter.inCollection(_activeCollection);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _NoneChip(
                isActive: widget.selected == MirrorFilter.none,
                onTap: () => widget.onSelect(MirrorFilter.none),
              ),
              const SizedBox(width: 8),
              for (final c in FilterCollection.values) ...[
                _CollectionTab(
                  collection: c,
                  isActive: c == _activeCollection,
                  onTap: () => setState(() => _activeCollection = c),
                ),
                if (c != FilterCollection.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = filters[i];
              return _FilterChip(
                filter: f,
                isActive: f == widget.selected,
                onTap: () => widget.onSelect(f),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final MirrorFilter filter;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          '${filter.icon} ${filter.label}',
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NoneChip extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _NoneChip({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.black54,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Center(
          widthFactor: 1.0,
          child: Text(
            '${MirrorFilter.none.icon} ${MirrorFilter.none.label}',
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionTab extends StatelessWidget {
  final FilterCollection collection;
  final bool isActive;
  final VoidCallback onTap;

  const _CollectionTab({
    required this.collection,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Underline instead of a filled pill so the active tab reads differently
    // from the active filter chip below.
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Center(
          widthFactor: 1.0,
          child: Text(
            collection.label.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
