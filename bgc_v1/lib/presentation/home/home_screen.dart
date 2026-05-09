import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/user_model.dart';
import 'widgets/home_menu_button.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                fontSize: 20, // Un poco más pequeño para el AppBar
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/logo.svg',
              height: 24, // Ajustado para AppBar
            ),
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
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
                        // Navegar a agregar invitados
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.book,
                      label: 'ANOTADORES',
                      backgroundColor: const Color(0xFF10B981), // Verde
                      onPressed: () {
                        // Navegar a anotadores
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.extension,
                      label: 'ACCESORIOS',
                      backgroundColor: const Color(0xFF3B82F6), // Azul
                      onPressed: () {
                        // Navegar a accesorios
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
