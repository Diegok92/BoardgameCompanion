import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/repositories/i_local_storage_repository.dart';
import '../widgets/custom_alert.dart';

// Proveedor para inyectar el LocalStorageRepository en la vista
final localStorageProvider = Provider<ILocalStorageRepository>((ref) {
  return LocalStorageRepository();
});

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
                  SwitchListTile(
                    title: const Text(
                      'Modo Obscuro',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Cambiar entre tema claro y obscuro'),
                    secondary: Icon(
                      settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: settings.isDarkMode ? Colors.amber : Colors.orange,
                    ),
                    value: settings.isDarkMode,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(value);
                    },
                  ),
                ],
              ),
            ),



            // --- SECCIÓN: DATOS ---
            _buildSectionHeader('Datos', colorScheme),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                title: Text(
                  'Borrar partidas en curso',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: const Text('Eliminar la caché local de partidas'),
                trailing: Icon(Icons.delete_forever, color: colorScheme.error),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Borrar Caché'),
                      content: const Text(
                        '¿Estás seguro de que quieres borrar todas las partidas locales en curso? Esta acción no se puede deshacer.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(localStorageProvider).clearAllData();
                            if (context.mounted) {
                              CustomAlert.show(context, 'Caché borrada exitosamente.');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          child: const Text('Borrar Todo'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
