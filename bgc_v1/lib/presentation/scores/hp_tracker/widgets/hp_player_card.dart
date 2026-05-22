import 'package:flutter/material.dart';
import '../providers/hp_tracker_provider.dart';
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
  Widget _buildSinglePlayerCapsule(bool isWide, bool isCompact, Set<int> usedColors, List<String> availableInvitados) {
    final colorSelector = PlayerColorPicker(
      playerColor: widget.player.color,
      usedColorsArgb: usedColors,
      onColorChanged: widget.onColorChanged,
    );

    final nameSelector = PlayerNameDropdown(
      isUser: widget.player.index == 0,
      playerName: widget.player.name,
      playerIndex: widget.player.index,
      playerColor: widget.player.color,
      invitados: availableInvitados,
      onNameChanged: widget.onNameChanged,
    );

    Widget capsuleContent;
    if (isWide && !isCompact) {
      capsuleContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          colorSelector,
          const SizedBox(height: 6),
          Container(
            height: 1.5,
            width: 32,
            color: widget.player.color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 6),
          Flexible(child: nameSelector),
        ],
      );
    } else {
      capsuleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          colorSelector,
          SizedBox(width: isCompact ? 8 : 16),
          Container(
            width: 2,
            height: isCompact ? 24 : 32,
            color: widget.player.color.withValues(alpha: 0.3),
          ),
          SizedBox(width: isCompact ? 8 : 16),
          Flexible(child: nameSelector),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 2.0 : (isWide ? 4.0 : 16.0),
        vertical: isCompact ? 2.0 : (isWide ? 16.0 : 4.0),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : (isWide ? 8 : 24),
          vertical: isCompact ? 6 : (isWide ? 16 : 12),
        ),
        decoration: BoxDecoration(
          color: widget.player.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: widget.player.color.withValues(alpha: 0.3),
            width: 2.0,
          ),
        ),
        child: capsuleContent,
      ),
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

        final capsule = _buildSinglePlayerCapsule(isWide, isCompact, usedColors, availableInvitados);
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
              Expanded(
                flex: isCompact ? 1 : 3,
                child: shield,
              ),
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
