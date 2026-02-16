import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final double textScaleFactor;
  final String fontFamily;
  final int? bubbleColor; // Custom color for user message bubbles
  final String? localeCode; // Null means follow system locale.

  const SettingsState({
    required this.textScaleFactor,
    required this.fontFamily,
    this.bubbleColor,
    this.localeCode,
  });

  factory SettingsState.initial() {
    return const SettingsState(textScaleFactor: 1.0, fontFamily: 'App Default');
  }

  SettingsState copyWith({
    double? textScaleFactor,
    String? fontFamily,
    int? bubbleColor,
    String? localeCode,
    bool clearBubbleColor = false,
    bool clearLocaleCode = false,
  }) {
    return SettingsState(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      fontFamily: fontFamily ?? this.fontFamily,
      bubbleColor:
          clearBubbleColor ? null : (bubbleColor ?? this.bubbleColor),
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
    );
  }

  @override
  List<Object?> get props => [
    textScaleFactor,
    fontFamily,
    bubbleColor,
    localeCode,
  ];
}
