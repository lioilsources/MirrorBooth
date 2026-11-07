import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/services/deep_link.dart';

MirrorFilter? _filter(String link) => DeepLink.parse(Uri.parse(link)).filter;

void main() {
  test('collections open on their first filter', () {
    expect(_filter('mirrorbooth://collection/art'), MirrorFilter.pencil);
    expect(_filter('mirrorbooth://collection/fantasy'), MirrorFilter.vampire);
    expect(_filter('https://olin.now/mirror/collection/ugly'),
        MirrorFilter.bigNose);
  });

  test('filters by name, in any spelling', () {
    expect(_filter('mirrorbooth://f/vampire'), MirrorFilter.vampire);
    expect(_filter('https://olin.now/mirror/f/pop-art'), MirrorFilter.popArt);
    expect(_filter('mirrorbooth://filter/BIG_NOSE'), MirrorFilter.bigNose);
  });

  test('events map to their filter', () {
    expect(_filter('mirrorbooth://event/holiday'), MirrorFilter.frozen);
    expect(_filter('https://olin.now/mirror/event/valentine'),
        MirrorFilter.lips);
  });

  test('anything unknown just opens the camera', () {
    for (final link in [
      'mirrorbooth://',
      'mirrorbooth://camera',
      'mirrorbooth://event/unknown-event',
      'mirrorbooth://collection/nope',
      'mirrorbooth://f/none',
      'mirrorbooth://what/ever/else',
      'https://olin.now/mirror',
      'https://example.com/mirror/f/vampire',
      'mailto:someone@example.com',
    ]) {
      expect(_filter(link), isNull, reason: link);
    }
  });
}
