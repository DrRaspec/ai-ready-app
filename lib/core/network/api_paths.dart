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
  static const String smart = '$ai/smart';
  static String smartWithConversation(String conversationId) =>
      '$ai/smart/$conversationId';
  static const String stream = '$ai/stream';

  static const String chat = '$ai/chat';
  static const String voiceChat = '$ai/voice-chat';
  static const String visionChat = '$ai/vision-chat';
  static const String generateImage = '$ai/images/generate';
  static const String editImage = '$ai/images/edit';
  static const String enhancePrompt = '$ai/prompts/enhance';
  static String chatWithConversation(String conversationId) =>
      '$ai/chat/$conversationId';
  static String visionChatWithConversation(String conversationId) =>
      '$ai/vision-chat/$conversationId';

  // Conversations
  static const String conversations = '$ai/conversations';
  static String messages(String conversationId) =>
      '$ai/conversations/$conversationId/messages';
  static String conversation(String conversationId) =>
      '$ai/conversations/$conversationId';
  static String regenerate(String conversationId) =>
      '$ai/conversations/$conversationId/regenerate';
  static String summary(String conversationId) =>
      '$ai/conversations/$conversationId/summary';
  static String feedback(String messageId) =>
      '$ai/messages/$messageId/feedback';
  static const String search = '$apiVersion/search';

  static String editMessage(String conversationId, String messageId) =>
      '$ai/conversations/$conversationId/messages/$messageId';
  static String shareConversation(String conversationId) =>
      '$apiVersion/conversations/$conversationId/share';

  // Usage
  static const String usage = '$ai/usage';

  // Health
  static const String health = '/health';

  // User Profile
  static const String user = '$apiVersion/user';
  static const String profile = '$user/profile';
  static const String profilePicture = '$user/profile-picture';
  static const String userStats = '$user/stats';
  // Streaming
  static const String streamChat = '$ai/stream';
  static String streamChatWithConversation(String conversationId) =>
      '$ai/stream/$conversationId';

  // Folders
  static const String folders = '$apiVersion/folders';
  static String folder(String id) => '$folders/$id';

  // Prompts
  static const String prompts = '$apiVersion/prompts';
  static String prompt(String id) => '$prompts/$id';

  // User Preferences
  static const String preferences = '$apiVersion/users/me/preferences';
}
