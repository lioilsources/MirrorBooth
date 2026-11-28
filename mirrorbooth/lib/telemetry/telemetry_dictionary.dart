import 'package:ol1n_telemetry/ol1n_telemetry.dart';

import '../core/mirror_filter.dart';
import '../features/video_recording/video_recording_state.dart';
import '../l10n/app_localizations.dart';

/// The app version this build reports; `test/telemetry_test.dart` keeps it
/// equal to `version:` in `pubspec.yaml`.
const kAppVersion = '2.5.0';

/// The app id in StoreMetrics `apps.yaml`.
const kTelemetryApp = 'mirrorbooth';

/// TestFlight lab builds (`--dart-define=MB_LAB=true`) report `tester: true`.
const kTesterBuild = bool.fromEnvironment('MB_LAB');

/// Route name → screen. The playback screen and the paywall sheet are not
/// routes; they report themselves with `Telemetry.screen`.
const kScreenRoutes = {'/': 'camera', '/call': 'call'};

/// Screens reported by hand.
const kScreenPlayback = 'playback';
const kScreenPaywall = 'paywall';

/// Collection → feature for `feature_use` / `feature_snapshot`. Packs share
/// one feature, as they share one tab; the Lab collection is not counted.
String? collectionFeature(FilterCollection? c) => switch (c) {
  FilterCollection.pretty => 'col_pretty',
  FilterCollection.ugly => 'col_ugly',
  FilterCollection.art => 'col_art',
  FilterCollection.fantasy => 'col_fantasy',
  FilterCollection.experimental || null => null,
  _ => 'col_packs',
};

/// Collection value for events: the enum name, or `none` without a filter.
String collectionValue(FilterCollection? c) => c?.name ?? 'none';

/// Error kinds the user can see (`error_shown.kind`).
const kErrorKinds = {
  'camera_denied',
  'camera_missing',
  'camera_failed',
  'photo_failed',
  'gallery_denied',
  'gallery_space',
  'gallery_format',
  'mic_denied',
  'video_short',
  'video_failed',
  'audio_effect',
  'share_failed',
  'purchase_failed',
};

String recordingErrorKind(RecordingError e) => switch (e) {
  RecordingError.micPermission => 'mic_denied',
  RecordingError.tooShort => 'video_short',
  RecordingError.assemblyFailed => 'video_failed',
  RecordingError.audioEffectFailed => 'audio_effect',
  RecordingError.galleryAccessDenied => 'gallery_denied',
  RecordingError.galleryNotEnoughSpace => 'gallery_space',
  RecordingError.galleryUnsupportedFormat => 'gallery_format',
  RecordingError.unexpected => 'video_failed',
};

final _collections = {for (final c in FilterCollection.values) c.name, 'none'};

final _paidCollections = {
  for (final c in FilterCollection.values)
    if (c.isPaid) c.name,
};

const _saveResults = {'denied', 'no_space'};

/// The one event dictionary of MirrorBooth, mirrored in `docs/telemetry.md`.
/// No property describes what is in a photo or a video: only which filter,
/// collection or audio effect was on, counts, and outcomes.
final appDictionary = TelemetryDictionary(
  appVersion: kAppVersion,
  languages: {
    for (final l in AppLocalizations.supportedLocales) telemetryLocaleId(l),
  },
  screens: {...kScreenRoutes.values, kScreenPlayback, kScreenPaywall},
  features: {
    'col_pretty',
    'col_ugly',
    'col_art',
    'col_fantasy',
    'col_packs',
    'video',
    'audio_effect',
    'rotate',
    'mirror_axis',
    'side_toggle',
    'lens_toggle',
    'volume_shutter',
  },
  errorKinds: kErrorKinds,
  lockedTargets: _paidCollections,
  common: {'buyer': const BoolProp()},
  events: {
    'filter_select': {
      'filter': EnumProp({for (final f in MirrorFilter.values) f.name}),
      'collection': EnumProp(_collections),
      'locked': const BoolProp(),
    },
    'link_open': {'filter': const BoolProp()},
    ...TelemetryDictionary.flow(
      'photo_save',
      results: _saveResults,
      start: {'collection': EnumProp(_collections)},
      end: {'fallback': const BoolProp()},
    ),
    ...TelemetryDictionary.flow(
      'video_record',
      results: {'denied', 'short'},
      start: {'collection': EnumProp(_collections)},
    ),
    ...TelemetryDictionary.flow(
      'video_save',
      results: _saveResults,
      start: {
        'effect': EnumProp({for (final e in AudioEffect.values) e.name}),
      },
    ),
    ...TelemetryDictionary.flow(
      'share',
      results: {'unknown'},
      start: {
        'media': const EnumProp({'photo', 'video'}),
      },
    ),
    ...TelemetryDictionary.flow(
      'purchase',
      start: {
        'item': EnumProp({..._paidCollections, 'bundle'}),
        'source': const EnumProp({'paywall', 'store_page'}),
      },
    ),
  },
);

/// `share_end.result` for a share sheet outcome. Android rarely knows what
/// the user did and reports `unavailable`.
String shareResult(String status) => switch (status) {
  'success' => 'ok',
  'dismissed' => 'cancel',
  _ => 'unknown',
};
