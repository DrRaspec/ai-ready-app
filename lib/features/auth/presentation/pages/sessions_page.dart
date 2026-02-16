import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/sessions_cubit.dart';
import 'package:ai_chat_bot/features/auth/data/models/session.dart';
import 'package:ai_chat_bot/core/localization/app_text.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t.activeSessions),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: context.t.tr('Terminate All Others', 'បញ្ចប់សម័យផ្សេងទាំងអស់'),
            onPressed: () {
              final sessionsCubit = context.read<SessionsCubit>();
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    context.t.tr(
                      'Terminate All Other Sessions?',
                      'បញ្ចប់សម័យឧបករណ៍ផ្សេងទាំងអស់?',
                    ),
                  ),
                  content: Text(
                    context.t.tr(
                      'Are you sure you want to log out from all other devices?',
                      'តើអ្នកប្រាកដថាចង់ចាកចេញពីឧបករណ៍ផ្សេងទាំងអស់មែនទេ?',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.t.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        sessionsCubit.terminateAllOtherSessions();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      child: Text(context.t.tr('Terminate All', 'បញ្ចប់ទាំងអស់')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: BlocConsumer<SessionsCubit, SessionsState>(
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
                    context.t.tr('No active sessions found.', 'រកមិនឃើញសម័យសកម្មទេ។'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.sessions.length,
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionTile(session: session),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
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
        : context.t.tr('Unknown', 'មិនស្គាល់');

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isCurrent
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            deviceIcon,
            color: isCurrent
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
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
                  context.t.tr('Current', 'ឧបករណ៍នេះ'),
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
              Text('${context.t.tr('IP', 'អាសយដ្ឋាន IP')}: ${session.ipAddress}'),
              Text(
                '${context.t.tr('Last Active', 'សកម្មចុងក្រោយ')}: $lastActiveStr',
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
                tooltip: context.t.tr('Terminate Session', 'បញ្ចប់សម័យ'),
                onPressed: () {
                  final sessionsCubit = context.read<SessionsCubit>();
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.t.tr('Terminate Session?', 'បញ្ចប់សម័យនេះ?')),
                      content: Text(
                        context.t.tr(
                          'Are you sure you want to log out from "${session.deviceInfo}"?',
                          'តើអ្នកប្រាកដថាចង់ចាកចេញពី "${session.deviceInfo}" មែនទេ?',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(context.t.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            sessionsCubit.terminateSession(session.sessionId);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          child: Text(context.t.tr('Terminate', 'បញ្ចប់')),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
