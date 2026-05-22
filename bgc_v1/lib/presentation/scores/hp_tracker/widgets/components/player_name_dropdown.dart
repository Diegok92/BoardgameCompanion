import 'package:flutter/material.dart';

class PlayerNameDropdown extends StatelessWidget {
  final bool isUser;
  final String? playerName;
  final int playerIndex;
  final Color playerColor;
  final List<String> invitados;
  final ValueChanged<String?> onNameChanged;

  const PlayerNameDropdown({
    super.key,
    required this.isUser,
    required this.playerName,
    required this.playerIndex,
    required this.playerColor,
    required this.invitados,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        playerName ?? 'Usuario',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: playerColor,
        ),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return PopupMenuButton<String>(
        initialValue: playerName,
        onSelected: onNameChanged,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (BuildContext context) {
          return [
            ...invitados.map(
              (i) => PopupMenuItem(
                value: i,
                child: Text(
                  i,
                  style: TextStyle(
                    color: playerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const PopupMenuItem(
              value: 'NUEVO_INVITADO',
              child: Text(
                '+ Agregar...',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                playerName ?? 'Jugador ${playerIndex + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: playerName == null
                      ? playerColor.withValues(alpha: 0.6)
                      : playerColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: playerColor),
          ],
        ),
      );
    }
  }
}
