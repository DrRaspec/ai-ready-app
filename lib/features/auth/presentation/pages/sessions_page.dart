import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/sessions_cubit.dart';
import 'package:ai_chat_bot/features/auth/data/models/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionsCubit(di<AuthRepository>())..loadSessions(),
      child: const _SessionsView(),
    );
  }
}

class _SessionsView extends StatelessWidget {
  const _SessionsView();

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
              final sessionsCubit = context.read<SessionsCubit>();
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Terminate All Other Sessions?'),
                  content: const Text(
                    'Are you sure you want to log out from all other devices?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        sessionsCubit.terminateAllOtherSessions();
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
      body: BlocConsumer<SessionsCubit, SessionsState>(
        listener: (context, state) {
          if (state is SessionsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
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
                return _SessionTile(session: session);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrent = session.isCurrentSession;
    final canTerminate = !isCurrent && session.sessionId.trim().isNotEmpty;

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
      trailing: canTerminate
          ? IconButton(
              icon: Icon(Icons.exit_to_app, color: colorScheme.error),
              tooltip: 'Terminate Session',
              onPressed: () {
                final sessionsCubit = context.read<SessionsCubit>();
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Terminate Session?'),
                    content: Text(
                      'Are you sure you want to log out from "${session.deviceInfo}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          sessionsCubit.terminateSession(session.sessionId);
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
