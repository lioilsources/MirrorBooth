import 'package:flutter/services.dart';

/// Native introspection of camera hardware capabilities (lens count, physical
/// lens types, zoom switch-over points). Used only for diagnostics — the
/// actual zoom is driven by the cross-platform `camera` plugin's min/max zoom.
class CameraInfoService {
  static const MethodChannel _channel = MethodChannel('mirrorbooth/camera_info');

  /// Returns a map with `"front"` and `"back"` keys, each holding a list of
  /// per-device lens descriptions. Returns `null` when the native side is
  /// unavailable (e.g., older OS, missing plugin registration).
  static Future<Map<String, dynamic>?> getLensInfo() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getLensInfo');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
