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

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      log("Error fetching all users: $e");
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

  static Future<bool> markAsRead(String senderId, String receiverId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/read"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId,
          "receiver_id": receiverId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      log("Error marking as read: $e");
      return false;
    }
  }

  static Future<bool> updateFCMToken(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "token": token,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      log("Error updating FCM token: $e");
      return false;
    }
  }
}
