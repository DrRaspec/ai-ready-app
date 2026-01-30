import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';
import 'package:ai_chat_bot/features/gamification/data/models/gamification_status.dart';
import 'package:flutter/material.dart';

class AchievementsCard extends StatelessWidget {
  final GamificationStatus status;

  const AchievementsCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlockedCount = status.achievements.where((a) => a.isUnlocked).length;
    final totalCount = status.achievements.length;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E212B)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.1 : 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700), // Gold
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$unlockedCount/$totalCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.grey[400]
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              final achievement = status.achievements[index];
              return _AchievementIcon(achievement: achievement);
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final Achievement achievement;

  const _AchievementIcon({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = achievement.isUnlocked;
    final isDark = theme.brightness == Brightness.dark;

    final baseIconColor = isDark
        ? Colors.grey[600]
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
    final unlockedIconColor = const Color(0xFFFFD700);

    final baseBgColor = isDark
        ? const Color(0xFF2A2D3A)
        : colorScheme.surfaceContainerHigh;

    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? baseBgColor : baseBgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: isUnlocked
              ? Border.all(
                  color: unlockedIconColor,
                  width: 1.5,
                ) // Gold border for unlocked
              : null,
        ),
        child: Icon(
          _getIconData(achievement.icon, achievement.id),
          color: isUnlocked ? unlockedIconColor : baseIconColor,
          size: 24,
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName, String id) {
    // Priority 1: Map by ID (most reliable)
    final lowerId = id.toLowerCase();
    if (lowerId.contains('first_message') || lowerId.contains('chat_starter')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (lowerId.contains('vision') || lowerId.contains('image_analyzer')) {
      return Icons.visibility_outlined;
    }
    if (lowerId.contains('streak') || lowerId.contains('daily')) {
      return Icons.bolt_rounded;
    }
    if (lowerId.contains('bookmark')) {
      return Icons.bookmark_outline_rounded;
    }
    if (lowerId.contains('theme') || lowerId.contains('appearance')) {
      return Icons.palette_outlined;
    }
    if (lowerId.contains('profile')) {
      return Icons.person_outline;
    }
    if (lowerId.contains('share')) {
      return Icons.share_outlined;
    }

    // Priority 2: Map by icon name from API
    final name = iconName?.toLowerCase() ?? '';
    switch (name) {
      case 'chat_bubble':
      case 'chat':
      case 'message':
      case 'messages':
        return Icons.chat_bubble_outline_rounded;
      case 'forum':
        return Icons.forum_outlined;
      case 'workspace_premium':
      case 'trophy':
      case 'award':
      case 'medal':
        return Icons.workspace_premium_outlined;
      case 'bolt':
      case 'fire':
      case 'streak':
        return Icons.bolt_rounded;
      case 'bookmark':
      case 'save':
        return Icons.bookmark_outline_rounded;
      case 'visibility':
      case 'eye':
      case 'vision':
        return Icons.visibility_outlined;
      case 'nightlight':
      case 'moon':
      case 'dark_mode':
        return Icons.nightlight_outlined;
      case 'wb_sunny':
      case 'sun':
      case 'light_mode':
        return Icons.wb_sunny_outlined;
      case 'star':
        return Icons.star_border_rounded;
      case 'edit':
      case 'pencil':
        return Icons.edit_note_rounded;
      case 'palette':
      case 'style':
        return Icons.palette_outlined;
      case 'folder':
        return Icons.folder_outlined;
      case 'person':
      case 'profile':
      case 'user':
        return Icons.person_outline;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}
