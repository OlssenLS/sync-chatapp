import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String wsUrl = "ws://10.0.2.2:8080/chat/ws";
  WebSocketChannel? _channel;

  void connect(String userId) {
    _channel = WebSocketChannel.connect(
      Uri.parse("$wsUrl?user_id=$userId"),
    );
  }

  Stream get messages => _channel!.stream;

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
