import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/settings_model.dart';

// Provider global para las configuraciones de la aplicación
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    // Estado inicial por defecto
    return const Settings(
      themeColor: Color(0xFF10B981), // Verde principal (default)
      isDarkMode: false,
      keepSessionOpen: false,
    );
  }

  void updateThemeColor(Color newColor) {
    state = state.copyWith(themeColor: newColor);
  }

  void toggleDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }

  void toggleKeepSessionOpen(bool keepOpen) {
    state = state.copyWith(keepSessionOpen: keepOpen);
  }
}
