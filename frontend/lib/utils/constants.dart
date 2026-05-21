import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class Constants {
  static const String computerIp = "10.38.50.139";
  static const String emulatorIp = "10.0.2.2";
  static const String port = "8080";

  static String _serverDomain = "$computerIp:$port";

  // Initialize dynamic domain detection
  static Future<void> init() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      
      // Check if running on an emulator
      if (!androidInfo.isPhysicalDevice) {
        _serverDomain = "$emulatorIp:$port";
      } else {
        _serverDomain = "$computerIp:$port";
      }
    } else if (Platform.isIOS) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      
      if (!iosInfo.isPhysicalDevice) {
        _serverDomain = "localhost:$port";
      } else {
        _serverDomain = "$computerIp:$port";
      }
    } else {
      // Default for Web/Desktop
      _serverDomain = "localhost:$port";
    }
  }

  static String get serverDomain => _serverDomain;

  // Base URLs
  static String get apiBaseUrl => "http://$serverDomain";
  static String get wsBaseUrl => "ws://$serverDomain";

  // Specific Endpoints
  static String get authUrl => "$apiBaseUrl/auth";
  static String get chatUrl => "$apiBaseUrl/chat";
  static String get wsChatUrl => "$wsBaseUrl/chat/ws";
}
