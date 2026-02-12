import 'dart:io';
import 'package:ai_chat_bot/features/settings/presentation/controllers/settings_controller.dart';
import 'package:ai_chat_bot/features/settings/presentation/widgets/app_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                'Appearance Settings',
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
    final settingsController = Get.find<SettingsController>();
    return Obx(() {
      final state = settingsController.state;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font Size', style: Theme.of(context).textTheme.titleMedium),
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
                    settingsController.setTextScale(value);
                  },
                ),
              ),
              const Icon(Icons.text_fields, size: 24),
            ],
          ),
        ],
      );
    });
  }
}

class _FontFamilySection extends StatelessWidget {
  const _FontFamilySection();

  static const List<String> _fonts = [
    'Outfit',
    'Roboto',
    'Inter',
    'Lora',
    'Monospace',
  ];

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    return Obx(() {
      final state = settingsController.state;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Family', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fonts.map((font) {
              final isSelected =
                  state.fontFamily == font ||
                  (state.fontFamily == 'App Default' && font == 'Outfit');
              return ChoiceChip(
                label: Text(font, style: _getFontStyle(font)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    if (font == 'Outfit') {
                      settingsController.setFontFamily('App Default');
                    } else {
                      settingsController.setFontFamily(font);
                    }
                  }
                },
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  TextStyle? _getFontStyle(String font) {
    switch (font) {
      case 'Roboto':
        return GoogleFonts.roboto();
      case 'Inter':
        return GoogleFonts.inter();
      case 'Lora':
        return GoogleFonts.lora();
      case 'Monospace':
        return GoogleFonts.spaceMono();
      default:
        return GoogleFonts.outfit();
    }
  }
}
