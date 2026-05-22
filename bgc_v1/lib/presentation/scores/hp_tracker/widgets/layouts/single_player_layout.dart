import 'package:flutter/material.dart';
import '../../providers/hp_tracker_provider.dart';
import '../components/hp_shield.dart';
import '../components/player_color_picker.dart';
import '../components/player_name_dropdown.dart';

class SinglePlayerLayout extends StatelessWidget {
  final TrackerPlayer player;
  final List<String> invitados;
  final Set<int> usedColorsArgb;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onHpChange;

  const SinglePlayerLayout({
    super.key,
    required this.player,
    required this.invitados,
    required this.usedColorsArgb,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onHpChange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > constraints.maxHeight * 1.3;

        final colorSelector = PlayerColorPicker(
          playerColor: player.color,
          usedColorsArgb: usedColorsArgb,
          onColorChanged: onColorChanged,
        );

        final nameSelector = PlayerNameDropdown(
          isUser: player.index == 0,
          playerName: player.name,
          playerIndex: player.index,
          playerColor: player.color,
          invitados: invitados,
          onNameChanged: onNameChanged,
        );

        Widget capsuleContent;
        if (isWide) {
          capsuleContent = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              colorSelector,
              const SizedBox(height: 6),
              Container(
                height: 1.5,
                width: 32,
                color: player.color.withValues(alpha: 0.3),
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
              const SizedBox(width: 16),
              Container(
                width: 2,
                height: 32,
                color: player.color.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Flexible(child: nameSelector),
            ],
          );
        }

        final capsule = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 4.0 : 16.0,
            vertical: isWide ? 16.0 : 4.0,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 8 : 24,
              vertical: isWide ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: player.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: player.color.withValues(alpha: 0.3),
                width: 2.0,
              ),
            ),
            child: capsuleContent,
          ),
        );

        final shield = Expanded(
          child: HpShield(
            hp: player.hp,
            color: player.color,
            onHpChange: onHpChange,
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 1, child: Center(child: capsule)),
              Expanded(flex: 2, child: shield),
            ],
          );
        } else {
          return Column(
            children: [
              const SizedBox(height: 16),
              capsule,
              shield,
            ],
          );
        }
      },
    );
  }
}
