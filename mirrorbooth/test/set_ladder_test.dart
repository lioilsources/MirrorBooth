// Table test for lib/core/set_ladder.dart; copied together with it into every
// app that sells an "all" bundle, only the import changes.
import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/set_ladder.dart';

const _ladder = <SetTier>[
  (threshold: 0, productId: 'all'),
  (threshold: 1, productId: 'all_s1'),
  (threshold: 2, productId: 'all_s2'),
  (threshold: 3, productId: 'all_s3'),
  (threshold: 4, productId: 'all_s4'),
];

void main() {
  test('offers the highest tier whose threshold is met', () {
    const table = <int, String>{
      0: 'all',
      1: 'all_s1',
      2: 'all_s2',
      3: 'all_s3',
      4: 'all_s4',
      5: 'all_s4',
      15: 'all_s4',
      1000: 'all_s4',
    };
    for (final MapEntry(key: owned, value: expected) in table.entries) {
      expect(offerFromLadder(owned, _ladder), expected, reason: 'owned $owned');
    }
  });

  test('gaps in the ladder fall back to the next lower tier', () {
    const gappy = <SetTier>[
      (threshold: 0, productId: 'all'),
      (threshold: 3, productId: 'all_s3'),
    ];
    expect(offerFromLadder(0, gappy), 'all');
    expect(offerFromLadder(2, gappy), 'all');
    expect(offerFromLadder(3, gappy), 'all_s3');
    expect(offerFromLadder(9, gappy), 'all_s3');
  });

  test('no tier applies: empty ladder or every threshold above', () {
    expect(offerFromLadder(3, const []), isNull);
    expect(
      offerFromLadder(0, const [(threshold: 1, productId: 'all_s1')]),
      isNull,
    );
  });
}
