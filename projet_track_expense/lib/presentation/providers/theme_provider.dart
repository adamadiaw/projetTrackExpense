import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// StateNotifier pour gérer le thème
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode themeMode) {
    state = themeMode;
  }

  void toggleTheme() {
    if (state == ThemeMode.system) {
      state = ThemeMode.light;
    } else if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }
}

// Provider pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});