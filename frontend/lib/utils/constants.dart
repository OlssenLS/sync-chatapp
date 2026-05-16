class Constants {
  // TODO: Replace with  actual Render URL after deployment
  static const String serverDomain = "RENDER_URL.onrender.com";

  // Base URLs
  static const String apiBaseUrl = "https://$serverDomain";
  static const String wsBaseUrl = "wss://$serverDomain";

  // Specific Endpoints
  static const String authUrl = "$apiBaseUrl/auth";
  static const String chatUrl = "$apiBaseUrl/chat";
  static const String wsChatUrl = "$wsBaseUrl/chat/ws";
}
