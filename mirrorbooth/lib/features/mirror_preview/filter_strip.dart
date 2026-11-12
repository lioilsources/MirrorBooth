import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/mirror_filter.dart';
import '../../l10n/l10n.dart';

class FilterStrip extends StatefulWidget {
  final MirrorFilter selected;
  final ValueChanged<MirrorFilter> onSelect;

  /// Paid collections the user owns; unowned paid collections get a lock
  /// badge (selection stays allowed — the paywall gates saving, not trying).
  final Set<FilterCollection> ownedCollections;

  const FilterStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.ownedCollections,
  });

  bool _isLocked(FilterCollection c) =>
      c.isPaid && !ownedCollections.contains(c);

  @override
  State<FilterStrip> createState() => _FilterStripState();
}

class _FilterStripState extends State<FilterStrip> {
  static final _random = math.Random();

  /// Active tab: a regular collection, or the first pack standing in for
  /// the shared Packs tab (see [_packsActive]).
  late FilterCollection _activeCollection =
      widget.selected.collection ?? FilterCollection.pretty;

  bool get _packsActive => _activeCollection.isPack;

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

  /// Tapping a pack chip switches straight to a random filter of that pack,
  /// never the one already on, so every tap shows something new.
  void _openPack(FilterCollection pack) {
    final options = MirrorFilter.inCollection(pack)
        .where((f) => f != widget.selected)
        .toList();
    setState(() => _activeCollection = pack);
    if (options.isEmpty) return;
    widget.onSelect(options[_random.nextInt(options.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final filters = MirrorFilter.inCollection(_activeCollection);
    final packs = FilterCollection.packs;
    final tabs = FilterCollection.tabs;
    final packsLocked = packs.every(widget._isLocked);

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
              for (final c in tabs) ...[
                _CollectionTab(
                  label: c.localizedLabel(context.l10n),
                  isActive: c == _activeCollection,
                  isLocked: widget._isLocked(c),
                  onTap: () => setState(() => _activeCollection = c),
                ),
                const SizedBox(width: 8),
              ],
              _CollectionTab(
                label: context.l10n.collectionPacks,
                isActive: _packsActive,
                isLocked: packsLocked,
                onTap: () {
                  if (!_packsActive) _openPack(packs.first);
                },
              ),
            ],
          ),
        ),
        if (_packsActive) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: packs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final pack = packs[i];
                return _PackChip(
                  label: pack.localizedLabel(context.l10n),
                  isActive: pack == _activeCollection,
                  isLocked: widget._isLocked(pack),
                  onTap: () => _openPack(pack),
                );
              },
            ),
          ),
        ],
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
                isLocked: widget._isLocked(_activeCollection),
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
  final bool isLocked;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isActive,
    required this.isLocked,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              Icon(
                Icons.lock,
                size: 11,
                color: isActive ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              '${filter.icon} ${filter.localizedLabel(context.l10n)}',
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            '${MirrorFilter.none.icon} ${MirrorFilter.none.localizedLabel(context.l10n)}',
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
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _CollectionTab({
    required this.label,
    required this.isActive,
    required this.isLocked,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              const Icon(Icons.lock, size: 10, color: Colors.white60),
              const SizedBox(width: 3),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _PackChip({
    required this.label,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.black45,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? Colors.white : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              Icon(
                Icons.lock,
                size: 10,
                color: isActive ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
