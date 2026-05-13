import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8080/auth"; // 10.0.2.2 is localhost for Android Emulator

  static Future<Map<String, dynamic>> register(String email, String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "identifier": identifier,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }
}
