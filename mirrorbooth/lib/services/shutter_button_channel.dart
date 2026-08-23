import 'package:flutter/services.dart';

import '../core/constants.dart';

/// Hardware shutter press reported by the native side.
enum ShutterPress {
  /// Quick tap — take a photo.
  short,

  /// Held down — toggle video recording.
  long,
}

/// Volume-button (and, on iOS, Action button / Camera Control) shutter.
///
/// Native side only claims the keys while [setEnabled] is true, so the volume
/// keys keep their normal function everywhere else in the app.
class ShutterButtonChannel {
  static const _method = MethodChannel(kMethodChannelShutter);
  static const _events = EventChannel(kEventChannelShutterEvents);

  static Stream<ShutterPress>? _presses;

  /// Broadcast stream of hardware shutter presses.
  static Stream<ShutterPress> get presses => _presses ??= _events
      .receiveBroadcastStream()
      .map((event) => (event is Map && event['long'] == true)
          ? ShutterPress.long
          : ShutterPress.short);

  /// Whether this platform can deliver hardware shutter events at all
  /// (iOS 17.2+ / Android). Failures are reported as unsupported.
  static Future<bool> isSupported() async {
    try {
      return await _method.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Starts or stops claiming the volume keys.
  static Future<void> setEnabled(bool enabled) async {
    try {
      await _method.invokeMethod('setEnabled', {'enabled': enabled});
    } on PlatformException {
      // Non-fatal: on-screen buttons keep working.
    } on MissingPluginException {
      // Platform without the plugin (e.g. desktop builds).
    }
  }
}
