import 'package:flutter/material.dart';

/// Barra de controles compartida para accesorios con temporizador
/// (reloj de ajedrez, reloj de arena, y futuros accesorios).
///
/// Muestra los botones Play / Pausa / Stop, y opcionalmente Volver y
/// Reiniciar-con-nuevo-tiempo. Los callbacks nulos ocultan su botón.
class AccessoryControlBar extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback? onBack;
  final VoidCallback? onRestart;

  /// Alto de la barra y tamaño del ícono principal (play/pausa/stop).
  /// Los defaults conservan el tamaño original (usado por el reloj de ajedrez).
  final double height;
  final double iconSize;

  const AccessoryControlBar({
    super.key,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    this.onBack,
    this.onRestart,
    this.height = 70,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onBack != null)
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: iconSize - 8),
              onPressed: onBack,
              tooltip: 'Volver',
            ),
          IconButton(
            icon: Icon(Icons.play_arrow, size: iconSize),
            color: Colors.green,
            onPressed: onPlay,
            tooltip: 'Comenzar',
          ),
          IconButton(
            icon: Icon(Icons.pause, size: iconSize),
            color: Colors.orange,
            onPressed: onPause,
            tooltip: 'Pausa',
          ),
          IconButton(
            icon: Icon(Icons.stop, size: iconSize),
            color: Colors.red,
            onPressed: onStop,
            tooltip: 'Detener',
          ),
          if (onRestart != null)
            IconButton(
              icon: Icon(Icons.restart_alt, size: iconSize - 4),
              color: colorScheme.primary,
              onPressed: onRestart,
              tooltip: 'Reiniciar con nuevo tiempo',
            ),
        ],
      ),
    );
  }
}
