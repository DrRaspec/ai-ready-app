import 'package:ai_chat_bot/features/gamification/data/gamification_repository.dart';
import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/presentation/controllers/gamification_state.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationController extends GetxController {
  final GamificationRepository _repository;
  final SharedPreferences _prefs;
  static const String _unlockedIdsKey = 'unlocked_achievement_ids';
  Set<String> _unlockedIds = {};
  final Rx<GamificationState> rxState;

  GamificationState get state => rxState.value;

  void _setState(GamificationState newState) {
    rxState.value = newState;
  }

  GamificationController(this._repository, this._prefs)
    : rxState = GamificationInitial().obs {
    _loadLocalCache();
  }

  void _loadLocalCache() {
    final List<String>? cached = _prefs.getStringList(_unlockedIdsKey);
    if (cached != null) {
      _unlockedIds = cached.toSet();
    }
  }

  Future<void> checkStatus() async {
    // If we haven't loaded, invoke loading state (optional, maybe keep previous data to avoid flickering)
    if (state is GamificationInitial) {
      _setState(GamificationLoading());
    }

    try {
      final response = await _repository.getStatus();
      final status = response.data;

      if (status == null) {
        _setState(const GamificationError('Failed to load status'));
        return;
      }

      final List<Achievement> newUnlocks = [];
      final Set<String> currentUnlocked = {};

      for (var ach in status.achievements) {
        if (ach.isUnlocked) {
          currentUnlocked.add(ach.id);
          if (!_unlockedIds.contains(ach.id)) {
            newUnlocks.add(ach);
            _unlockedIds.add(ach.id);
          }
        }
      }

      // Persist if new unlocks found
      if (newUnlocks.isNotEmpty) {
        await _prefs.setStringList(_unlockedIdsKey, _unlockedIds.toList());
      }

      _setState(GamificationLoaded(status, newUnlocks: newUnlocks));
    } catch (e) {
      _setState(GamificationError(e.toString()));
    }
  }
}
