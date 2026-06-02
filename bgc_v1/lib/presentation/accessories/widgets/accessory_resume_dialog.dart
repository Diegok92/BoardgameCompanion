import 'package:flutter/material.dart';

/// Diálogo compartido que se muestra al entrar a un accesorio con temporizador
/// cuando había un estado guardado (una partida pausada). Pregunta si retomar
/// el temporizador como estaba o arrancar uno nuevo.
class AccessoryResumeDialog {
  static void show(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onNew,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Temporizador en curso',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Encontramos un temporizador pausado. '
            '¿Querés retomarlo como estaba o arrancar uno nuevo?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onNew();
              },
              child: const Text('Temporizador nuevo'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onResume();
              },
              child: const Text('Retomar'),
            ),
          ],
        );
      },
    );
  }
}
