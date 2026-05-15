import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Asegúrate de tener esto
import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Esto ahora funcionará porque está dentro de ProviderScope
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
