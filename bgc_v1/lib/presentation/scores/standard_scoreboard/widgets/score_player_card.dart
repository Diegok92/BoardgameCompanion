import 'package:flutter/material.dart';

import '../../widgets/calculator_dialog.dart';
import '../../widgets/player_badge.dart';
import '../../widgets/tracker_dialogs.dart';
import '../providers/standard_scoreboard_provider.dart';

/// Tarjeta de un jugador en el anotador de puntos: muestra el badge con su
/// nombre/color (tocable para editar) y su puntaje (tocable para modificar).
class ScorePlayerCard extends StatelessWidget {
  final ScorePlayer player;
  final List<ScorePlayer> allPlayers;
  final List<String> invitados;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onScoreChange;

  const ScorePlayerCard({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.invitados,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onScoreChange,
  });

  void _openEditor(BuildContext context) {
    final usedNames = allPlayers
        .map((p) => p.name)
        .whereType<String>()
        .toList();
    final usedColors = allPlayers.map((p) => p.color).toList();

    TrackerDialogs.showEntityEditor(
      context: context,
      entityName: player.name ?? 'Jugador ${player.index + 1}',
      entityId: player.index.toString(),
      entityColor: player.color,
      entityIndex: player.index,
      loggedInUsername: player.index == 0 ? (player.name ?? '') : null,
      invitados: invitados,
      assignedNames: usedNames,
      assignedColors: usedColors,
      onNameChanged: onNameChanged,
      onColorChanged: onColorChanged,
      onAddInvitado: () => onNameChanged('NUEVO_INVITADO'),
    );
  }

  Future<void> _openCalculator(BuildContext context) async {
    final name = player.name ?? 'Jugador ${player.index + 1}';
    final delta = await CalculatorDialog.show(
      context,
      title: 'Sumar puntos a $name',
    );
    if (delta != null && delta != 0) {
      onScoreChange(delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = player.name ?? 'Jugador ${player.index + 1}';

    return GestureDetector(
      onTap: () => _openCalculator(context),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: player.color, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: player.color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PlayerBadge(
              name: name,
              color: player.color,
              width: double.infinity,
              height: 36,
              onTap: () => _openEditor(context),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${player.score}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Tocar para modificar',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
