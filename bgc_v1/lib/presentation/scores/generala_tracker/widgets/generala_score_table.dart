import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/generala_tracker_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/tracker_dialogs.dart';
import '../../widgets/player_badge.dart';

class GeneralaScoreTable extends ConsumerWidget {
  const GeneralaScoreTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(generalaTrackerProvider);
    final notifier = ref.read(generalaTrackerProvider.notifier);
    final user     = ref.watch(authProvider); // watch para recargar invitados al volver
    final cs       = Theme.of(context).colorScheme;

    if (state.entities.isEmpty) return const SizedBox.shrink();

    void openEditor(int i) {
      final entity = state.entities[i];
      TrackerDialogs.showEntityEditor(
        context: context,
        entityName: entity.name,
        entityId: entity.id,
        entityColor: entity.color,
        entityIndex: i,
        loggedInUsername: user?.username,
        invitados: user?.invitados ?? [],
        assignedNames: state.entities.map((e) => e.name).toList(),
        assignedColors: state.entities.map((e) => e.color).toList(),
        onNameChanged:  (n) => notifier.updateEntity(i, name: n),
        onColorChanged: (c) => notifier.updateEntity(i, color: c),
        onAddInvitado:  () => context.push('/register-invitado'),
      );
    }

    // ── Celda de puntaje ──────────────────────────────────────────────────────
    Widget scoreCell(GeneralaEntity entity, GeneralaCategory cat) {
      final score = entity.scores[cat];
      String text;
      Color  color;

      if (score == null) {
        text  = '';
        color = Colors.transparent;
      } else if (score == 0) {
        text  = '—';
        color = cs.onSurface.withValues(alpha: 0.3);
      } else {
        text  = score.toString();
        color = entity.color;
      }

      return Container(
        height: 38,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    return Table(
      border: TableBorder.all(
        color: cs.outline,
        width: 1.5,
      ),
      columnWidths: {
        0: const FixedColumnWidth(88),
        for (int i = 0; i < state.entities.length; i++)
          i + 1: const FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // ── Encabezado: nombres de jugadores ──────────────────────────────────
        TableRow(
          children: [
            const SizedBox(height: 46), // celda vacía arriba-izquierda
            for (int i = 0; i < state.entities.length; i++)
              GestureDetector(
                onTap: () => openEditor(i),
                child: SizedBox(
                  height: 46,
                  child: PlayerBadge(
                    name: state.entities[i].name,
                    color: state.entities[i].color,
                  ),
                ),
              ),
          ],
        ),

        // ── Filas de categorías ───────────────────────────────────────────────
        for (final cat in GeneralaCategory.values)
          TableRow(
            children: [
              Container(
                height: 38,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  cat.tableLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                ),
              ),
              for (final entity in state.entities) scoreCell(entity, cat),
            ],
          ),

        // ── Fila de total ─────────────────────────────────────────────────────
        TableRow(
          children: [
            Container(
              height: 46,
              alignment: Alignment.center,
              child: Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            for (final entity in state.entities)
              Container(
                height: 46,
                alignment: Alignment.center,
                child: Text(
                  entity.total.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: entity.color,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
