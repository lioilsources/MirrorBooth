import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/l10n/l10n.dart';

void main() {
  test('every pack is paid, has filters and its own product', () {
    final ids = <String>{};
    for (final p in FilterCollection.packs) {
      expect(p.isPaid, isTrue, reason: '$p');
      expect(MirrorFilter.inCollection(p), isNotEmpty, reason: '$p');
      expect(ids.add(p.productId!), isTrue, reason: '$p');
    }
  });

  test('Tunnel and Night live in Optics and VHS', () {
    expect(MirrorFilter.r2OpticsTunnel.collection, FilterCollection.optics);
    expect(MirrorFilter.r2VhsNight.collection, FilterCollection.vhs);
  });

  test('packs share one tab', () {
    expect(FilterCollection.tabs.where((c) => c.isPack), isEmpty);
  });

  // Wide enough for every pack chip without scrolling.
  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(4000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget strip(MirrorFilter selected, ValueChanged<MirrorFilter> onSelect) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FilterStrip(
            selected: selected,
            onSelect: onSelect,
            ownedCollections: const {},
          ),
        ),
      );

  testWidgets('tapping a pack chip switches to one of its filters',
      (tester) async {
    wide(tester);
    MirrorFilter? picked;
    final first = MirrorFilter.inCollection(FilterCollection.mosaic).first;
    await tester.pumpWidget(strip(first, (f) => picked = f));
    await tester.tap(find.text('Kaleido'));
    expect(picked?.collection, FilterCollection.kaleido);
  });

  testWidgets('tapping the active pack chip picks a different filter',
      (tester) async {
    wide(tester);
    final current = MirrorFilter.inCollection(FilterCollection.vhs).first;
    for (var i = 0; i < 10; i++) {
      MirrorFilter? picked;
      await tester.pumpWidget(strip(current, (f) => picked = f));
      await tester.tap(find.text('VHS'));
      expect(picked?.collection, FilterCollection.vhs);
      expect(picked, isNot(current));
    }
  });
}
