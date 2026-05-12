import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configuración',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // --- SECCIÓN: TEMA Y APARIENCIA ---
            _buildSectionHeader('Apariencia', colorScheme),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  // Modo Oscuro (Switch)
                  SwitchListTile(
                    title: const Text(
                      'Modo Oscuro',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Cambiar entre tema claro y oscuro'),
                    secondary: Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: settings.isDarkMode ? Colors.amber : Colors.orange,
                    ),
                    value: settings.isDarkMode,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(value);
                    },
                  ),

                  const Divider(height: 1),

                  // Color del Tema (ExpansionTile)
                  ExpansionTile(
                    leading: const Icon(Icons.color_lens, color: Colors.blue),
                    title: const Text(
                      'Color del Tema',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Elige tu color principal favorito'),
                    children: [
                      _buildColorRadio(
                        context: context,
                        ref: ref,
                        color: const Color(0xFFE53935), // Rojo
                        name: 'Rojo Carmesí',
                        currentColor: settings.themeColor,
                      ),
                      _buildColorRadio(
                        context: context,
                        ref: ref,
                        color: const Color(0xFF10B981), // Verde
                        name: 'Verde Esmeralda',
                        currentColor: settings.themeColor,
                      ),
                      _buildColorRadio(
                        context: context,
                        ref: ref,
                        color: const Color(0xFF3B82F6), // Azul
                        name: 'Azul Océano',
                        currentColor: settings.themeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SECCIÓN: SESIÓN ---
            _buildSectionHeader('Sesión', colorScheme),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: CheckboxListTile(
                title: const Text(
                  'Mantener sesión iniciada',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('No cerrar sesión al salir de la app'),
                secondary: const Icon(Icons.login, color: Colors.purple),
                value: settings.keepSessionOpen,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleKeepSessionOpen(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de ayuda para construir el RadioListTile de colores
  Widget _buildColorRadio({
    required BuildContext context,
    required WidgetRef ref,
    required Color color,
    required String name,
    required Color currentColor,
  }) {
    final isSelected = currentColor == color;
    return ListTile(
      onTap: () => ref.read(settingsProvider.notifier).updateThemeColor(color),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      title: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget de ayuda para construir el título de cada sección
  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
