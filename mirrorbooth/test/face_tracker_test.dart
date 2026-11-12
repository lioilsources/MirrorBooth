import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/face_anchor.dart';
import 'package:mirrorbooth/services/face_tracker.dart';

void main() {
  test('parses the largest face, ignores junk', () {
    expect(FaceTracker.parse(null), isNull);
    expect(FaceTracker.parse(const []), isNull);
    expect(
        FaceTracker.parse(const [
          [0.1, 0.2, 0.0, 0.3]
        ]),
        isNull);
    final box = FaceTracker.parse(const [
      [0.25, 0.3, 0.5, 0.4],
      [0.0, 0.0, 0.1, 0.1],
    ])!;
    expect(box.left, 0.25);
    expect(box.height, 0.4);
  });

  test('box maps to center and padded radius over the short side', () {
    // Portrait 1000x2000 frame, face 600x800 px centered at (500, 800).
    const box = FaceBox(0.2, 0.2, 0.6, 0.4);
    final a = box.toAnchor(1000, 2000);
    expect(a.center.dx, closeTo(0.5, 1e-9));
    expect(a.center.dy, closeTo(0.4, 1e-9));
    expect(a.scale, closeTo(0.4 * FaceTracker.boxToRadius, 1e-9));
  });

  test('scale is clamped', () {
    expect(const FaceBox(0, 0, 1, 1).toAnchor(100, 100).scale,
        FaceTracker.maxScale);
    expect(const FaceBox(0.5, 0.5, 0.01, 0.01).toAnchor(100, 100).scale,
        FaceTracker.minScale);
  });

  group('smoothing', () {
    late Duration now;
    late FaceTracker t;
    setUp(() {
      now = Duration.zero;
      t = FaceTracker(clock: () => now);
    });

    test('moves toward a detection, not all the way', () {
      t.update(const FaceBox(0.3, 0.1, 0.4, 0.3), 100, 100);
      expect(t.value.center.dy, lessThan(0.5));
      expect(t.value.center.dy, greaterThan(0.25));
      for (var i = 0; i < 30; i++) {
        t.update(const FaceBox(0.3, 0.1, 0.4, 0.3), 100, 100);
      }
      expect(t.value.center.dy, closeTo(0.25, 0.01));
    });

    test('holds the last face briefly, then eases back to the default', () {
      for (var i = 0; i < 30; i++) {
        t.update(const FaceBox(0.3, 0.1, 0.4, 0.3), 100, 100);
      }
      final held = t.value;
      now += const Duration(milliseconds: 500);
      t.update(null, 100, 100);
      expect(t.value, held);
      now += FaceTracker.holdFor;
      for (var i = 0; i < 100; i++) {
        t.update(null, 100, 100);
      }
      expect(t.value.center.dy, closeTo(0.5, 0.01));
      expect(t.value.scale, closeTo(FaceAnchor.defaults.scale, 0.01));
    });

    test('reset returns to the default anchor', () {
      t.update(const FaceBox(0.0, 0.0, 0.4, 0.3), 100, 100);
      t.reset();
      expect(t.value, FaceAnchor.defaults);
      expect(t.value.center, const Offset(0.5, 0.5));
    });
  });
}
