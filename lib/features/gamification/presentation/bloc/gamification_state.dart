import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/data/models/gamification_status.dart';
import 'package:equatable/equatable.dart';

abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {}

class GamificationLoading extends GamificationState {}

class GamificationLoaded extends GamificationState {
  final GamificationStatus status;
  // Optional: List of newly unlocked achievements to trigger UI events
  final List<Achievement> newUnlocks;

  const GamificationLoaded(this.status, {this.newUnlocks = const []});

  @override
  List<Object?> get props => [status, newUnlocks];
}

class GamificationError extends GamificationState {
  final String message;

  const GamificationError(this.message);

  @override
  List<Object?> get props => [message];
}
