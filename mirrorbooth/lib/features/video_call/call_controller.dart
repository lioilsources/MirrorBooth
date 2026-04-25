import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/mirror_side.dart';
import '../../services/webrtc_service.dart';
import 'signaling_service.dart';

enum CallStatus { idle, connecting, connected, ended }

class CallState {
  final CallStatus status;
  final String roomId;
  final MirrorSide side;
  final String? error;

  const CallState({
    this.status = CallStatus.idle,
    this.roomId = '',
    this.side = MirrorSide.left,
    this.error,
  });

  CallState copyWith({
    CallStatus? status,
    String? roomId,
    MirrorSide? side,
    String? error,
  }) =>
      CallState(
        status: status ?? this.status,
        roomId: roomId ?? this.roomId,
        side: side ?? this.side,
        error: error ?? this.error,
      );
}

// TODO: Replace with your deployed signaling server URL
const _signalingServerUrl = 'http://localhost:3000';

class CallController extends StateNotifier<CallState> {
  final WebRtcService _webRtc = WebRtcService();
  late final SignalingService _signaling;
  final List<StreamSubscription<dynamic>> _subs = [];
  late String _myId;
  String? _peerId;

  CallController() : super(const CallState()) {
    _myId = _randomId();
    _signaling = SignalingService(serverUrl: _signalingServerUrl);
    _signaling.connect();
    _listenSignaling();
  }

  WebRtcService get webRtc => _webRtc;

  String _randomId() =>
      List.generate(8, (_) => Random().nextInt(16).toRadixString(16)).join();

  void _listenSignaling() {
    _subs.add(_signaling.onPeerJoined.listen(_onPeerJoined));
    _subs.add(_signaling.onOffer.listen(_onOffer));
    _subs.add(_signaling.onAnswer.listen(_onAnswer));
    _subs.add(_signaling.onIce.listen(_onIce));
    _subs.add(_signaling.onPeerLeft.listen(_onPeerLeft));
  }

  Future<void> joinCall(String roomId, MirrorSide side) async {
    state = state.copyWith(status: CallStatus.connecting, roomId: roomId, side: side);
    await _webRtc.init(side);
    await _webRtc.setupPeerConnection();

    _webRtc.peerConnection.onIceCandidate = (candidate) {
      if (_peerId != null) {
        _signaling.sendIce(_peerId!, candidate.toMap());
      }
    };

    _signaling.joinRoom(roomId, _myId);
  }

  Future<void> _onPeerJoined(String peerId) async {
    _peerId = peerId;
    // We are the offerer
    final offer = await _webRtc.peerConnection.createOffer();
    await _webRtc.peerConnection.setLocalDescription(offer);
    _signaling.sendOffer(peerId, offer.toMap());
    state = state.copyWith(status: CallStatus.connected);
  }

  Future<void> _onOffer(Map<String, dynamic> data) async {
    _peerId = data['fromId'] as String;
    final sdp = data['sdp'] as Map<String, dynamic>;
    await _webRtc.peerConnection
        .setRemoteDescription(RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String));
    final answer = await _webRtc.peerConnection.createAnswer();
    await _webRtc.peerConnection.setLocalDescription(answer);
    _signaling.sendAnswer(_peerId!, answer.toMap());
    state = state.copyWith(status: CallStatus.connected);
  }

  Future<void> _onAnswer(Map<String, dynamic> data) async {
    final sdp = data['sdp'] as Map<String, dynamic>;
    await _webRtc.peerConnection
        .setRemoteDescription(RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String));
  }

  Future<void> _onIce(Map<String, dynamic> data) async {
    final c = data['candidate'] as Map<String, dynamic>;
    await _webRtc.peerConnection.addCandidate(RTCIceCandidate(
      c['candidate'] as String,
      c['sdpMid'] as String?,
      c['sdpMLineIndex'] as int?,
    ));
  }

  void _onPeerLeft(String peerId) {
    if (peerId == _peerId) {
      state = state.copyWith(status: CallStatus.ended);
    }
  }

  void toggleSide() {
    final newSide = state.side.toggled;
    state = state.copyWith(side: newSide);
    _webRtc.updateMirrorSide(newSide);
  }

  Future<void> endCall() async {
    _signaling.leaveRoom(state.roomId);
    await _webRtc.dispose();
    state = state.copyWith(status: CallStatus.ended);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _signaling.dispose();
    _webRtc.dispose();
    super.dispose();
  }
}

final callProvider = StateNotifierProvider.autoDispose<CallController, CallState>(
  (_) => CallController(),
);
