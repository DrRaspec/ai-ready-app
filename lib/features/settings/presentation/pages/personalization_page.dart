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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
      body: BlocConsumer<PersonalizationCubit, PersonalizationState>(
        listener: (context, state) {
          if (!state.isLoading && state.preferences != null) {
            _systemInstructionsController.text =
                state.preferences!.systemInstructions ?? '';
            setState(() {
              _streamResponse = state.preferences!.streamResponse ?? true;
              _hapticFeedback = state.preferences!.hapticFeedback ?? true;
              _themeMode = state.preferences!.themeMode ?? 'system';
              _defaultModel = state.preferences!.model;
            });

            // Sync with global ThemeCubit
            final themeCubit = context.read<ThemeCubit>();
            if (_themeMode == 'light') {
              themeCubit.light();
            } else if (_themeMode == 'dark') {
              themeCubit.dark();
            } else {
              themeCubit.system();
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
              _buildSectionHeader(theme, 'AI Persona'),
              const SizedBox(height: 8),
              TextField(
                controller: _systemInstructionsController,
                decoration: const InputDecoration(
                  labelText: 'System Instructions',
                  hintText:
                      'How should the AI behave? (e.g., "Be concise", "Act like a pirate")',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(theme, 'Chat Experience'),
              SwitchListTile(
                title: const Text('Stream Responses'),
                subtitle: const Text('Type out messages as they generate'),
                value: _streamResponse,
                onChanged: (val) => setState(() => _streamResponse = val),
              ),
              SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on interactions'),
                value: _hapticFeedback,
                onChanged: (val) => setState(() => _hapticFeedback = val),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(theme, 'Appearance'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
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
            ],
          );
        },
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
}
