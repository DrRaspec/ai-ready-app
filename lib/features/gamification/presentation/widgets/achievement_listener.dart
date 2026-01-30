import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AchievementListener extends StatelessWidget {
  final Widget child;

  const AchievementListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamificationCubit, GamificationState>(
      listener: (context, state) {
        if (state is GamificationLoaded && state.newUnlocks.isNotEmpty) {
          for (var achievement in state.newUnlocks) {
            _showAchievementNotification(context, achievement);
          }
        }
      },
      child: child,
    );
  }

  void _showAchievementNotification(
    BuildContext context,
    Achievement achievement,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(achievement.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Achievement Unlocked!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(achievement.title),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      case 'military_tech':
        return Icons.military_tech;
      case 'bolt':
        return Icons.bolt;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.emoji_events;
    }
  }
}
