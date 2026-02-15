class ApiPaths {
  static const String apiVersion = '/api/v1';

  // Auth
  static const String auth = '$apiVersion/auth';
  static const String login = '$auth/login';
  static const String googleLogin = '$auth/google';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String logoutAll = '$auth/logout-all';
  static const String refreshToken = '$auth/refresh';
  static const String me = '$auth/me';

  // Sessions
  static const String sessions = '$apiVersion/sessions';
  static String session(String id) => '$sessions/$id';
  static const String sessionsAllOthers = '$sessions/all-others';

  // AI Chat
  static const String ai = '$apiVersion/ai';
  static const String smart = '$ai/smart';
  static String smartWithConversation(String conversationId) =>
      '$smart/$conversationId';

  static const String chat = '$ai/chat';
  static String chatWithConversation(String conversationId) =>
      '$chat/$conversationId';
  static const String voiceChat = '$ai/voice-chat';
  static const String visionChat = '$ai/vision-chat';
  static String visionChatWithConversation(String conversationId) =>
      '$visionChat/$conversationId';

  // Streaming
  static const String streamChat = '$ai/stream';
  static const String stream = streamChat; // Backward-compatible alias
  static String streamChatWithConversation(String conversationId) =>
      '$streamChat/$conversationId';

  // Images
  static const String generateImage = '$ai/images/generate';
  static const String editImage = '$ai/images/edit';

  // AI Conversations
  static const String conversations = '$ai/conversations';
  static const String conversationsSearch = '$conversations/search';
  static String messages(String conversationId) =>
      '$conversations/$conversationId/messages';
  static String editMessage(String conversationId, String messageId) =>
      '${messages(conversationId)}/$messageId';
  static String conversation(String conversationId) =>
      '$conversations/$conversationId';
  static String conversationFolder(String conversationId) =>
      '${conversation(conversationId)}/folder';

  // Advanced conversation routes (no /ai segment)
  static String regenerate(String conversationId) =>
      '$apiVersion/conversations/$conversationId/regenerate';
  static String summary(String conversationId) =>
      '$apiVersion/conversations/$conversationId/summary';
  static String shareConversation(String conversationId) =>
      '$apiVersion/conversations/$conversationId/share';
  static String sharedConversation(String token) => '$apiVersion/shared/$token';

  // Message feedback
  static String feedback(String messageId) =>
      '$apiVersion/messages/$messageId/feedback';

  // Search
  static const String search = '$apiVersion/search';
  static const String searchNeedsSearch = '$search/needs-search';

  // Usage and analytics
  static const String usage = '$ai/usage';
  static const String analyticsUsage = '$apiVersion/analytics/usage';

  // Prompt Templates
  static const String promptTemplates = '$apiVersion/prompt-templates';
  static String promptTemplate(String id) => '$promptTemplates/$id';
  static const String promptTemplatesSearch = '$promptTemplates/search';

  // AI Prompts
  static const String prompts = '$ai/prompts';
  static String prompt(String id) => '$prompts/$id';
  static const String enhancePrompt = '$prompts/enhance';

  // Favorites
  static const String favorites = '$apiVersion/favorites';
  static const String favoritesToggle = '$favorites/toggle';

  // User Profile
  static const String user = '$apiVersion/user';
  static const String profile = '$user/profile';
  static const String profilePicture = '$user/profile-picture';
  static const String userStats = '$user/stats';

  // Folders
  static const String folders = '$apiVersion/folders';
  static String folder(String id) => '$folders/$id';

  // User Preferences
  static const String preferences = '$apiVersion/users/me/preferences';

  // Gamification
  static const String gamificationStatus = '$apiVersion/gamification/status';

  // Health
  static const String health = '/health';
  static const String healthLive = '/health/live';
  static const String healthReady = '/health/ready';
}
