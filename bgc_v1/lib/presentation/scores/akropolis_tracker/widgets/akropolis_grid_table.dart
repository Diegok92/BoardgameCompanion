import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../providers/akropolis_tracker_provider.dart';
import '../../widgets/tracker_dialogs.dart';
import '../../widgets/player_badge.dart';

class AkropolisGridTable extends ConsumerWidget {
  const AkropolisGridTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(akropolisTrackerProvider);
    return Table(
      border: TableBorder.all(
        color: Theme.of(context).colorScheme.outline,
        width: 1.5,
      ),
      columnWidths: {
        0: const FixedColumnWidth(50),
        for (int i = 0; i < state.entities.length; i++)
          i + 1: const FlexColumnWidth(),
      },
      children: [
        // Header
        TableRow(
          children: [
            const SizedBox(height: 40), // Empty top-left
            for (int i = 0; i < state.entities.length; i++)
              GestureDetector(
                onTap: () {
                  final user = ref.read(authProvider);
                  TrackerDialogs.showEntityEditor(
                    context: context,
                    entityName: state.entities[i].name,
                    entityId: state.entities[i].id,
                    entityColor: state.entities[i].color,
                    entityIndex: i,
                    loggedInUsername: user?.username,
                    invitados: user?.invitados ?? [],
                    assignedNames: state.entities.map((e) => e.name).toList(),
                    assignedColors: state.entities.map((e) => e.color).toList(),
                    onNameChanged: (name) => ref.read(akropolisTrackerProvider.notifier).updateEntity(i, name: name),
                    onColorChanged: (color) => ref.read(akropolisTrackerProvider.notifier).updateEntity(i, color: color),
                    onAddInvitado: () => context.push('/register-invitado'),
                  );
                },
                child: SizedBox(
                  height: 40,
                  child: PlayerBadge(
                    name: state.entities[i].name,
                    color: state.entities[i].color,
                  ),
                ),
              ),
          ],
        ),
        // Hexagons
        for (final hex in AkropolisHexagon.values)
          TableRow(
            children: [
              Container(
                height: 50,
                alignment: Alignment.center,
                child: Icon(
                  hex == AkropolisHexagon.stones ? Icons.square : Icons.hexagon,
                  color: hex.color,
                  size: 36,
                ),
              ),
              for (final entity in state.entities)
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    entity.scores[hex]?.isScored == true ? entity.scores[hex]!.total.toString() : '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        // Total
        TableRow(
          children: [
            Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                'TOTAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            for (final entity in state.entities)
              Container(
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  entity.totalScore.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
