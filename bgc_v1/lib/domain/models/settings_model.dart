import 'package:flutter/material.dart';

class Settings {
  final Color themeColor;
  final bool isDarkMode;
  final bool keepSessionOpen;

  const Settings({
    required this.themeColor,
    required this.isDarkMode,
    required this.keepSessionOpen,
  });

  Settings copyWith({
    Color? themeColor,
    bool? isDarkMode,
    bool? keepSessionOpen,
  }) {
    return Settings(
      themeColor: themeColor ?? this.themeColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      keepSessionOpen: keepSessionOpen ?? this.keepSessionOpen,
    );
  }
}
