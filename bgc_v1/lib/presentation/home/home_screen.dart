import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'widgets/home_menu_button.dart';
import '../widgets/app_drawer.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/constants/app_strings.dart';

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
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24,
                  vertical: AppSizes.p16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- SECCIÓN 1: PERFIL ---
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
                    const SizedBox(height: 16),
                    Text(
                      'Hola, ${user.username}!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A que vamos a jugar hoy?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Espaciador flexible
                    const Spacer(flex: 1),

                    // --- SECCIÓN 2: BOTONES PRINCIPALES ---
                    HomeMenuButton(
                      icon: Icons.person_add,
                      label: AppStrings.addGuests,
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        context.push('/register-invitado');
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.edit_document,
                      label: AppStrings.trackers,
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        context.push('/score-selector');
                      },
                    ),
                    const SizedBox(height: 16),

                    HomeMenuButton(
                      icon: Icons.hourglass_bottom,
                      label: AppStrings.accessories,
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        context.push('/accessories');
                      },
                    ),

                    // Espaciador para acercar los botones inferiores
                    const SizedBox(height: 32),

                    // --- SECCIÓN 3: BOTONES SECUNDARIOS ---
                    Row(
                      children: [
                        Expanded(
                          child: HomeMenuButton(
                            icon: Icons.bar_chart,
                            label: AppStrings.stats,
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            isSecondary: true,
                            onPressed: () {
                              context.push('/stats');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: HomeMenuButton(
                            icon: Icons.history,
                            label: AppStrings.history,
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            isSecondary: true,
                            onPressed: () {
                              context.push('/historial');
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
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
