import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../providers/burako_tracker_provider.dart';

class BurakoEntityEditorDialog {
  static void show(BuildContext context, WidgetRef ref, int entityIndex) {
    final user = ref.read(authProvider);
    final invitados = user?.invitados ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentState = ref.read(burakoTrackerProvider);
            final currentEntity = currentState.entities[entityIndex];

            return AlertDialog(
              title: Text('Editar ${currentEntity.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(currentEntity.playerNames.length, (pIndex) {
                      final currName = currentEntity.playerNames[pIndex];
                      int globalIndex = 1;
                      for (int i = 0; i < entityIndex; i++) {
                        globalIndex += currentState.entities[i].playerNames.length;
                      }
                      globalIndex += pIndex;

                      if (entityIndex == 0 && pIndex == 0 && user != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Jugador 1: ${user.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Jugador $globalIndex',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          initialValue: currName != user?.username && currName != 'NUEVO_INVITADO' && !invitados.contains(currName) ? null : currName,
                          items: [
                            ...invitados.where((inv) {
                              for (int i = 0; i < currentState.entities.length; i++) {
                                for (int j = 0; j < currentState.entities[i].playerNames.length; j++) {
                                  if (i == entityIndex && j == pIndex) continue;
                                  if (currentState.entities[i].playerNames[j] == inv) return false;
                                }
                              }
                              return true;
                            }).map((inv) => DropdownMenuItem(value: inv, child: Text(inv))),
                            const DropdownMenuItem(value: 'NUEVO_INVITADO', child: Text('+ Agregar Invitado', style: TextStyle(color: Colors.blue))),
                            if (currName == null) const DropdownMenuItem(value: null, child: Text('Sin Asignar', style: TextStyle(color: Colors.grey))),
                          ],
                          onChanged: (val) {
                            if (val == 'NUEVO_INVITADO') {
                              Navigator.pop(context);
                              context.push('/register-invitado');
                            } else {
                              ref.read(burakoTrackerProvider.notifier).updatePlayerNameInEntity(entityIndex, pIndex, val);
                              setDialogState(() {});
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Elige color:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: AppColors.availableColors.where((color) {
                        return !currentState.entities.any((e) => e.id != currentEntity.id && e.color.toARGB32() == color.toARGB32());
                      }).map((color) {
                        return InkWell(
                          onTap: () {
                            ref.read(burakoTrackerProvider.notifier).updateEntityColor(entityIndex, color);
                            Navigator.pop(context);
                          },
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: currentEntity.color.toARGB32() == color.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
