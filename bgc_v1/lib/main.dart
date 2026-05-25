import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Asegúrate de tener esto
import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear la orientación a vertical (portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      theme: AppTheme(isDarkMode: settings.isDarkMode).getTheme(),
      routerConfig: appRouter,
    );
  }
}
