import 'package:flutter/material.dart';
import '../providers/hp_tracker_provider.dart';
import 'hp_shield.dart';
import '../../widgets/tracker_dialogs.dart';
import '../../widgets/player_badge.dart';

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
  Widget _buildSinglePlayerCapsule(
    bool isWide,
    bool isCompact,
    Set<int> usedColors,
    List<String> availableInvitados,
    BuildContext context,
  ) {
    return PlayerBadge(
      name: widget.player.name ?? 'Jugador ${widget.player.index + 1}',
      color: widget.player.color,
      height: isCompact ? 36 : 48,
      onTap: () {
        final usedNames = widget.allPlayers
            .map((p) => p.name)
            .where((n) => n != null)
            .cast<String>()
            .toList();
        final usedColorsList = widget.allPlayers.map((p) => p.color).toList();

        TrackerDialogs.showEntityEditor(
          context: context,
          entityName:
              widget.player.name ?? 'Jugador ${widget.player.index + 1}',
          entityId: widget.player.index.toString(),
          entityColor: widget.player.color,
          entityIndex: widget.player.index,
          loggedInUsername: widget.player.index == 0
              ? (widget.player.name ?? '')
              : null,
          invitados: widget.invitados,
          assignedNames: usedNames,
          assignedColors: usedColorsList,
          onNameChanged: widget.onNameChanged,
          onColorChanged: widget.onColorChanged,
          onAddInvitado: () => widget.onNameChanged('NUEVO_INVITADO'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usedColors = widget.allPlayers.map((p) => p.color.toARGB32()).toSet();
    final bool isSinglePlayer = widget.allPlayers.length == 1;

    final usedNames = widget.allPlayers
        .map((p) => p.name)
        .where((name) => name != null && name != widget.player.name)
        .toSet();

    final availableInvitados = widget.invitados
        .where((invitado) => !usedNames.contains(invitado))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > constraints.maxHeight * 1.3;
        bool isCompact = !isSinglePlayer;

        final capsule = _buildSinglePlayerCapsule(
          isWide,
          isCompact,
          usedColors,
          availableInvitados,
          context,
        );
        final shield = Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: HpShield(
              hp: widget.player.hp,
              color: widget.player.color,
              onHpChange: widget.onHpChange,
            ),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(
                flex: isCompact ? 1 : 2,
                child: Center(child: capsule),
              ),
              Expanded(flex: isCompact ? 1 : 3, child: shield),
            ],
          );
        } else {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: isCompact ? 4.0 : 16.0),
                child: capsule,
              ),
              shield,
            ],
          );
        }
      },
    );
  }
}
