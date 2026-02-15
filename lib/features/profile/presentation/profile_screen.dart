import 'dart:io';
import 'package:ai_chat_bot/core/storage/local_storage.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ai_chat_bot/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:ai_chat_bot/features/profile/presentation/cubit/profile_state.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:ai_chat_bot/features/gamification/presentation/widgets/achievements_card.dart';
import 'package:ai_chat_bot/features/settings/presentation/widgets/settings_modal.dart';
import 'package:ai_chat_bot/core/routers/route_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_kit/flutter_adaptive_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    context.read<ProfileCubit>().loadProfile();
    context.read<GamificationCubit>().checkStatus();
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        // Upload to server
        final success = await context.read<ProfileCubit>().uploadProfilePicture(
          image.path,
        );
        if (success && mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
        } else if (mounted) {
          // Fallback to local storage if upload fails
          context.read<ProfileCubit>().setAvatar(image.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved locally (upload failed)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, ProfileState profileState) {
    final firstNameController = TextEditingController(
      text: profileState.firstName,
    );
    final lastNameController = TextEditingController(
      text: profileState.lastName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                hintText: 'Enter your first name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter your last name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await context.read<ProfileCubit>().updateProfile(
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will clear all bookmarks, pinned conversations, achievements, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await LocalStorage.clearAll();
              if (mounted) {
                Navigator.of(context).pop();
                _loadProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local data cleared')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout From All Devices'),
        content: const Text(
          'This will end all active sessions, including this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutAllRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) => current is Unauthenticated,
          listener: (context, state) {
            context.go(RoutePaths.login);
          },
          builder: (context, authState) {
            if (authState is Authenticated) {
              final user = authState.authData;

              return BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, profileState) {
                  // Use profile state name if available, otherwise auth data
                  final displayFirstName =
                      profileState.firstName ?? user.firstName ?? '';
                  final displayLastName =
                      profileState.lastName ?? user.lastName ?? '';
                  final fullName = '$displayFirstName $displayLastName'.trim();
                  final initials =
                      '${displayFirstName.isNotEmpty ? displayFirstName[0] : ''}'
                              '${displayLastName.isNotEmpty ? displayLastName[0] : ''}'
                          .toUpperCase();

                  return _buildAdaptiveProfileContent(
                    profileState: profileState,
                    theme: theme,
                    colorScheme: colorScheme,
                    fullName: fullName,
                    initials: initials,
                    email: user.email ?? '',
                  );
                },
              );
            }

            // Loading State Skeleton
            return Skeletonizer(
              enabled: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 32, width: 200, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 20, width: 150, color: Colors.white),
                    const SizedBox(height: 64),
                    Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdaptiveProfileContent({
    required ProfileState profileState,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String fullName,
    required String initials,
    required String email,
  }) {
    final isWideLayout =
        context.isTablet ||
        context.isDesktop ||
        (context.isLandscape && context.screenWidth >= 900);

    final contentPadding = context.adaptiveOrientation<double>(
      phonePortrait: 24,
      phoneLandscape: 20,
      tabletPortrait: 32,
      tabletLandscape: 36,
      desktopPortrait: 40,
      desktopLandscape: 48,
    );
    final maxContentWidth = context.adaptive<double>(
      phone: 700,
      tablet: 1200,
      desktop: 1440,
    );

    final profileHeader = _buildProfileIdentitySection(
      profileState: profileState,
      theme: theme,
      colorScheme: colorScheme,
      fullName: fullName,
      initials: initials,
      email: email,
    );

    final achievementsSection =
        BlocBuilder<GamificationCubit, GamificationState>(
          builder: (context, state) {
            if (state is GamificationLoaded) {
              return AchievementsCard(status: state.status);
            }
            return const SizedBox.shrink();
          },
        );

    final actionsSection = _buildQuickActionsSection(theme, colorScheme);
    final statsSection = _buildStatsSection(profileState, theme, colorScheme);
    final logoutButton = _buildLogoutButton(colorScheme);

    return SingleChildScrollView(
      padding: EdgeInsets.all(contentPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: isWideLayout
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          profileHeader,
                          const SizedBox(height: 24),
                          logoutButton,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          statsSection,
                          const SizedBox(height: 24),
                          achievementsSection,
                          const SizedBox(height: 24),
                          actionsSection,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    profileHeader,
                    const SizedBox(height: 32),
                    statsSection,
                    const SizedBox(height: 24),
                    achievementsSection,
                    const SizedBox(height: 24),
                    actionsSection,
                    const SizedBox(height: 32),
                    logoutButton,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileIdentitySection({
    required ProfileState profileState,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String fullName,
    required String initials,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          _buildAvatarSection(
            profileState.avatarPath,
            profileState.profilePictureUrl,
            initials,
            colorScheme,
            profileState.isUploading,
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                fullName.isNotEmpty ? fullName : 'User',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileDialog(context, profileState),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                tooltip: 'Edit Profile',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            email,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(LogoutRequested());
        },
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
    String? avatarPath,
    String? profilePictureUrl,
    String initials,
    ColorScheme colorScheme,
    bool isUploading,
  ) {
    // Priority: server URL > local avatar > initials
    ImageProvider? imageProvider;
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      imageProvider = NetworkImage(profilePictureUrl);
    } else if (avatarPath != null) {
      imageProvider = FileImage(File(avatarPath));
    }

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: isUploading ? null : _pickAvatar,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: imageProvider,
              child: isUploading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : (imageProvider == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: isUploading ? null : _pickAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStat(int value) {
    return value > 99 ? '99+' : value.toString();
  }

  Widget _buildStatsSection(
    ProfileState profileState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: _formatStat(profileState.conversationCount),
                  label: 'Conversations',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.message_outlined,
                  value: _formatStat(profileState.messageCount),
                  label: 'Messages',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  value: _formatStat(profileState.unlockedAchievements.length),
                  label: 'Badges',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.bookmark_outline_rounded,
            title: 'Bookmarks',
            subtitle: 'View saved messages',
            onTap: () => context.push('/bookmarks'),
          ),
          _ActionTile(
            icon: Icons.explore_outlined,
            title: 'Discover',
            subtitle: 'AI tips and prompts',
            onTap: () => context.push('/discover'),
          ),
          _ActionTile(
            icon: Icons.person_outline,
            title: 'Personalization',
            subtitle: 'AI Persona & Preferences',
            onTap: () => context.push('/personalization'),
          ),
          _ActionTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Customize chat look',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const SettingsModal(),
              );
            },
          ),
          _ActionTile(
            icon: Icons.devices_outlined,
            title: 'Active Sessions',
            subtitle: 'Manage devices',
            onTap: () => context.push(RoutePaths.sessions),
          ),
          _ActionTile(
            icon: Icons.logout,
            title: 'Logout All Devices',
            subtitle: 'End every active session',
            onTap: _showLogoutAllDialog,
            isDestructive: true,
          ),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Clear Local Data',
            subtitle: 'Reset bookmarks & settings',
            onTap: _showClearDataDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.38,
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive ? colorScheme.error : null,
                        ),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
