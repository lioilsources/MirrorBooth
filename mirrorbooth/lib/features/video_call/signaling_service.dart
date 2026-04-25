import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef JsonMap = Map<String, dynamic>;

class SignalingService {
  final String serverUrl;
  late final io.Socket _socket;

  final _onPeerJoined = StreamController<String>.broadcast();
  final _onOffer = StreamController<JsonMap>.broadcast();
  final _onAnswer = StreamController<JsonMap>.broadcast();
  final _onIce = StreamController<JsonMap>.broadcast();
  final _onPeerLeft = StreamController<String>.broadcast();

  Stream<String> get onPeerJoined => _onPeerJoined.stream;
  Stream<JsonMap> get onOffer => _onOffer.stream;
  Stream<JsonMap> get onAnswer => _onAnswer.stream;
  Stream<JsonMap> get onIce => _onIce.stream;
  Stream<String> get onPeerLeft => _onPeerLeft.stream;

  SignalingService({required this.serverUrl});

  void connect() {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.on('peer_joined', (data) => _onPeerJoined.add(data['peerId'] as String));
    _socket.on('offer', (data) => _onOffer.add(Map<String, dynamic>.from(data as Map)));
    _socket.on('answer', (data) => _onAnswer.add(Map<String, dynamic>.from(data as Map)));
    _socket.on('ice', (data) => _onIce.add(Map<String, dynamic>.from(data as Map)));
    _socket.on('peer_left', (data) => _onPeerLeft.add(data['peerId'] as String));
  }

  void joinRoom(String roomId, String userId) {
    _socket.emit('join_room', {'roomId': roomId, 'userId': userId});
  }

  void sendOffer(String targetId, Map<String, dynamic> sdp) {
    _socket.emit('offer', {'targetId': targetId, 'sdp': sdp});
  }

  void sendAnswer(String targetId, Map<String, dynamic> sdp) {
    _socket.emit('answer', {'targetId': targetId, 'sdp': sdp});
  }

  void sendIce(String targetId, Map<String, dynamic> candidate) {
    _socket.emit('ice', {'targetId': targetId, 'candidate': candidate});
  }

  void leaveRoom(String roomId) {
    _socket.emit('leave_room', {'roomId': roomId});
  }

  void dispose() {
    _socket.disconnect();
    _onPeerJoined.close();
    _onOffer.close();
    _onAnswer.close();
    _onIce.close();
    _onPeerLeft.close();
  }
}
