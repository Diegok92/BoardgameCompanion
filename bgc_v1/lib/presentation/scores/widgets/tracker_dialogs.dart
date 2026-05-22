import 'package:flutter/material.dart';

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
    if (players.any((p) => p.name == null || p.name!.isEmpty || p.name == 'Sin Asignar' || p.name == 'NUEVO_INVITADO')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, asigna todos los jugadores a un invitado antes de guardar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (gameId == null || gameName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un juego para registrar la partida.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int maxScore = customMaxScore ?? 0;
    if (customMaxScore == null && players.isNotEmpty) {
      maxScore = players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    }
    final winners = customWinnerName ?? players.where((p) => p.score == maxScore).map((p) => p.name!).join(' y ');

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Partida registrada con éxito!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onNavigateHome();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar: $e'),
                      backgroundColor: Colors.red,
                    ),
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
    String content = 'Todos los jugadores volverán al valor inicial de la partida.',
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
    final TextEditingController controller = TextEditingController(text: initialValue.toString());
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

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
}
