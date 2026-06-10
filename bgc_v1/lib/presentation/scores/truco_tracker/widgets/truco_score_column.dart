import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../widgets/player_badge.dart';
import '../providers/truco_tracker_provider.dart';
import 'truco_action_buttons.dart';
import 'truco_score_section.dart';
import 'truco_team_editor_dialog.dart';

class TrucoScoreColumn extends ConsumerWidget {
  final int teamIndex;
  final TrucoTeam team;
  final int targetScore;

  const TrucoScoreColumn({
    super.key,
    required this.teamIndex,
    required this.team,
    required this.targetScore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(trucoTrackerProvider.notifier);

    final teamColor = team.color;

    return Column(
      children: [
        PlayerBadge(
          name: team.name,
          color: teamColor,
          width: double.infinity,
          height: 38,
          onTap: () => TrucoTeamEditorDialog.show(context, ref, teamIndex),
        ),

        const SizedBox(height: 10),

        TrucoActionButtons(
          color: teamColor,
          onAdd: () => notifier.addPoint(teamIndex, 1),
          onRemove: () => notifier.addPoint(teamIndex, -1),
        ),

        const SizedBox(height: 8),

        TrucoScoreSection(
          // En "A 15" hay una sola tira: el cartel sobra (son puntos obvios).
          title: 'Malas',
          labelColor: AppColors.trucoMalas,
          points: team.malas,
          showLabel: targetScore == 30,
          onAddPoint: () => notifier.addPoint(teamIndex, 1),
        ),

        if (targetScore == 30) ...[
          const SizedBox(height: 12),

          TrucoScoreSection(
            title: 'Buenas',
            labelColor: AppColors.trucoBuenas,
            points: team.buenas,
            onAddPoint: () => notifier.addPoint(teamIndex, 1),
          ),
        ],

        const Spacer(),

        Container(
          width: double.infinity,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${team.totalPoints} pts',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Nombres de los jugadores. Al tocarlos se abre el mismo editor que el
        // header (Nosotros/Ellos), para asignar invitados y color.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => TrucoTeamEditorDialog.show(context, ref, teamIndex),
          child: Column(
            children: [
              for (int i = 0; i < team.playerNames.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    team.playerNames[i] ??
                        'Jugador ${(teamIndex * team.playerNames.length) + i + 1}',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: team.playerNames[i] == null
                          ? FontWeight.w600
                          : FontWeight.w900,
                      color: team.playerNames[i] == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
