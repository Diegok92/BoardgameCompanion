import 'package:flutter/material.dart';
import '../../providers/hp_tracker_provider.dart';
import '../components/hp_shield.dart';
import '../components/player_color_picker.dart';
import '../components/player_name_dropdown.dart';

class TwoPlayerLayout extends StatelessWidget {
  final List<TrackerPlayer> players;
  final List<String> invitados;
  final Set<int> usedColorsArgb;
  final void Function(int index, String? name) onNameChanged;
  final void Function(int index, Color color) onColorChanged;
  final void Function(int index, int delta) onHpChange;

  const TwoPlayerLayout({
    super.key,
    required this.players,
    required this.invitados,
    required this.usedColorsArgb,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onHpChange,
  });

  Widget _buildPill(Widget child, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Widget _buildPlayerRow(BuildContext context, TrackerPlayer player) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Escudo centrado y agrandado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 60.0),
            child: HpShield(
              hp: player.hp,
              color: player.color,
              onHpChange: (delta) => onHpChange(player.index, delta),
            ),
          ),
          // Nombre alineado a la izquierda y más arriba, con ancho máximo
          Positioned(
            left: 16,
            top: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.35,
              ),
              child: _buildPill(
                PlayerNameDropdown(
                  isUser: player.index == 0,
                  playerName: player.name,
                  playerIndex: player.index,
                  playerColor: player.color,
                  invitados: invitados,
                  onNameChanged: (val) => onNameChanged(player.index, val),
                ),
                player.color,
              ),
            ),
          ),
          // Color alineado a la derecha
          Positioned(
            right: 16,
            top: 4,
            child: _buildPill(
              PlayerColorPicker(
                playerColor: player.color,
                usedColorsArgb: usedColorsArgb,
                onColorChanged: (color) => onColorChanged(player.index, color),
              ),
              player.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (players.length != 2) return const SizedBox.shrink();

    return Column(
      children: [
        _buildPlayerRow(context, players[0]),
        const SizedBox(height: 16),
        _buildPlayerRow(context, players[1]),
      ],
    );
  }
}
