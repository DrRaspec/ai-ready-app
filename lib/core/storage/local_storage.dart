import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for managing app-wide local data
/// Uses Hive for complex objects and SharedPreferences for simple key-values
class LocalStorage {
  static const String _bookmarksBox = 'bookmarks';
  static const String _pinnedBox = 'pinned_conversations';
  static const String _achievementsBox = 'achievements';
  static const String _settingsBox = 'settings';

  static late Box<Map> _bookmarks;
  static late Box<String> _pinned;
  static late Box<Map> _achievements;
  static late Box<dynamic> _settings;
  static late SharedPreferences _prefs;

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    _bookmarks = await Hive.openBox<Map>(_bookmarksBox);
    _pinned = await Hive.openBox<String>(_pinnedBox);
    _achievements = await Hive.openBox<Map>(_achievementsBox);
    _settings = await Hive.openBox<dynamic>(_settingsBox);
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== BOOKMARKS ====================

  /// Add a bookmarked message
  static Future<void> addBookmark({
    required String messageId,
    required String content,
    required String role,
    required String? conversationId,
    required String? conversationTitle,
  }) async {
    await _bookmarks.put(messageId, {
      'id': messageId,
      'content': content,
      'role': role,
      'conversationId': conversationId,
      'conversationTitle': conversationTitle,
      'bookmarkedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove a bookmark
  static Future<void> removeBookmark(String messageId) async {
    await _bookmarks.delete(messageId);
  }

  /// Check if a message is bookmarked
  static bool isBookmarked(String messageId) {
    return _bookmarks.containsKey(messageId);
  }

  /// Get all bookmarks
  static List<Map<dynamic, dynamic>> getAllBookmarks() {
    final bookmarks = _bookmarks.values.toList();
    bookmarks.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['bookmarkedAt'] ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['bookmarkedAt'] ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate); // Newest first
    });
    return bookmarks;
  }

  // ==================== PINNED CONVERSATIONS ====================

  /// Pin a conversation
  static Future<void> pinConversation(String conversationId) async {
    await _pinned.put(conversationId, conversationId);
  }

  /// Unpin a conversation
  static Future<void> unpinConversation(String conversationId) async {
    await _pinned.delete(conversationId);
  }

  /// Check if a conversation is pinned
  static bool isPinned(String conversationId) {
    return _pinned.containsKey(conversationId);
  }

  /// Get all pinned conversation IDs
  static Set<String> getPinnedIds() {
    return _pinned.values.toSet();
  }

  // ==================== ACHIEVEMENTS ====================

  static const Map<String, Map<String, dynamic>> achievementDefinitions = {
    'first_chat': {
      'id': 'first_chat',
      'name': 'First Steps',
      'description': 'Start your first conversation',
      'icon': 'chat_bubble',
      'requirement': 1,
      'type': 'conversations',
    },
    'ten_chats': {
      'id': 'ten_chats',
      'name': 'Getting Started',
      'description': 'Have 10 conversations',
      'icon': 'forum',
      'requirement': 10,
      'type': 'conversations',
    },
    'fifty_chats': {
      'id': 'fifty_chats',
      'name': 'Regular User',
      'description': 'Have 50 conversations',
      'icon': 'workspace_premium',
      'requirement': 50,
      'type': 'conversations',
    },
    'hundred_messages': {
      'id': 'hundred_messages',
      'name': 'Chatterbox',
      'description': 'Send 100 messages',
      'icon': 'message',
      'requirement': 100,
      'type': 'messages',
    },
    'five_hundred_messages': {
      'id': 'five_hundred_messages',
      'name': 'Power User',
      'description': 'Send 500 messages',
      'icon': 'bolt',
      'requirement': 500,
      'type': 'messages',
    },
    'bookworm': {
      'id': 'bookworm',
      'name': 'Bookworm',
      'description': 'Bookmark 10 messages',
      'icon': 'bookmark',
      'requirement': 10,
      'type': 'bookmarks',
    },
    'night_owl': {
      'id': 'night_owl',
      'name': 'Night Owl',
      'description': 'Chat after midnight',
      'icon': 'nightlight',
      'requirement': 1,
      'type': 'special',
    },
    'early_bird': {
      'id': 'early_bird',
      'name': 'Early Bird',
      'description': 'Chat before 6 AM',
      'icon': 'wb_sunny',
      'requirement': 1,
      'type': 'special',
    },
  };

