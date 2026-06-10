import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/team_editor_dialog.dart';
import '../providers/truco_tracker_provider.dart';

/// Abre el editor de equipo (compartido) para un equipo del Truco: permite
/// asignar invitados a cada posición y elegir el color del equipo.
class TrucoTeamEditorDialog {
  static void show(BuildContext context, WidgetRef ref, int teamIndex) {
    final state = ref.read(trucoTrackerProvider);
    if (teamIndex < 0 || teamIndex >= state.teams.length) return;

    final user = ref.read(authProvider);
    final team = state.teams[teamIndex];
    final allNames = [for (final t in state.teams) t.playerNames];
    final allColors = [for (final t in state.teams) t.color];

    // El usuario logueado queda fijo como Jugador 1 del equipo "Nosotros".
    final lockedFirstSlotLabel = (teamIndex == 0 && user != null)
        ? 'Jugador 1: ${user.username}'
        : null;

    TeamEditorDialog.show(
      context,
      title: 'Editar ${team.name}',
      currentNames: team.playerNames,
      firstPlayerNumber: TeamEditorDialog.firstPlayerNumber(
        allNames,
        teamIndex,
      ),
      invitados: user?.invitados ?? [],
      canAssign: TeamEditorDialog.canAssignBuilder(allNames, teamIndex),
      lockedFirstSlotLabel: lockedFirstSlotLabel,
      onNameChanged: (slot, name) => ref
          .read(trucoTrackerProvider.notifier)
          .updatePlayerNameInTeam(teamIndex, slot, name),
      onAddInvitado: () => context.push('/register-invitado'),
      currentColor: team.color,
      takenColors: TeamEditorDialog.takenColors(allColors, teamIndex),
      onColorChanged: (color) => ref
          .read(trucoTrackerProvider.notifier)
          .updateTeamColor(teamIndex, color),
    );
  }
}
