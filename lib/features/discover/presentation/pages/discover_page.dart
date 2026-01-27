import 'package:ai_chat_bot/features/prompts/data/prompts_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Tips Section
            _buildTipsSection(theme, colorScheme),
            const SizedBox(height: 24),

            // AI Capabilities
            _buildCapabilitiesSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Prompt Ideas
            _buildPromptIdeasSection(context, theme, colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.tertiary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Unlock AI Power',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore tips, prompts, and capabilities to get the most out of your AI assistant.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(ThemeData theme, ColorScheme colorScheme) {
    final tips = [
      {
        'icon': Icons.format_quote_rounded,
        'tip': 'Be specific about what you want',
        'detail':
            'Instead of "write about dogs", try "write a 200-word article about golden retrievers as family pets"',
      },
      {
        'icon': Icons.layers_rounded,
        'tip': 'Provide context',
        'detail':
            'Tell the AI your role, target audience, or specific requirements',
      },
      {
        'icon': Icons.repeat_rounded,
        'tip': 'Iterate and refine',
        'detail': 'Ask follow-up questions to improve the response',
      },
      {
        'icon': Icons.format_list_numbered_rounded,
        'tip': 'Request specific formats',
        'detail':
            'Ask for lists, tables, bullet points, or step-by-step guides',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tips_and_updates_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Pro Tips',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tips.map(
          (tip) => _TipCard(
            icon: tip['icon'] as IconData,
            title: tip['tip'] as String,
            description: tip['detail'] as String,
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilitiesSection(ThemeData theme, ColorScheme colorScheme) {
    final capabilities = [
      {
        'icon': Icons.chat_rounded,
        'name': 'Chat',
        'desc': 'Natural conversations',
        'color': 0xFF6366F1,
      },
      {
        'icon': Icons.image_rounded,
        'name': 'Vision',
        'desc': 'Analyze images',
        'color': 0xFF10B981,
      },
      {
        'icon': Icons.mic_rounded,
        'name': 'Voice',
        'desc': 'Speech to text',
        'color': 0xFFF59E0B,
      },
      {
        'icon': Icons.brush_rounded,
        'name': 'Generate',
        'desc': 'Create images',
        'color': 0xFFEC4899,
      },
      {
        'icon': Icons.code_rounded,
        'name': 'Code',
        'desc': 'Write & debug',
        'color': 0xFF8B5CF6,
      },
      {
        'icon': Icons.translate_rounded,
        'name': 'Translate',
        'desc': 'Any language',
        'color': 0xFF06B6D4,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'AI Capabilities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: capabilities.length,
          itemBuilder: (context, index) {
            final cap = capabilities[index];
            return _CapabilityCard(
              icon: cap['icon'] as IconData,
              name: cap['name'] as String,
              description: cap['desc'] as String,
              color: Color(cap['color'] as int),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromptIdeasSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prompt Ideas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/chat'),
              child: const Text('Try Now'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...PromptsData.categories.take(3).map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(category.color),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.prompts.take(3).map((prompt) {
                  return ActionChip(
                    label: Text(prompt.title),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Copy to clipboard only
                      Clipboard.setData(ClipboardData(text: prompt.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prompt copied! Paste in chat'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final Color color;

  const _CapabilityCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