  /// Unlock an achievement
  static Future<void> unlockAchievement(String achievementId) async {
    if (!_achievements.containsKey(achievementId)) {
      await _achievements.put(achievementId, {
        'id': achievementId,
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Check if achievement is unlocked
  static bool isAchievementUnlocked(String achievementId) {
    return _achievements.containsKey(achievementId);
  }

  /// Get all unlocked achievements
  static List<String> getUnlockedAchievements() {
    return _achievements.keys.cast<String>().toList();
  }

  /// Check and unlock achievements based on stats
  static Future<List<String>> checkAndUnlockAchievements({
    required int conversationCount,
    required int messageCount,
  }) async {
    final newlyUnlocked = <String>[];
    final now = DateTime.now();

    // Check conversation achievements
    if (conversationCount >= 1 && !isAchievementUnlocked('first_chat')) {
      await unlockAchievement('first_chat');
      newlyUnlocked.add('first_chat');
    }
    if (conversationCount >= 10 && !isAchievementUnlocked('ten_chats')) {
      await unlockAchievement('ten_chats');
      newlyUnlocked.add('ten_chats');
    }
    if (conversationCount >= 50 && !isAchievementUnlocked('fifty_chats')) {
      await unlockAchievement('fifty_chats');
      newlyUnlocked.add('fifty_chats');
    }

    // Check message achievements
    if (messageCount >= 100 && !isAchievementUnlocked('hundred_messages')) {
      await unlockAchievement('hundred_messages');
      newlyUnlocked.add('hundred_messages');
    }
    if (messageCount >= 500 &&
        !isAchievementUnlocked('five_hundred_messages')) {
      await unlockAchievement('five_hundred_messages');
      newlyUnlocked.add('five_hundred_messages');
    }

    // Check bookmark achievement
    if (getAllBookmarks().length >= 10 && !isAchievementUnlocked('bookworm')) {
      await unlockAchievement('bookworm');
      newlyUnlocked.add('bookworm');
    }

    // Check time-based achievements
    if (now.hour >= 0 && now.hour < 5 && !isAchievementUnlocked('night_owl')) {
      await unlockAchievement('night_owl');
      newlyUnlocked.add('night_owl');
    }
    if (now.hour >= 5 && now.hour < 6 && !isAchievementUnlocked('early_bird')) {
      await unlockAchievement('early_bird');
      newlyUnlocked.add('early_bird');
    }

    return newlyUnlocked;
  }

  // ==================== SETTINGS ====================

  /// Get custom avatar path
  static String? getAvatarPath() {
    return _settings.get('avatar_path') as String?;
  }

  /// Set custom avatar path
  static Future<void> setAvatarPath(String? path) async {
    if (path == null) {
      await _settings.delete('avatar_path');
    } else {
      await _settings.put('avatar_path', path);
    }
  }

  /// Get bubble color
  static int? getBubbleColor() {
    return _settings.get('bubble_color') as int?;
  }

  /// Set bubble color
  static Future<void> setBubbleColor(int? colorValue) async {
    if (colorValue == null) {
      await _settings.delete('bubble_color');
    } else {
      await _settings.put('bubble_color', colorValue);
    }
  }

  /// Get message stats
  static int getMessageCount() {
    return _prefs.getInt('message_count') ?? 0;
  }

  /// Increment message count
  static Future<void> incrementMessageCount() async {
    final current = getMessageCount();
    await _prefs.setInt('message_count', current + 1);
  }

  /// Clear all local data
  static Future<void> clearAll() async {
    await _bookmarks.clear();
    await _pinned.clear();
    await _achievements.clear();
    await _settings.clear();
    await _prefs.clear();
  }
}
