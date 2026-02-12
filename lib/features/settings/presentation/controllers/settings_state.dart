import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final double textScaleFactor;
  final String fontFamily;
  final int? bubbleColor; // Custom color for user message bubbles

  const SettingsState({
    required this.textScaleFactor,
    required this.fontFamily,
    this.bubbleColor,
  });

  factory SettingsState.initial() {
    return const SettingsState(textScaleFactor: 1.0, fontFamily: 'Inter');
  }

  SettingsState copyWith({
    double? textScaleFactor,
    String? fontFamily,
    int? bubbleColor,
    bool clearBubbleColor = false,
  }) {
    return SettingsState(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      fontFamily: fontFamily ?? this.fontFamily,
      bubbleColor: clearBubbleColor ? null : (bubbleColor ?? this.bubbleColor),
    );
  }

  @override
  List<Object?> get props => [textScaleFactor, fontFamily, bubbleColor];
}
