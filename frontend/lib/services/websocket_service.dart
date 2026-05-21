import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

class WebSocketService {
  static String get wsUrl => Constants.wsChatUrl;
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;

  void connect(String userId) {
    if (_channel != null) {
      log("WebSocket already connected, skipping.");
      return;
    }

    log("Connecting WebSocket for user: $userId");
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?user_id=$userId"),
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _messageController.add(data);
        },
        onError: (error) {
          log("WebSocket Error: $error");
          _channel = null;
          reconnect(userId);
        },
        onDone: () {
          log("WebSocket Closed");
          _channel = null;
          reconnect(userId);
        },
      );
    } catch (e) {
      log("WebSocket Connection Exception: $e");
      _channel = null;
      reconnect(userId);
    }
  }

  void sendMessage(String receiverId, String content) {
    if (_channel != null) {
      final msg = {
        "type": "chat",
        "receiver_id": receiverId,
        "content": content,
      };
      _channel!.sink.add(jsonEncode(msg));
    }
  }

  void reconnect(String userId) {
    Future.delayed(const Duration(seconds: 5), () => connect(userId));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
