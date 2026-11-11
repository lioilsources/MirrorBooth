import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';

void main() {
  test('every Lab filter sits in exactly one Lab chip', () {
    final lab = MirrorFilter.inCollection(FilterCollection.experimental);
    final grouped = [for (final g in MirrorFilter.labGroups) ...g.filters];
    expect(grouped.length, lab.length);
    expect(grouped.toSet(), lab.toSet());
  });

  test('round 2 families get one chip each, after the paged chips', () {
    final labels = MirrorFilter.labGroups.map((g) => g.label).toList();
    final families = labels.where((l) => !l.contains('–')).toList();
    expect(families.length, MirrorFilter.labFamilies.length);
    expect(labels.indexOf(families.first),
        labels.lastIndexWhere((l) => l.contains('–')) + 1);
  });
}
