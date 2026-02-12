import 'package:ai_chat_bot/features/auth/presentation/controllers/sessions_controller.dart';
import 'package:ai_chat_bot/features/auth/data/models/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late final SessionsController _sessionsController;
  late final Worker _sessionsWorker;

  @override
  void initState() {
    super.initState();
    _sessionsController = Get.find<SessionsController>();
    _sessionsWorker = ever<SessionsState>(_sessionsController.rxState, (state) {
      if (state is SessionsError && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
      }
    });
    _sessionsController.loadSessions();
  }

  @override
  void dispose() {
    _sessionsWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: 'Terminate All Others',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Terminate All Other Sessions?'),
                  content: const Text(
                    'Are you sure you want to log out from all other devices?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sessionsController.terminateAllOtherSessions();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      child: const Text('Terminate All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final state = _sessionsController.state;
        if (state is SessionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SessionsLoaded) {
          if (state.sessions.isEmpty) {
            return Center(
              child: Text(
                'No active sessions found.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: state.sessions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = state.sessions[index];
              return _SessionTile(
                session: session,
                sessionsController: _sessionsController,
              );
            },
          );
        }

        return const SizedBox.shrink();
      }),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final SessionsController sessionsController;

  const _SessionTile({required this.session, required this.sessionsController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrent = session.isCurrentSession;

    final dateFormat = DateFormat.yMMMd().add_jm();
    final lastActiveStr = session.lastActive != null
        ? dateFormat.format(session.lastActive!.toLocal())
        : 'Unknown';

    IconData deviceIcon = Icons.devices;
    final deviceLower = session.deviceInfo.toLowerCase();
    if (deviceLower.contains('mobile') ||
        deviceLower.contains('iphone') ||
        deviceLower.contains('android')) {
      deviceIcon = Icons.smartphone;
    } else if (deviceLower.contains('mac') ||
        deviceLower.contains('windows') ||
        deviceLower.contains('linux') ||
        deviceLower.contains('desktop')) {
      deviceIcon = Icons.laptop;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCurrent
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        child: Icon(
          deviceIcon,
          color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.deviceInfo,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Current',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: ${session.ipAddress}'),
            Text(
              'Last Active: $lastActiveStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      trailing: !isCurrent
          ? IconButton(
              icon: Icon(Icons.exit_to_app, color: colorScheme.error),
              tooltip: 'Terminate Session',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Terminate Session?'),
                    content: Text(
                      'Are you sure you want to log out from "${session.deviceInfo}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          sessionsController.terminateSession(session.sessionId);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                        child: const Text('Terminate'),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }
}
