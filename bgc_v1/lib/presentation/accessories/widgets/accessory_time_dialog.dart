import 'package:flutter/material.dart';

/// Diálogo compartido para elegir la duración de un temporizador mediante chips.
///
/// Lo usan el reloj de ajedrez y el reloj de arena. Las opciones se pasan en
/// segundos y se etiquetan automáticamente como "X seg" o "X min".
class AccessoryTimeDialog {
  static String _label(int seconds) {
    if (seconds < 60) return '$seconds seg';
    return '${seconds ~/ 60} min';
  }

  static void show(
    BuildContext context, {
    required String title,
    required List<int> optionsSeconds,
    required ValueChanged<int> onSelect,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: optionsSeconds.map((seconds) {
              return ActionChip(
                label: Text(_label(seconds)),
                onPressed: () {
                  onSelect(seconds);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
