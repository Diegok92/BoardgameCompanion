import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'BG Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme(
        seedColor: settings.themeColor,
        isDarkMode: settings.isDarkMode,
      ).getTheme(),
      routerConfig: appRouter,
    );
  }
}
