import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/usage_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UsagePage extends GetView<UsageController> {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usage Statistics')),
      body: Obx(() {
        final state = controller.state;
        final usage = state.usage;

        if (usage == null) {
          return Skeletonizer(
            enabled: true,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _UsageCard(
                  title: 'Today',
                  tokens: 1560,
                  requests: 42,
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                SizedBox(height: 16),
                _UsageCard(
                  title: 'This Week',
                  tokens: 12500,
                  requests: 350,
                  icon: Icons.date_range,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                _UsageCard(
                  title: 'This Month',
                  tokens: 45000,
                  requests: 1200,
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.reloadUsage();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UsageCard(
                title: 'Today',
                tokens: usage.todayTokens,
                requests: usage.todayRequests,
                icon: Icons.today,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _UsageCard(
                title: 'This Week',
                tokens: usage.weeklyTokens,
                requests: usage.weeklyRequests,
                icon: Icons.date_range,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _UsageCard(
                title: 'This Month',
                tokens: usage.monthlyTokens,
                requests: usage.monthlyRequests,
                icon: Icons.calendar_month,
                color: Colors.orange,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final String title;
  final int tokens;
  final int requests;
  final IconData icon;
  final Color color;

  const _UsageCard({
    required this.title,
    required this.tokens,
    required this.requests,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Tokens',
                    value: _formatNumber(tokens),
                    color: color,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Requests',
                    value: requests.toString(),
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
