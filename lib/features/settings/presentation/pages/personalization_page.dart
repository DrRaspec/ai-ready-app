import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/features/settings/presentation/controllers/personalization_controller.dart';
import 'package:ai_chat_bot/features/settings/presentation/controllers/personalization_state.dart';
import 'package:ai_chat_bot/core/theme/theme_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PersonalizationView();
  }
}

class _PersonalizationView extends StatefulWidget {
  const _PersonalizationView();

  @override
  State<_PersonalizationView> createState() => _PersonalizationViewState();
}

class _PersonalizationViewState extends State<_PersonalizationView> {
  late final PersonalizationController _personalizationController;
  late final ThemeController _themeController;
  late final Worker _personalizationWorker;
  UserPreferences? _lastSyncedPreferences;
  String? _lastErrorMessage;

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
    _personalizationController = Get.find<PersonalizationController>();
    _themeController = Get.find<ThemeController>();
    _personalizationWorker = ever<PersonalizationState>(
      _personalizationController.rxState,
      _handlePersonalizationState,
    );
    _personalizationController.loadPreferences();
  }

  void _handlePersonalizationState(PersonalizationState state) {
    if (!mounted) return;

    if (state.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferences saved')));
      _personalizationController.resetSuccess();
    }

    if (state.errorMessage != null && state.errorMessage != _lastErrorMessage) {
      _lastErrorMessage = state.errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }

    if (!state.isLoading &&
        state.preferences != null &&
        !identical(_lastSyncedPreferences, state.preferences)) {
      _lastSyncedPreferences = state.preferences;
      final prefs = state.preferences!;

      _systemInstructionsController.text = prefs.systemInstructions ?? '';
      _preferredNameController.text = prefs.preferredName ?? '';
      _preferredToneController.text = prefs.preferredTone ?? '';
      _preferredLanguageController.text = prefs.preferredLanguage ?? '';

      setState(() {
        _streamResponse = prefs.streamResponse ?? true;
        _hapticFeedback = prefs.hapticFeedback ?? true;
        if (prefs.themeMode != null) {
          _themeMode = prefs.themeMode!;
        }
        _defaultModel = prefs.model;
      });

      if (prefs.themeMode == 'light') {
        _themeController.light();
      } else if (prefs.themeMode == 'dark') {
        _themeController.dark();
      } else if (prefs.themeMode == 'system') {
        _themeController.system();
      }
    }
  }

  @override
  void dispose() {
    _personalizationWorker.dispose();
    _systemInstructionsController.dispose();
    _preferredNameController.dispose();
    _preferredToneController.dispose();
    _preferredLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization'),
        actions: [
          Obx(() {
            final state = _personalizationController.state;
            return TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      final prefs = UserPreferences(
                        systemInstructions: _systemInstructionsController.text,
                        preferredName: _preferredNameController.text,
                        preferredTone: _preferredToneController.text,
                        preferredLanguage: _preferredLanguageController.text,
                        streamResponse: _streamResponse,
                        hapticFeedback: _hapticFeedback,
                        themeMode: _themeMode,
                        model: _defaultModel,
                      );
                      _personalizationController.updatePreferences(prefs);
                    },
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            );
          }),
        ],
      ),
      body: Obx(() {
        final state = _personalizationController.state;
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
              controller: _preferredNameController,
              decoration: const InputDecoration(
                labelText: 'Preferred Name',
                hintText: 'How should the AI address you?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _preferredToneController,
              decoration: const InputDecoration(
                labelText: 'Preferred Tone',
                hintText: 'e.g., Friendly, Professional, Concise',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _preferredLanguageController,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                hintText: 'e.g., English, Thai, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
                if (newMode == 'light') {
                  _themeController.light();
                } else if (newMode == 'dark') {
                  _themeController.dark();
                } else {
                  _themeController.system();
                }
              },
            ),
          ],
        );
      }),
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
