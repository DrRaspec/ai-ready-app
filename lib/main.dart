import 'package:ai_chat_bot/app/app.dart';
import 'package:ai_chat_bot/app/app_initializer.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await AppInitializer.initialize();
  runApp(const App());
}
