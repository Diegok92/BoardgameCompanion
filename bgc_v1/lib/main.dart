import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Asegúrate de tener esto
import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Ejecuta la prueba de lectura (se verá en consola)
  await testReadUsersFromFirebase();

  // 3. Envuelve TODO en ProviderScope
  runApp(const ProviderScope(child: MainApp()));
}

Future<void> testReadUsersFromFirebase() async {
  try {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    print('========== USUARIOS FIREBASE ==========');

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();

      print('ID DOCUMENTO: ${doc.id}');
      print('USERNAME: ${data['username']}');
      print('EMAIL: ${data['email']}');
      print('AVATAR: ${data['avatar_url']}');
      print('CREATED AT: ${data['created_at']}');
      print('--------------------------------------');
    }

    print('TOTAL USUARIOS: ${usersSnapshot.docs.length}');
    print('=======================================');
  } catch (e) {
    // Si sale el error de "Missing or insufficient permissions",
    // recuerda cambiar las reglas en la consola de Firebase.
    print('ERROR LEYENDO USUARIOS FIREBASE: $e');
  }
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
