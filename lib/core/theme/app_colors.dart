import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary
  static const primary = Color(0xFF0B6E99);
  static const primaryDark = Color(0xFF07597D);
  static const secondary = Color(0xFF14B8A6);

  // Light mode
  static const lightBackground = Color(0xFFF4F7FB);
  static const lightSurface = Colors.white;
  static const lightSurfaceContainer = Color(0xFFE8EEF5);
  static const lightText = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF526076);

  static const lightBubbleUser = primary;
  static const lightBubbleUserText = Colors.white;
  static const lightBubbleAI = Color(0xFFEAF1F8);
  static const lightBubbleAIText = lightText;

  // Dark mode
  static const darkBackground = Color(0xFF0C1117);
  static const darkSurface = Color(0xFF141C26);
  static const darkSurfaceContainer = Color(0xFF1E2A38);
  static const darkText = Color(0xFFF2F6FB);
  static const darkTextSecondary = Color(0xFF9AA9BC);

  static const darkBubbleUser = primary;
  static const darkBubbleUserText = Colors.white;
  static const darkBubbleAI = darkSurfaceContainer;
  static const darkBubbleAIText = darkText;

  // Semantic
  static const error = Color(0xFFD64045);
  static const success = Color(0xFF16A34A);
}
