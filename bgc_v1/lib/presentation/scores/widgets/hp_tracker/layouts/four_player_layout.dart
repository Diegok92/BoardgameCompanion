import 'package:flutter/material.dart';
import '../../../../providers/hp_tracker_provider.dart';
import '../components/hp_shield.dart';
import '../components/player_color_picker.dart';
import '../components/player_name_dropdown.dart';

class FourPlayerLayout extends StatelessWidget {
  final List<TrackerPlayer> players;
  final List<String> invitados;
  final Set<int> usedColorsArgb;
  final void Function(int index, String? name) onNameChanged;
  final void Function(int index, Color color) onColorChanged;
  final void Function(int index, int delta) onHpChange;

  const FourPlayerLayout({
    super.key,
    required this.players,
    required this.invitados,
    required this.usedColorsArgb,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onHpChange,
  });

  // Píldora combinada: nombre a la izquierda + círculo de color a la derecha
  Widget _buildNameColorPill(TrackerPlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: player.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: player.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PlayerNameDropdown(
              isUser: player.index == 0,
              playerName: player.name,
              playerIndex: player.index,
              playerColor: player.color,
              invitados: invitados,
              onNameChanged: (val) => onNameChanged(player.index, val),
            ),
          ),
          const SizedBox(width: 8),
          PlayerColorPicker(
            playerColor: player.color,
            usedColorsArgb: usedColorsArgb,
            onColorChanged: (color) => onColorChanged(player.index, color),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCell(BuildContext context, TrackerPlayer player) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameColorPill(player),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -8,
                  left: -8,
                  right: -8,
                  bottom: -8,
                  child: HpShield(
                    hp: player.hp,
                    color: player.color,
                    onHpChange: (delta) => onHpChange(player.index, delta),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (players.length != 4) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos el ancho de cada celda
        final double cellWidth = (constraints.maxWidth - 8) / 2;
        
        // La altura de la celda es el ancho del escudo + altura de la píldora (~50px)
        double cellHeight = cellWidth + 56;
        
        // Aseguramos que las dos filas entren en la pantalla
        final double maxCellHeight = (constraints.maxHeight - 8) / 2;
        if (cellHeight > maxCellHeight) {
          cellHeight = maxCellHeight;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center, // ESTO CENTRA TODO EL BLOQUE
          children: [
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  _buildPlayerCell(context, players[0]),
                  const SizedBox(width: 8),
                  _buildPlayerCell(context, players[1]),
                ],
              ),
            ),
            const SizedBox(height: 48), // Aumentado de 8 a 48 para separar las filas
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  _buildPlayerCell(context, players[2]),
                  const SizedBox(width: 8),
                  _buildPlayerCell(context, players[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
