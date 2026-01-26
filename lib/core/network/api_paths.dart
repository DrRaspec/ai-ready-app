class ApiPaths {
  static const String apiVersion = '/api/v1';

  // Auth
  static const String auth = '$apiVersion/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String me = '$auth/me';

  // AI Chat
  static const String ai = '/ai';
  static const String chat = '$ai/chat';
  static String chatWithConversation(String conversationId) =>
      '$ai/chat/$conversationId';

  // Conversations
  static const String conversations = '$ai/conversations';
  static String conversationMessages(String conversationId) =>
      '$ai/conversations/$conversationId/messages';
  static String conversation(String conversationId) =>
      '$ai/conversations/$conversationId';

  // Usage
  static const String usage = '$ai/usage';

  // Health
  static const String health = '/health';
}
