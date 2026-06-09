import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/truco_tracker_provider.dart';
import 'truco_action_buttons.dart';
import 'truco_players_footer.dart';
import 'truco_score_section.dart';
import 'truco_team_editor_dialog.dart';
import 'truco_team_header.dart';

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

    final teamColor = teamIndex == 0
        ? const Color(0xFFE53935)
        : const Color(0xFF2F80ED);

    return Column(
      children: [
        TrucoTeamHeader(
          title: team.name,
          color: teamColor,
        ),

        const SizedBox(height: 10),

        TrucoActionButtons(
          color: teamColor,
          onAdd: () => notifier.addMalas(teamIndex, 1),
          onRemove: () => notifier.addMalas(teamIndex, -1),
        ),

        const SizedBox(height: 8),

TrucoScoreSection(
  title: targetScore == 15 ? 'Puntos' : 'Malas',
  labelColor: targetScore == 15
      ? Theme.of(context).colorScheme.primary
      : const Color(0xFFFF8A1C),
  points: team.malas,
  onAddPoint: () => notifier.addMalas(teamIndex, 1),
),

        if (targetScore == 30) ...[
          const SizedBox(height: 12),

TrucoScoreSection(
  title: 'Buenas',
  labelColor: const Color(0xFF16A85A),
  points: team.buenas,
  onAddPoint: () => notifier.addBuenas(teamIndex, 1),
),

          const SizedBox(height: 8),

          TrucoActionButtons(
            color: teamColor,
            onAdd: () => notifier.addBuenas(teamIndex, 1),
            onRemove: () => notifier.addBuenas(teamIndex, -1),
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

        TrucoPlayersFooter(
          teamIndex: teamIndex,
          playerNames: team.playerNames,
          onEdit: () => TrucoTeamEditorDialog.show(
            context,
            ref,
            teamIndex,
          ),
        ),
      ],
    );
  }
}