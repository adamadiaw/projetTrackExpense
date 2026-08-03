import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// StateNotifier pour gérer le thème
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light); // On démarre en mode clair par défaut

  void setTheme(ThemeMode themeMode) {
    state = themeMode;
  }

  // ALTERNANCE DIRECTE : Light -> Dark -> Light
  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }
}

// Provider pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});