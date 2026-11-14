// The checks every measured app carries (ol1n_telemetry README,
// "Testovací sada"): dictionary ↔ doc, no free text, version constant ↔
// pubspec, literal event names, no key → no network, off → nothing.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/video_recording/video_recording_state.dart';
import 'package:mirrorbooth/telemetry/telemetry_dictionary.dart';
import 'package:ol1n_telemetry/testing.dart';

// docs/ sits next to the Flutter root (GitHub Pages serves it).
const _doc = '../docs/telemetry.md';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('docs/telemetry.md lists exactly the dictionary', () {
    expect(
      telemetryDocProblems(appDictionary, File(_doc).readAsStringSync()),
      isEmpty,
    );
  });

  test('no property is free text', () {
    expect(telemetryDictionaryProblems(appDictionary), isEmpty);
  });

  test('app version matches pubspec.yaml', () {
    expect(
      telemetryVersionProblems(
        kAppVersion,
        File('pubspec.yaml').readAsStringSync(),
      ),
      isEmpty,
    );
  });

  test('the code sends only dictionary events, and every one of them', () {
    expect(telemetryTrackCallProblems(appDictionary), isEmpty);
  });

  test('no key, no network', () async {
    expect(
      await telemetryNoKeyProblems(
        appDictionary,
        common: () => {'buyer': false},
      ),
      isEmpty,
    );
  }, skip: const bool.fromEnvironment('TELEMETRY_DEBUG'));

  test('off means nothing', () async {
    expect(
      await telemetryOffProblems(appDictionary, common: () => {'buyer': false}),
      isEmpty,
    );
  });

  test('every catalogue value fits the dictionary', () {
    for (final f in MirrorFilter.values) {
      expect(
        appDictionary.valid('filter_select', {
          ...telemetrySampleProps(appDictionary, 'filter_select'),
          'filter': f.name,
          'collection': collectionValue(f.collection),
          'locked': false,
        }),
        isTrue,
        reason: '$f',
      );
    }
    for (final e in RecordingError.values) {
      expect(kErrorKinds, contains(recordingErrorKind(e)), reason: '$e');
    }
    for (final c in FilterCollection.values) {
      final feature = collectionFeature(c);
      if (feature != null) {
        expect(appDictionary.features, contains(feature), reason: '$c');
      }
    }
    for (final s in ['success', 'dismissed', 'unavailable']) {
      expect(
        appDictionary.valid('share_end', {
          ...telemetrySampleProps(appDictionary, 'share_end'),
          'result': shareResult(s),
          'secs': 1,
        }),
        isTrue,
      );
    }
  });
}
