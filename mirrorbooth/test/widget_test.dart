import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_side.dart';

void main() {
  test('MirrorSide toggle', () {
    expect(MirrorSide.left.toggled, MirrorSide.right);
    expect(MirrorSide.right.toggled, MirrorSide.left);
  });

  test('MirrorSide label', () {
    expect(MirrorSide.left.label, 'L');
    expect(MirrorSide.right.label, 'R');
  });
}
