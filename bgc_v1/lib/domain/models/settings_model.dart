import 'package:flutter/material.dart';

class Settings {
  final bool isDarkMode;
  final bool keepSessionOpen;

  const Settings({
    required this.isDarkMode,
    required this.keepSessionOpen,
  });

  Settings copyWith({
    bool? isDarkMode,
    bool? keepSessionOpen,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      keepSessionOpen: keepSessionOpen ?? this.keepSessionOpen,
    );
  }
}
