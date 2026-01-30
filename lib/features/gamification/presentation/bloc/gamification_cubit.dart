import 'package:ai_chat_bot/features/gamification/data/gamification_repository.dart';
import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;
  final SharedPreferences _prefs;
  static const String _unlockedIdsKey = 'unlocked_achievement_ids';
  Set<String> _unlockedIds = {};

  GamificationCubit(this._repository, this._prefs)
    : super(GamificationInitial()) {
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
      emit(GamificationLoading());
    }

    try {
      final response = await _repository.getStatus();
      final status = response.data;

      if (status == null) {
        emit(const GamificationError('Failed to load status'));
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

      emit(GamificationLoaded(status, newUnlocks: newUnlocks));
    } catch (e) {
      emit(GamificationError(e.toString()));
    }
  }
}
