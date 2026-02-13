import 'package:shared_preferences/shared_preferences.dart';

class UnlockedAchievementsStore {
  static const String _unlockedIdsKey = 'unlocked_achievement_ids';
  final SharedPreferences _prefs;

  UnlockedAchievementsStore(this._prefs);

  Set<String> loadUnlockedIds() {
    return _prefs.getStringList(_unlockedIdsKey)?.toSet() ?? <String>{};
  }

  Future<void> saveUnlockedIds(Set<String> unlockedIds) {
    return _prefs.setStringList(_unlockedIdsKey, unlockedIds.toList());
  }

  Future<void> clear() {
    return _prefs.remove(_unlockedIdsKey);
  }
}
