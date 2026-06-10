import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/settings_model.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    return const Settings(isDarkMode: false);
  }

  void toggleDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }
}
