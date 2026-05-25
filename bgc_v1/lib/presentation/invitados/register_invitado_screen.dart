import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class RegisterInvitadoScreen extends ConsumerStatefulWidget {
  const RegisterInvitadoScreen({super.key});

  @override
  ConsumerState<RegisterInvitadoScreen> createState() =>
      _RegisterInvitadoScreenState();
}

class _RegisterInvitadoScreenState
    extends ConsumerState<RegisterInvitadoScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addInvitado() {
    final name = _nameController.text.trim().toUpperCase();
    if (name.isNotEmpty) {
      ref.read(authProvider.notifier).addInvitado(name);
      _nameController.clear();
    }
  }

  void _deleteInvitado(int index) {
    ref.read(authProvider.notifier).removeInvitado(index);
  }

  void _editInvitado(int index, String currentName) {
    final TextEditingController editController = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Invitado'),
          content: TextField(
            controller: editController,
            maxLength: 9,
            decoration: const InputDecoration(hintText: 'Nuevo nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final newName = editController.text.trim().toUpperCase();
                if (newName.isNotEmpty) {
                  ref.read(authProvider.notifier).editInvitado(index, newName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final user = ref.watch(authProvider);
    final invitados = user?.invitados ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar del usuario
              CircleAvatar(
                radius: 40,
                backgroundColor: user?.favoriteColor ?? Colors.blue,
                child: Text(
                  user?.username.isNotEmpty == true
                      ? user!.username.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tus Invitados',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Formulario para agregar nuevo invitado
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      maxLength: 9,
                      decoration: const InputDecoration(
                        hintText: 'Nombre del invitado',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addInvitado,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('+ Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Lista de invitados
              Expanded(
                child: invitados.isEmpty
                    ? Center(
                        child: Text(
                          'Aún no tienes invitados registrados.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: invitados.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final invitado = invitados[index];
                          return Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  invitado[0].toUpperCase(),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                invitado,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _editInvitado(index, invitado),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteInvitado(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
