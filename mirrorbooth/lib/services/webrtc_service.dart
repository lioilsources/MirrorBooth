import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/mirror_side.dart';
import 'mirror_channel.dart';

const _iceConfig = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    // Add TURN credentials here for production:
    // {'urls': 'turn:your-turn.example.com:3478', 'username': '...', 'credential': '...'},
  ],
  'sdpSemantics': 'unified-plan',
};

class WebRtcService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  final _onRemoteStream = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onRemoteStream => _onRemoteStream.stream;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  Future<void> init(MirrorSide side) async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      },
      'audio': true,
    });

    _localRenderer.srcObject = _localStream;

    // Tell native layer to apply mirror transform before encoding
    await MirrorChannel.setEnabled(true);
    await MirrorChannel.setMirrorSide(side);
  }

  Future<RTCPeerConnection> setupPeerConnection() async {
    _pc = await createPeerConnection(_iceConfig);

    _localStream?.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        _onRemoteStream.add(event.streams.first);
      }
    };

    return _pc!;
  }

  RTCPeerConnection get peerConnection => _pc!;

  void updateMirrorSide(MirrorSide side) {
    MirrorChannel.setMirrorSide(side);
  }

  Future<void> dispose() async {
    await MirrorChannel.setEnabled(false);
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    await _pc?.close();
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    await _onRemoteStream.close();
  }
}
