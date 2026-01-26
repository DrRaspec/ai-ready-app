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
  static const String ai = '$apiVersion/ai';
  static const String chat = '$ai/chat';
  static const String voiceChat = '$ai/voice-chat';
  static String chatWithConversation(String conversationId) =>
      '$ai/chat/$conversationId';

  // Conversations
  static const String conversations = '$ai/conversations';
  static String conversationMessages(String conversationId) =>
      '$ai/conversations/$conversationId/messages';
  static String conversation(String conversationId) =>
      '$ai/conversations/$conversationId';
  static String editMessage(String conversationId, String messageId) =>
      '$ai/conversations/$conversationId/messages/$messageId';

  // Usage
  static const String usage = '$ai/usage';

  // Health
  static const String health = '/health';
}
