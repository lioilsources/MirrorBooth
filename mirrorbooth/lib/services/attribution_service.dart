import 'dart:io';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:flutter/foundation.dart';
import 'package:ol1n_store_kit/ol1n_store_kit.dart';

/// Reads the QR/campaign source once, on first launch, and stores it locally
/// (anonymous aggregate; no identifiers). Android: Play install referrer
/// (`utm_campaign`). iOS: the App Store gives no referrer to the app, so
/// attribution there comes from the Custom Product Page / `ct=` in App Analytics.
class AttributionService {
  static Future<String?> captureOnFirstOpen() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await Ol1nAttribution.captureOnFirstOpen(() async {
        final d = await AndroidPlayInstallReferrer.installReferrer;
        return d.installReferrer;
      });
    } catch (e) {
      debugPrint('attribution: $e');
      return null;
    }
  }
}
