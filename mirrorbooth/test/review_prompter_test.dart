import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/services/review_prompter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _start = DateTime(2026, 11, 1, 12);

Future<(ReviewPrompter, List<int>, void Function(String))> _make({
  int launches = ReviewPrompter.minLaunches,
  DateTime? firstLaunch,
  DateTime Function()? now,
}) async {
  SharedPreferences.setMockInitialValues({
    'review_launches': launches,
    'review_first_launch_ms': (firstLaunch ?? _start).millisecondsSinceEpoch,
  });
  final prefs = await SharedPreferences.getInstance();
  final asks = <int>[];
  var version = '2.4.0';
  final prompter = ReviewPrompter(
    prefs,
    appVersion: () async => version,
    request: () async {
      asks.add(1);
      return true;
    },
    now: now ?? () => _start.add(ReviewPrompter.minAge),
  );
  return (prompter, asks, (String v) => version = v);
}

void main() {
  test('asks on the third photo, once per version', () async {
    final (p, asks, setVersion) = await _make();
    expect(await p.photoDone(), isFalse);
    expect(await p.photoDone(), isFalse);
    expect(await p.photoDone(), isTrue);
    expect(await p.photoDone(), isFalse);
    expect(asks, hasLength(1));
    setVersion('2.4.1');
    expect(await p.photoDone(), isTrue);
  });

  test('the first video is enough', () async {
    final (p, asks, _) = await _make();
    expect(await p.videoDone(), isTrue);
    expect(asks, hasLength(1));
  });

  test('never during the first launches', () async {
    final (p, asks, _) = await _make(launches: ReviewPrompter.minLaunches - 1);
    for (var i = 0; i < 5; i++) {
      await p.photoDone();
    }
    await p.videoDone();
    expect(asks, isEmpty);
  });

  test('a fresh install waits minAge even with many launches', () async {
    var clock = _start;
    final (p, asks, _) =
        await _make(launches: 10, firstLaunch: _start, now: () => clock);
    await p.videoDone();
    clock = _start.add(ReviewPrompter.minAge - const Duration(minutes: 1));
    await p.videoDone();
    expect(asks, isEmpty);
    clock = _start.add(ReviewPrompter.minAge);
    expect(await p.videoDone(), isTrue);
  });

  test('recordLaunch stamps the first launch once', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var clock = _start;
    final p = ReviewPrompter(prefs,
        appVersion: () async => '2.5.0',
        request: () async => true,
        now: () => clock);
    p.recordLaunch();
    clock = clock.add(const Duration(days: 9));
    p.recordLaunch();
    expect(prefs.getInt('review_first_launch_ms'), _start.millisecondsSinceEpoch);
    expect(prefs.getInt('review_launches'), 2);
  });

  test('held back right after an error', () async {
    var clock = _start.add(ReviewPrompter.minAge);
    final (p, asks, _) = await _make(now: () => clock);
    await p.photoDone();
    await p.photoDone();
    p.errorShown();
    expect(await p.photoDone(), isFalse);
    clock = clock.add(ReviewPrompter.errorCooldown);
    expect(await p.photoDone(), isTrue);
    expect(asks, hasLength(1));
  });
}
