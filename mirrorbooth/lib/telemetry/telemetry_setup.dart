import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ol1n_telemetry/ol1n_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'telemetry_dictionary.dart';

/// `TelemetryStore` over the SharedPreferences instance the app already
/// loads in `main` (README pattern; no extra dependency).
class PrefsTelemetryStore implements TelemetryStore {
  PrefsTelemetryStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Keys the app wrote before measuring existed. Any of them means this is
/// not a new install (`days_band: pre`).
const _legacyKeys = [
  'review_launches',
  'review_photo_events',
  'review_video_saves',
  'review_prompted_version',
  'owned_collections',
];

/// Where the Play install-referrer capture (`ol1n_store_kit`
/// `Ol1nAttribution`) keeps the campaign of this install. Read only; the
/// capture itself makes no network call, and neither does this.
const kCampaignPrefsKey = 'ol1n_campaign';

/// Cached paid collections, written by `EntitlementController`.
const _ownedKey = 'owned_collections';

/// The app's language as MaterialApp resolves it from the system locales.
String currentLang() => telemetryLocaleId(
  basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  ),
);

/// Starts measuring. Must run before anything else writes SharedPreferences
/// on this launch, so the legacy check sees the state from before it.
/// Without TELEMETRY_KEY and TELEMETRY_HOST this does nothing at all.
void startTelemetry(
  SharedPreferences prefs, {
  FutureOr<String?> Function()? campaign,
}) {
  final hadData = _legacyKeys.any(prefs.containsKey);
  unawaited(
    Telemetry.init(
      app: kTelemetryApp,
      appVersion: kAppVersion,
      dictionary: appDictionary,
      store: PrefsTelemetryStore(prefs),
      lang: currentLang,
      tester: kTesterBuild,
      hadDataBefore: () => hadData,
      common: () => {
        'buyer': (prefs.getStringList(_ownedKey) ?? const []).isNotEmpty,
      },
      campaign: campaign ?? () => prefs.getString(kCampaignPrefsKey),
    ),
  );
}
