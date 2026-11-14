import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/paywall/entitlement_controller.dart';

/// Asks for a store rating at a happy moment: the 3rd saved or shared photo,
/// or the first saved or shared video. At most once per app version, only
/// once the app has been opened on [minLaunches] starts over at least
/// [minAge] since the first one (App Review 5.6.3: never on first launch or
/// during onboarding, so a fresh install never sees it), and never right
/// after an error. The system decides whether
/// the dialog really shows (Apple: 3 times a year; Play: its own quota), so
/// there is no "Rate us?" question first and no button that calls this.
class ReviewPrompter {
  static const photosForPrompt = 3;
  static const errorCooldown = Duration(seconds: 30);
  static const minLaunches = 3;
  static const minAge = Duration(days: 3);

  static const _kLaunches = 'review_launches';
  static const _kFirstLaunch = 'review_first_launch_ms';
  static const _kPhotos = 'review_photo_events';
  static const _kVideos = 'review_video_saves';
  static const _kPromptedVersion = 'review_prompted_version';

  final SharedPreferences _prefs;
  final Future<String> Function() _appVersion;
  final Future<bool> Function() _request;
  final DateTime Function() _now;
  DateTime? _lastError;

  ReviewPrompter(
    this._prefs, {
    Future<String> Function()? appVersion,
    Future<bool> Function()? request,
    DateTime Function()? now,
  })  : _appVersion = appVersion ?? _platformVersion,
        _request = request ?? _systemRequest,
        _now = now ?? DateTime.now;

  /// Call once per app start.
  void recordLaunch() {
    _prefs.setInt(_kLaunches, (_prefs.getInt(_kLaunches) ?? 0) + 1);
    if (_prefs.getInt(_kFirstLaunch) == null) {
      _prefs.setInt(_kFirstLaunch, _now().millisecondsSinceEpoch);
    }
  }

  /// A photo was saved to the gallery or shared.
  Future<bool> photoDone() {
    _prefs.setInt(_kPhotos, (_prefs.getInt(_kPhotos) ?? 0) + 1);
    return _maybePrompt();
  }

  /// A video was saved to the gallery or shared.
  Future<bool> videoDone() {
    _prefs.setInt(_kVideos, (_prefs.getInt(_kVideos) ?? 0) + 1);
    return _maybePrompt();
  }

  /// Something failed; holds the prompt back for [errorCooldown].
  void errorShown() => _lastError = _now();

  /// Returns true when the system was asked to show the dialog.
  Future<bool> _maybePrompt() async {
    if ((_prefs.getInt(_kLaunches) ?? 0) < minLaunches) return false;
    final first = _prefs.getInt(_kFirstLaunch);
    if (first == null) return false;
    final since = _now().difference(DateTime.fromMillisecondsSinceEpoch(first));
    if (since < minAge) return false;
    final error = _lastError;
    if (error != null && _now().difference(error) < errorCooldown) return false;
    final happy = (_prefs.getInt(_kPhotos) ?? 0) >= photosForPrompt ||
        (_prefs.getInt(_kVideos) ?? 0) >= 1;
    if (!happy) return false;
    final version = await _appVersion();
    if (_prefs.getString(_kPromptedVersion) == version) return false;
    // Recorded before asking: a dialog the system swallows still counts.
    await _prefs.setString(_kPromptedVersion, version);
    return _request();
  }

  static Future<String> _platformVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static Future<bool> _systemRequest() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      return true;
    } catch (e) {
      debugPrint('in-app review: $e');
      return false;
    }
  }
}

final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => ReviewPrompter(ref.watch(sharedPreferencesProvider)),
);
