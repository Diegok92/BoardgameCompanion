

class Settings {
  final bool isDarkMode;

  const Settings({
    required this.isDarkMode,
  });

  Settings copyWith({
    bool? isDarkMode,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
