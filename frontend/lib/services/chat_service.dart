import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChatService {
  static String get baseUrl => Constants.chatUrl;

  static Future<List<dynamic>> getChatHistory(String senderId, String receiverId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/history?sender_id=$senderId&receiver_id=$receiverId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      log("Error fetching history: $e");
    }
    return [];
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/search?q=$query"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      log("Error searching users: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getActiveConversations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/conversations?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      log("Error fetching conversations: $e");
    }
    return [];
  }
}
