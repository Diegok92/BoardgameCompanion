import 'package:flutter/material.dart';
import '../../widgets/custom_alert.dart';
import '../../../core/theme/app_colors.dart';

class DialogPlayerInfo {
  final String? name;
  final int score;
  DialogPlayerInfo(this.name, this.score);
}

class TrackerDialogs {
  /// Muestra el diálogo para terminar y guardar la partida, incluyendo toda la validación
  static void showFinishMatchDialog({
    required BuildContext context,
    required String? gameId,
    required String? gameName,
    required List<DialogPlayerInfo> players,
    String? customWinnerName,
    int? customMaxScore,
    required Future<void> Function(Map<String, int> finalScores) onSaveMatch,
    required VoidCallback onClearState,
    required VoidCallback onNavigateHome,
  }) {
    if (players.any(
      (p) =>
          p.name == null ||
          p.name!.isEmpty ||
          p.name == 'Sin Asignar' ||
          p.name == 'NUEVO_INVITADO' ||
          p.name!.startsWith('Jugador'),
    )) {
      CustomAlert.show(
        context,
        'Por favor, asigna todos los jugadores a un invitado antes de guardar.',
        isError: true,
      );
      return;
    }

    if (gameId == null || gameName == null) {
      CustomAlert.show(
        context,
        'Debes seleccionar un juego para registrar la partida.',
        isError: true,
      );
      return;
    }

    int maxScore = customMaxScore ?? 0;
    if (customMaxScore == null && players.isNotEmpty) {
      maxScore = players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    }
    final winners =
        customWinnerName ??
        players
            .where((p) => p.score == maxScore)
            .map((p) => p.name!)
            .join(' y ');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Terminar Partida?'),
        content: Text(
          'Ganador actual: $winners con $maxScore puntos.\n\n¿Deseas registrar esta partida y sus puntajes finales en el historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              Map<String, int> finalScores = {};
              for (var p in players) {
                finalScores[p.name!] = p.score;
              }

              try {
                await onSaveMatch(finalScores);
                onClearState();

                if (context.mounted) {
                  CustomAlert.show(context, 'Partida registrada con éxito!');
                  onNavigateHome();
                }
              } catch (e) {
                if (context.mounted) {
                  CustomAlert.show(
                    context,
                    'Error al guardar: $e',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Registrar Partida'),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de confirmación para resetear los puntajes
  static void showResetDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
    String title = '¿Resetear contadores?',
    String content =
        'Todos los jugadores volverán al valor inicial de la partida.',
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  /// Muestra un pop-up con input numérico (Ej: Vida inicial)
  static void showNumberInputDialog({
    required BuildContext context,
    required String title,
    required String label,
    required int initialValue,
    required ValueChanged<int> onConfirm,
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialValue.toString(),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final int? val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  Navigator.pop(dialogContext);
                  onConfirm(val);
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra el diálogo para editar un jugador (nombre y color)
  static void showEntityEditor({
    required BuildContext context,
    required String entityName,
    required String entityId,
    required Color entityColor,
    required int entityIndex,
    required String? loggedInUsername,
    required List<String> invitados,
    required List<String> assignedNames,
    required List<Color> assignedColors,
    required Function(String name) onNameChanged,
    required Function(Color color) onColorChanged,
    required VoidCallback onAddInvitado,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Editar $entityName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entityIndex == 0 && loggedInUsername != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Jugador 1: $loggedInUsername',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else if (entityId == 'ilustre')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Jugador Virtual: Ilustre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Jugador ${entityIndex + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: entityName.startsWith('Jugador')
                              ? null
                              : entityName,
                          items: [
                            ...invitados
                                .where(
                                  (inv) =>
                                      !assignedNames.contains(inv) ||
                                      inv == entityName,
                                )
                                .map(
                                  (inv) => DropdownMenuItem(
                                    value: inv,
                                    child: Text(inv),
                                  ),
                                ),
                            DropdownMenuItem(
                              value: 'NUEVO_INVITADO',
                              child: Text(
                                '+ Agregar Invitado',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            if (entityName.startsWith('Jugador'))
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Sin Asignar',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == 'NUEVO_INVITADO') {
                              Navigator.pop(dialogContext);
                              onAddInvitado();
                            } else {
                              onNameChanged(
                                val ?? 'Jugador ${entityIndex + 1}',
                              );
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Elige color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppColors.availableColors
                          .where((color) {
                            return !assignedColors.any(
                                  (c) => c.toARGB32() == color.toARGB32(),
                                ) ||
                                entityColor.toARGB32() == color.toARGB32();
                          })
                          .map((color) {
                            return InkWell(
                              onTap: () {
                                onColorChanged(color);
                                Navigator.pop(dialogContext);
                              },
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 16,
                                child:
                                    entityColor.toARGB32() == color.toARGB32()
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
                ),
              ),
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

  /// Muestra un teclado numérico (NumberPad)
  static void showNumberPadDialog({
    required BuildContext context,
    required String title,
    required int initialValue,
    required String explanation,
    required Function(int) onConfirm,
  }) {
    int currentValue = initialValue;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void appendDigit(int digit) {
              setDialogState(() {
                if (currentValue.toString().length < 4) {
                  currentValue = int.parse('$currentValue$digit');
                }
              });
            }

            void backspace() {
              setDialogState(() {
                if (currentValue > 9) {
                  currentValue = int.parse(
                    currentValue.toString().substring(
                      0,
                      currentValue.toString().length - 1,
                    ),
                  );
                } else {
                  currentValue = 0;
                }
              });
            }

            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentValue.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: Builder(
                      builder: (context) {
                        Widget buildNumBtn(int i) {
                          return Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => appendDigit(i),
                              child: Text(
                                i.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                buildNumBtn(1),
                                const SizedBox(width: 8),
                                buildNumBtn(2),
                                const SizedBox(width: 8),
                                buildNumBtn(3),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildNumBtn(4),
                                const SizedBox(width: 8),
                                buildNumBtn(5),
                                const SizedBox(width: 8),
                                buildNumBtn(6),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildNumBtn(7),
                                const SizedBox(width: 8),
                                buildNumBtn(8),
                                const SizedBox(width: 8),
                                buildNumBtn(9),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      setDialogState(() => currentValue = 0);
                                    },
                                    child: const Icon(Icons.delete_outline),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                buildNumBtn(0),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: backspace,
                                    child: const Icon(Icons.backspace_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onConfirm(currentValue);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
