import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/mirror_side.dart';

class MirrorChannel {
  static const _channel = MethodChannel(kMethodChannelMirror);

  static Future<void> setMirrorSide(MirrorSide side) async {
    await _channel.invokeMethod('setMirrorSide', {'side': side.name});
  }

  static Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod('setEnabled', {'enabled': enabled});
  }
}
