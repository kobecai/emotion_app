import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'features/home/screens/home_screen.dart';

class LetGoApp extends StatelessWidget {
  const LetGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LETGO',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
