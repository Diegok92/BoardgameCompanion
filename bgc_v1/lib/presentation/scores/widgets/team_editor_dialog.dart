import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Editor compartido para "entidades con uno o varios jugadores" (equipos de
/// Burako, Truco, etc.): asigna invitados a cada posición y, opcionalmente,
/// elige el color de la entidad.
///
/// Es agnóstico del provider — recibe el estado actual y callbacks, así que
/// cualquier anotador por equipos puede reutilizarlo sin duplicar código.
class TeamEditorDialog {
  /// Número global "Jugador N" del primer slot de la entidad [index]
  /// (suma los jugadores de las entidades anteriores).
  static int firstPlayerNumber(List<List<String?>> allNames, int index) {
    var n = 1;
    for (var i = 0; i < index; i++) {
      n += allNames[i].length;
    }
    return n;
  }

  /// Construye la validación de asignación: un invitado se puede usar en un slot
  /// si no está ya ocupado en otra posición de cualquier entidad.
  static bool Function(int slot, String name) canAssignBuilder(
    List<List<String?>> allNames,
    int index,
  ) {
    return (slot, name) {
      for (var i = 0; i < allNames.length; i++) {
        for (var j = 0; j < allNames[i].length; j++) {
          if (i == index && j == slot) continue;
          if (allNames[i][j] == name) return false;
        }
      }
      return true;
    };
  }

  /// Colores usados por las OTRAS entidades (para no repetir el color).
  static List<Color> takenColors(List<Color> allColors, int index) {
    return [
      for (var i = 0; i < allColors.length; i++)
        if (i != index) allColors[i],
    ];
  }

  static void show(
    BuildContext context, {
    required String title,
    required List<String?> currentNames,
    required int firstPlayerNumber,
    required List<String> invitados,
    required bool Function(int slotIndex, String invitado) canAssign,
    required void Function(int slotIndex, String? name) onNameChanged,
    required VoidCallback onAddInvitado,
    String? lockedFirstSlotLabel,
    Color? currentColor,
    List<Color> takenColors = const [],
    ValueChanged<Color>? onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            final showColors = currentColor != null && onColorChanged != null;

            return AlertDialog(
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(currentNames.length, (slot) {
                      final globalNumber = firstPlayerNumber + slot;
                      final currName = currentNames[slot];

                      if (slot == 0 && lockedFirstSlotLabel != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            lockedFirstSlotLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: cs.primary,
                            ),
                          ),
                        );
                      }

                      final selectable = invitados
                          .where((inv) => canAssign(slot, inv))
                          .toList();
                      final selectedValue =
                          (currName != null && selectable.contains(currName))
                          ? currName
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String?>(
                          initialValue: selectedValue,
                          decoration: InputDecoration(
                            labelText: 'Jugador $globalNumber',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Sin asignar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...selectable.map(
                              (inv) => DropdownMenuItem<String?>(
                                value: inv,
                                child: Text(inv),
                              ),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'NUEVO_INVITADO',
                              child: Text(
                                '+ Agregar invitado',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == 'NUEVO_INVITADO') {
                              Navigator.pop(dialogContext);
                              onAddInvitado();
                              return;
                            }
                            onNameChanged(slot, val);
                            setDialogState(() {});
                          },
                        ),
                      );
                    }),

                    if (showColors) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Elegí color:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppColors.availableColors
                            .where((color) {
                              final taken = takenColors.any(
                                (c) => c.toARGB32() == color.toARGB32(),
                              );
                              return !taken ||
                                  currentColor.toARGB32() == color.toARGB32();
                            })
                            .map((color) {
                              final isSelected =
                                  currentColor.toARGB32() == color.toARGB32();
                              return InkWell(
                                onTap: () {
                                  onColorChanged(color);
                                  Navigator.pop(dialogContext);
                                },
                                child: CircleAvatar(
                                  backgroundColor: color,
                                  radius: 16,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
