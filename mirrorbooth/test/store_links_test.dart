import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/store_links.dart';

void main() {
  test('App Store link carries the campaign', () {
    final uri = StoreLinks.appStore();
    expect(uri.host, 'apps.apple.com');
    expect(uri.path, '/app/id6767824892');
    expect(uri.queryParameters['ct'], 'share');
    // Optional values stay out of the link until they are filled in.
    for (final key in ['pt', 'ppid']) {
      expect(uri.queryParameters[key], isNot(''), reason: key);
    }
  });

  test('Play link carries an install referrer', () {
    final uri = StoreLinks.play();
    expect(uri.queryParameters['id'], 'com.ab.mirrorbooth');
    expect(Uri.splitQueryString(uri.queryParameters['referrer']!), {
      'utm_source': 'share',
      'utm_medium': 'app_share',
    });
  });
}
