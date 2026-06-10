import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/team_editor_dialog.dart';
import '../providers/burako_tracker_provider.dart';

/// Abre el editor de entidad (compartido) para una entidad/equipo del Burako:
/// asigna invitados a cada posición y elige el color.
class BurakoEntityEditorDialog {
  static void show(BuildContext context, WidgetRef ref, int entityIndex) {
    final state = ref.read(burakoTrackerProvider);
    if (entityIndex < 0 || entityIndex >= state.entities.length) return;

    final user = ref.read(authProvider);
    final entity = state.entities[entityIndex];
    final allNames = [for (final e in state.entities) e.playerNames];
    final allColors = [for (final e in state.entities) e.color];

    // El usuario logueado queda fijo en el primer slot de la primera entidad.
    final lockedFirstSlotLabel = (entityIndex == 0 && user != null)
        ? 'Jugador 1: ${user.username}'
        : null;

    TeamEditorDialog.show(
      context,
      title: 'Editar ${entity.name}',
      currentNames: entity.playerNames,
      firstPlayerNumber: TeamEditorDialog.firstPlayerNumber(
        allNames,
        entityIndex,
      ),
      invitados: user?.invitados ?? [],
      canAssign: TeamEditorDialog.canAssignBuilder(allNames, entityIndex),
      lockedFirstSlotLabel: lockedFirstSlotLabel,
      onNameChanged: (slot, name) => ref
          .read(burakoTrackerProvider.notifier)
          .updatePlayerNameInEntity(entityIndex, slot, name),
      onAddInvitado: () => context.push('/register-invitado'),
      currentColor: entity.color,
      takenColors: TeamEditorDialog.takenColors(allColors, entityIndex),
      onColorChanged: (color) => ref
          .read(burakoTrackerProvider.notifier)
          .updateEntityColor(entityIndex, color),
    );
  }
}
