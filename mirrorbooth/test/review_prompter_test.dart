import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/services/review_prompter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ReviewPrompter, List<int>, void Function(String))> _make({
  int launches = 2,
  DateTime Function()? now,
}) async {
  SharedPreferences.setMockInitialValues({'review_launches': launches});
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
    now: now,
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

  test('never during the first launch', () async {
    final (p, asks, _) = await _make(launches: 1);
    for (var i = 0; i < 5; i++) {
      await p.photoDone();
    }
    expect(asks, isEmpty);
  });

  test('held back right after an error', () async {
    var clock = DateTime(2026, 11, 7, 12);
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
