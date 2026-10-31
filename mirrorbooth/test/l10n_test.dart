import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/video_recording/video_recording_state.dart';
import 'package:mirrorbooth/l10n/l10n.dart';

void main() {
  test('every supported locale loads and labels every filter and effect',
      () async {
    expect(AppLocalizations.supportedLocales.length, 13);
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      for (final f in MirrorFilter.values) {
        expect(f.localizedLabel(l), isNotEmpty, reason: '$locale $f');
      }
      for (final c in FilterCollection.values) {
        expect(c.localizedLabel(l), isNotEmpty, reason: '$locale $c');
      }
      for (final e in AudioEffect.values) {
        expect(e.localizedLabel(l), isNotEmpty, reason: '$locale $e');
      }
      expect(l.unlockFor(r'$1.99'), contains(r'$1.99'));
      expect(l.shareMessage('https://x.y'), contains('https://x.y'));
    }
  });

  test('English template keeps the original labels', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    for (final f in MirrorFilter.values) {
      expect(f.localizedLabel(l), f.label, reason: '$f');
    }
  });
}
