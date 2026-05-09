import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_model.dart';

class RegisterInvitadoScreen extends StatefulWidget {
  final User user;

  const RegisterInvitadoScreen({super.key, required this.user});

  @override
  State<RegisterInvitadoScreen> createState() => _RegisterInvitadoScreenState();
}

class _RegisterInvitadoScreenState extends State<RegisterInvitadoScreen> {
  late List<String> _invitados;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializamos el estado local con la lista de invitados del usuario
    _invitados = List.from(widget.user.invitados);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addInvitado() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _invitados.add(name);
        widget.user.invitados.add(name); // Simula guardado en BD
      });
      _nameController.clear();
    }
  }

  void _deleteInvitado(int index) {
    setState(() {
      final removed = _invitados.removeAt(index);
      widget.user.invitados.remove(removed); // Simula borrado en BD
    });
  }

  void _editInvitado(int index) {
    final TextEditingController editController = TextEditingController(
      text: _invitados[index],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Invitado'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Nuevo nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    // Simula edición en BD
                    final oldName = _invitados[index];
                    widget.user.invitados.remove(oldName);
                    widget.user.invitados.add(newName);

                    _invitados[index] = newName;
                  });
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
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'Tus Invitados',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),

              // Formulario para agregar nuevo invitado
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
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
                      backgroundColor: const Color(0xFFEF4444), // Rojo
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
                child: _invitados.isEmpty
                    ? Center(
                        child: Text(
                          'Aún no tienes invitados registrados.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.blueGrey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _invitados.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final invitado = _invitados[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primary
                                    .withOpacity(0.2),
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
                                    onPressed: () => _editInvitado(index),
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
