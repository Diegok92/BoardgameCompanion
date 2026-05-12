import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'widgets/home_menu_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String initials = user.username.isNotEmpty
        ? user.username.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Abrir Drawer (menú lateral) a futuro
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG Companion',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/logo.svg', height: 24),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- SECCIÓN 1: PERFIL ---
                    GestureDetector(
                      onTap: () {
                        context.push('/user-edit');
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: user.favoriteColor ?? Colors.blue,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hola, ${user.username}!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A que vamos a jugar hoy?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.blueGrey,
                      ),
                    ),

                    // Espaciador flexible
                    const Spacer(flex: 2),

                    // --- SECCIÓN 2: BOTONES PRINCIPALES ---
                    HomeMenuButton(
                      icon: Icons.person_add,
                      label: '+ AGREGAR INVITADOS',
                      backgroundColor: const Color(0xFFEF4444), // Rojo
                      onPressed: () {
                        context.push('/register-invitado');
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.book,
                      label: 'ANOTADORES',
                      backgroundColor: const Color(0xFF10B981), // Verde
                      onPressed: () {
                        context.push('/score-selector');
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.extension,
                      label: 'ACCESORIOS',
                      backgroundColor: const Color(0xFF3B82F6), // Azul
                      onPressed: () {
                        context.push('/accessories');
                      },
                    ),

                    // Espaciador flexible
                    const Spacer(flex: 3),

                    // --- SECCIÓN 3: BOTONES SECUNDARIOS ---
                    Row(
                      children: [
                        Expanded(
                          child: HomeMenuButton(
                            icon: Icons.bar_chart,
                            label: 'ESTADÍSTICAS',
                            backgroundColor: const Color(
                              0xFFF1F5F9,
                            ), // Gris claro
                            isSecondary: true,
                            onPressed: () {
                              // Navegar a estadísticas
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: HomeMenuButton(
                            icon: Icons.history,
                            label: 'HISTORIAL',
                            backgroundColor: const Color(
                              0xFFF1F5F9,
                            ), // Gris claro
                            isSecondary: true,
                            onPressed: () {
                              // Navegar a historial
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
