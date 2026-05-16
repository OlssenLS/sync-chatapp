class Constants {
  static const String serverDomain = "sync-chatapp-production.up.railway.app";

  // Base URLs
  static const String apiBaseUrl = "https://$serverDomain";
  static const String wsBaseUrl = "wss://$serverDomain";

  // Specific Endpoints
  static const String authUrl = "$apiBaseUrl/auth";
  static const String chatUrl = "$apiBaseUrl/chat";
  static const String wsChatUrl = "$wsBaseUrl/chat/ws";
}
