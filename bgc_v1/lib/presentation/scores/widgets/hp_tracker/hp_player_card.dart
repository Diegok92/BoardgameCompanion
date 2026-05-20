import 'package:flutter/material.dart';
import '../../../providers/hp_tracker_provider.dart';
import 'components/hp_shield.dart';
import 'components/player_color_picker.dart';
import 'components/player_name_dropdown.dart';

class HpPlayerCard extends StatefulWidget {
  final TrackerPlayer player;
  final List<String> invitados;
  final List<TrackerPlayer> allPlayers;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onHpChange;

  const HpPlayerCard({
    super.key,
    required this.player,
    required this.invitados,
    required this.allPlayers,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onHpChange,
  });

  @override
  State<HpPlayerCard> createState() => _HpPlayerCardState();
}

class _HpPlayerCardState extends State<HpPlayerCard> {
  Widget _buildPill(Widget child, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usedColors = widget.allPlayers.map((p) => p.color.toARGB32()).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Escudo
            Padding(
              padding: const EdgeInsets.only(top: 36.0, bottom: 0.0, left: 8.0, right: 48.0),
              child: HpShield(
                hp: widget.player.hp,
                color: widget.player.color,
                onHpChange: widget.onHpChange,
              ),
            ),
            // Nombre (Arriba a la izquierda)
            Positioned(
              left: 4,
              top: 4,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - 16, // Aprovecha casi todo el ancho
                ),
                child: _buildPill(
                  PlayerNameDropdown(
                    isUser: widget.player.index == 0,
                    playerName: widget.player.name,
                    playerIndex: widget.player.index,
                    playerColor: widget.player.color,
                    invitados: widget.invitados,
                    onNameChanged: widget.onNameChanged,
                  ),
                  widget.player.color,
                ),
              ),
            ),
            // Color (A la derecha, centrado verticalmente con el escudo)
            Positioned(
              right: 4,
              top: 0,
              bottom: -36, // Para compensar el top: 36 del escudo y que quede visualmente centrado con él
              child: Center(
                child: _buildPill(
                  PlayerColorPicker(
                    playerColor: widget.player.color,
                    usedColorsArgb: usedColors,
                    onColorChanged: widget.onColorChanged,
                  ),
                  widget.player.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
