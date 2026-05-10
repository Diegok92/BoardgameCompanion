import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_model.dart';
import 'widgets/home_menu_button.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                      onTap: () async {
                        // Navegar a editar usuario y esperar a que vuelva
                        await context.push('/user-edit', extra: widget.user);
                        // Al volver, refrescamos la pantalla
                        setState(() {});
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                widget.user.favoriteColor ?? Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
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
                      'Hola, ${widget.user.username}!',
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
                        context.push('/invitados', extra: widget.user);
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.book,
                      label: 'ANOTADORES',
                      backgroundColor: const Color(0xFF10B981), // Verde
                      onPressed: () {
                        context.push('/score-selector', extra: widget.user);
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.extension,
                      label: 'ACCESORIOS',
                      backgroundColor: const Color(0xFF3B82F6), // Azul
                      onPressed: () {
                        context.push('/accessories', extra: widget.user);
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
