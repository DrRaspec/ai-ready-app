import 'dart:io';
import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_state.dart';
import 'package:ai_chat_bot/features/settings/presentation/widgets/app_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t.appearanceSettings,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const _FontSizeSection(),
                  const SizedBox(height: 24),
                  const _FontFamilySection(),
                  const SizedBox(height: 24),
                  const _LanguageSection(),
                  const SizedBox(height: 24),
                  if (Platform.isIOS) ...[
                    const AppIconPicker(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeSection extends StatelessWidget {
  const _FontSizeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t.fontSize,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${(state.textScaleFactor * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                Expanded(
                  child: Slider(
                    value: state.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(state.textScaleFactor * 100).toInt()}%',
                    onChanged: (value) {
                      context.read<SettingsCubit>().setTextScale(value);
                    },
                  ),
                ),
                const Icon(Icons.text_fields, size: 24),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FontFamilySection extends StatelessWidget {
  const _FontFamilySection();

  static const List<String> _englishFonts = [
    'App Default',
    'Roboto',
    'Inter',
    'Lora',
    'Monospace',
  ];
  static const List<String> _khmerFonts = [
    'App Default',
    'Noto Sans Khmer',
    'Kantumruy Pro',
    'Battambang',
    'Hanuman',
    'Khmer',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final effectiveLocaleCode =
            state.localeCode ?? Localizations.localeOf(context).languageCode;
        final isKhmer = effectiveLocaleCode == 'km';
        final fonts = isKhmer ? _khmerFonts : _englishFonts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.fontFamily,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fonts.map((font) {
                final isSelected = state.fontFamily == font;
                return ChoiceChip(
                  label: Text(font, style: _getFontStyle(font, isKhmer)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SettingsCubit>().setFontFamily(font);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  TextStyle? _getFontStyle(String font, bool isKhmer) {
    switch (font) {
      case 'App Default':
        return isKhmer
            ? GoogleFonts.notoSansKhmer()
            : GoogleFonts.plusJakartaSans();
      case 'Roboto':
        return GoogleFonts.roboto();
      case 'Inter':
        return GoogleFonts.inter();
      case 'Lora':
        return GoogleFonts.lora();
      case 'Monospace':
        return GoogleFonts.spaceMono();
      case 'Noto Sans Khmer':
        return GoogleFonts.notoSansKhmer();
      case 'Kantumruy Pro':
        return GoogleFonts.kantumruyPro();
      case 'Battambang':
        return GoogleFonts.battambang();
      case 'Hanuman':
        return GoogleFonts.hanuman();
      case 'Khmer':
        return GoogleFonts.khmer();
      default:
        return isKhmer
            ? GoogleFonts.notoSansKhmer()
            : GoogleFonts.plusJakartaSans();
    }
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.t.systemLanguage),
                  selected: state.localeCode == null,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SettingsCubit>().setLocaleCode(null);
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(context.t.english),
                  selected: state.localeCode == 'en',
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SettingsCubit>().setLocaleCode('en');
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(context.t.khmer),
                  selected: state.localeCode == 'km',
                  onSelected: (selected) {
                    if (selected) {
                      context.read<SettingsCubit>().setLocaleCode('km');
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
