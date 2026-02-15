import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/personalization_cubit.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/personalization_state.dart';
import 'package:ai_chat_bot/core/theme/theme_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PersonalizationCubit(GetIt.I<AuthRepository>())..loadPreferences(),
      child: const _PersonalizationView(),
    );
  }
}

class _PersonalizationView extends StatefulWidget {
  const _PersonalizationView();

  @override
  State<_PersonalizationView> createState() => _PersonalizationViewState();
}

class _PersonalizationViewState extends State<_PersonalizationView> {
  final _systemInstructionsController = TextEditingController();
  final _preferredNameController = TextEditingController();
  final _preferredToneController = TextEditingController();
  final _preferredLanguageController = TextEditingController();
  bool _streamResponse = true;
  bool _hapticFeedback = true;
  String _themeMode = 'system';
  String? _defaultModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _systemInstructionsController.dispose();
    _preferredNameController.dispose();
    _preferredToneController.dispose();
    _preferredLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personalization'),
        actions: [
          BlocConsumer<PersonalizationCubit, PersonalizationState>(
            listener: (context, state) {
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences saved')),
                );
                context.read<PersonalizationCubit>().resetSuccess();
              }
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              return TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final prefs = UserPreferences(
                          systemInstructions:
                              _systemInstructionsController.text,
                          preferredName: _preferredNameController.text,
                          preferredTone: _preferredToneController.text,
                          preferredLanguage: _preferredLanguageController.text,
                          streamResponse: _streamResponse,
                          hapticFeedback: _hapticFeedback,
                          themeMode: _themeMode,
                          model: _defaultModel,
                        );
                        context.read<PersonalizationCubit>().updatePreferences(
                          prefs,
                        );
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
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
        child: BlocConsumer<PersonalizationCubit, PersonalizationState>(
          listener: (context, state) {
            if (!state.isLoading && state.preferences != null) {
              _systemInstructionsController.text =
                  state.preferences!.systemInstructions ?? '';
              _preferredNameController.text =
                  state.preferences!.preferredName ?? '';
              _preferredToneController.text =
                  state.preferences!.preferredTone ?? '';
              _preferredLanguageController.text =
                  state.preferences!.preferredLanguage ?? '';

              setState(() {
                _streamResponse = state.preferences!.streamResponse ?? true;
                _hapticFeedback = state.preferences!.hapticFeedback ?? true;
                if (state.preferences!.themeMode != null) {
                  _themeMode = state.preferences!.themeMode!;
                }
                _defaultModel = state.preferences!.model;
              });

              // Sync with global ThemeCubit only if the theme is explicitly provided by the server
              if (state.preferences!.themeMode != null) {
                final themeCubit = context.read<ThemeCubit>();
                if (state.preferences!.themeMode == 'light') {
                  themeCubit.light();
                } else if (state.preferences!.themeMode == 'dark') {
                  themeCubit.dark();
                } else if (state.preferences!.themeMode == 'system') {
                  themeCubit.system();
                }
              }
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.preferences == null) {
              return const Skeletonizer(
                enabled: true,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard(
                  context,
                  title: 'AI Persona',
                  child: Column(
                    children: [
                      TextField(
                        controller: _preferredNameController,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Name',
                          hintText: 'How should the AI address you?',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _preferredToneController,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Tone',
                          hintText: 'e.g., Friendly, Professional, Concise',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _preferredLanguageController,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Language',
                          hintText: 'e.g., English, Thai, etc.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _systemInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'System Instructions',
                          hintText:
                              'How should the AI behave? (e.g., "Be concise", "Act like a pirate")',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  context,
                  title: 'Chat Experience',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Stream Responses'),
                        subtitle: const Text(
                          'Type out messages as they generate',
                        ),
                        value: _streamResponse,
                        onChanged: (val) =>
                            setState(() => _streamResponse = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Haptic Feedback'),
                        subtitle: const Text('Vibrate on interactions'),
                        value: _hapticFeedback,
                        onChanged: (val) =>
                            setState(() => _hapticFeedback = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildSectionCard(
                  context,
                  title: 'Appearance',
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'system',
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: 'light',
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: 'dark',
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      final newMode = newSelection.first;
                      setState(() {
                        _themeMode = newMode;
                      });
                      // Immediate feedback
                      final themeCubit = context.read<ThemeCubit>();
                      if (newMode == 'light') {
                        themeCubit.light();
                      } else if (newMode == 'dark') {
                        themeCubit.dark();
                      } else {
                        themeCubit.system();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, title),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
