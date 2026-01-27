import 'package:ai_chat_bot/features/prompts/data/prompts_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromptsSheet extends StatelessWidget {
  final Function(String) onPromptSelected;

  const PromptsSheet({super.key, required this.onPromptSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text('Quick Prompts', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          const Divider(),

          // Categories
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: PromptsData.categories.length,
              itemBuilder: (context, index) {
                final category = PromptsData.categories[index];
                return _CategorySection(
                  category: category,
                  onPromptSelected: (prompt) {
                    HapticFeedback.lightImpact();
                    onPromptSelected(prompt);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final PromptCategory category;
  final Function(String) onPromptSelected;

  const _CategorySection({
    required this.category,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Prompts Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category.prompts.map((prompt) {
            return _PromptChip(
              prompt: prompt,
              color: color,
              onTap: () => onPromptSelected(prompt.content),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'edit':
        return Icons.edit_note_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'lightbulb':
        return Icons.lightbulb_outline_rounded;
      case 'school':
        return Icons.school_outlined;
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _PromptChip extends StatelessWidget {
  final Prompt prompt;
  final Color color;
  final VoidCallback onTap;

  const _PromptChip({
    required this.prompt,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: prompt.description,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                prompt.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
