import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/personalization_cubit.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/personalization_state.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_cubit.dart';
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
  String _preferredLanguage = 'English';
  Timer? _preferredNameDebounce;
  String _lastSyncedPreferredName = '';
  String _lastSyncedPreferredLanguage = 'English';
  bool _streamResponse = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _systemInstructionsController.dispose();
    _preferredNameController.dispose();
    _preferredToneController.dispose();
    _preferredNameDebounce?.cancel();
    super.dispose();
  }

  String _normalizePreferredLanguage(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'km' || normalized == 'kh' || normalized == 'khmer') {
      return 'Khmer';
    }
    return 'English';
  }

  void _schedulePreferredNameSync(String value) {
    final normalized = value.trim();
    if (normalized == _lastSyncedPreferredName) return;

    _preferredNameDebounce?.cancel();
    _preferredNameDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final updated = await context.read<PersonalizationCubit>().updatePreferences(
        UserPreferences(preferredName: normalized),
        showSuccess: false,
      );
      if (updated) {
        _lastSyncedPreferredName = normalized;
      }
    });
  }

  Future<void> _syncPreferredLanguage(String value) async {
    if (value == _lastSyncedPreferredLanguage) return;
    final updated = await context.read<PersonalizationCubit>().updatePreferences(
      UserPreferences(preferredLanguage: value),
      showSuccess: false,
    );
    if (updated) {
      _lastSyncedPreferredLanguage = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t.personalization),
        actions: [
          BlocConsumer<PersonalizationCubit, PersonalizationState>(
            listener: (context, state) {
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.t.tr('Preferences saved', 'បានរក្សាទុកចំណូលចិត្ត'),
                    ),
                  ),
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
                    : () async {
                        final prefs = UserPreferences(
                          systemInstructions:
                              _systemInstructionsController.text,
                          preferredName: _preferredNameController.text.trim(),
                          preferredTone: _preferredToneController.text,
                          preferredLanguage: _preferredLanguage,
                        );
                        await context
                            .read<PersonalizationCubit>()
                            .updatePreferences(
                          prefs,
                        );
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.t.save),
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

              setState(() {
                _streamResponse = state.preferences!.streamResponse ?? true;
                _hapticFeedback = state.preferences!.hapticFeedback ?? true;
                _preferredLanguage = _normalizePreferredLanguage(
                  state.preferences!.preferredLanguage,
                );
              });

              final localeCode = _preferredLanguage == 'Khmer' ? 'km' : 'en';
              context.read<SettingsCubit>().setLocaleCode(localeCode);
              _lastSyncedPreferredName = _preferredNameController.text.trim();
              _lastSyncedPreferredLanguage = _preferredLanguage;
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
                  title: context.t.tr('AI Persona', 'បុគ្គលិកលក្ខណៈ AI'),
                  child: Column(
                    children: [
                      TextField(
                        controller: _preferredNameController,
                        onChanged: _schedulePreferredNameSync,
                        decoration: InputDecoration(
                          labelText: context.t.tr('Preferred Name', 'ឈ្មោះដែលចង់ឱ្យហៅ'),
                          hintText: context.t.tr(
                            'How should the AI address you?',
                            'តើអ្នកចង់ឱ្យ AI ហៅអ្នកដូចម្តេច?',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _preferredToneController,
                        decoration: InputDecoration(
                          labelText: context.t.tr('Preferred Tone', 'សម្លេងដែលចង់បាន'),
                          hintText: context.t.tr(
                            'e.g., Friendly, Professional, Concise',
                            'ឧ. មិត្តភាព វិជ្ជាជីវៈ ខ្លីច្បាស់',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _preferredLanguage,
                        decoration: InputDecoration(
                          labelText: context.t.tr(
                            'Preferred Language',
                            'ភាសាដែលចង់បាន',
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text(context.t.english),
                          ),
                          DropdownMenuItem(
                            value: 'Khmer',
                            child: Text(context.t.khmer),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _preferredLanguage = value;
                          });
                          final localeCode = value == 'Khmer' ? 'km' : 'en';
                          context.read<SettingsCubit>().setLocaleCode(localeCode);
                          _syncPreferredLanguage(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _systemInstructionsController,
                        decoration: InputDecoration(
                          labelText: context.t.tr('System Instructions', 'សេចក្តីណែនាំប្រព័ន្ធ'),
                          hintText: context.t.tr(
                            'How should the AI behave? (e.g., "Be concise", "Act like a pirate")',
                            'AI គួរតែឆ្លើយដូចម្តេច? (ឧ. "ឆ្លើយខ្លីៗ", "និយាយបែបអ្នកជើងទឹក")',
                          ),
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
                  title: context.t.tr('Chat Experience', 'បទពិសោធន៍ជជែក'),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.t.tr('Stream Responses', 'បង្ហាញចម្លើយជាបន្តបន្ទាប់')),
                        subtitle: Text(
                          context.t.tr(
                            'Type out messages as they generate',
                            'បង្ហាញអក្សរតាមពេលកំពុងបង្កើតចម្លើយ',
                          ),
                        ),
                        value: _streamResponse,
                        onChanged: (val) =>
                            setState(() => _streamResponse = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.t.tr('Haptic Feedback', 'រំញ័រពេលប៉ះ')),
                        subtitle: Text(
                          context.t.tr('Vibrate on interactions', 'រំញ័រពេលធ្វើអន្តរកម្ម'),
                        ),
                        value: _hapticFeedback,
                        onChanged: (val) =>
                            setState(() => _hapticFeedback = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
