import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/presentation/controllers/gamification_controller.dart';
import 'package:ai_chat_bot/features/gamification/presentation/controllers/gamification_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AchievementListener extends StatefulWidget {
  final Widget child;

  const AchievementListener({super.key, required this.child});

  @override
  State<AchievementListener> createState() => _AchievementListenerState();
}

class _AchievementListenerState extends State<AchievementListener> {
  late final GamificationController _gamificationController;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _gamificationController = Get.find<GamificationController>();
    _worker = ever<GamificationState>(_gamificationController.rxState, (state) {
      if (!mounted) return;
      if (state is GamificationLoaded && state.newUnlocks.isNotEmpty) {
        for (final achievement in state.newUnlocks) {
          _showAchievementNotification(context, achievement);
        }
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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
