import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../../widgets/app_drawer.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../widgets/tracker_dialogs.dart';
import 'providers/generala_tracker_provider.dart';
import 'widgets/generala_score_table.dart';
import 'widgets/generala_input_panel.dart';
import '../../../core/theme/app_sizes.dart';

class GeneralaTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;
  final String? fullKey;

  const GeneralaTrackerScreen({
    super.key,
    required this.playerCount,
    this.fullKey,
  });

  @override
  ConsumerState<GeneralaTrackerScreen> createState() =>
      _GeneralaTrackerScreenState();
}

class _GeneralaTrackerScreenState
    extends ConsumerState<GeneralaTrackerScreen> {
  bool _completionDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref.read(generalaTrackerProvider.notifier).initialize(
              widget.playerCount,
              user,
              fullKey: widget.fullKey,
            );
      }
    });
  }

  // ── Diálogo de fin de partida (botón guardar) ───────────────────────────────

  void _showFinishDialog(GeneralaTrackerState state) {
    final players = state.entities
        .map((e) => DialogPlayerInfo(e.name, e.total))
        .toList();

    final maxScore = players.isEmpty
        ? 0
        : players.map((p) => p.score).reduce((a, b) => a > b ? a : b);

    final winners = state.entities
        .where((e) => e.total == maxScore)
        .map((e) => e.name)
        .join(' y ');

    TrackerDialogs.showFinishMatchDialog(
      context: context,
      gameId: state.selectedGame?.id,
      gameName: state.selectedGame?.name,
      players: players,
      customWinnerName: winners,
      customMaxScore: maxScore,
      onSaveMatch: (finalScores) async {
        if (state.selectedGame != null) {
          await ref.read(matchServiceProvider).saveMatch(
                gameId: state.selectedGame!.id,
                gameName: state.selectedGame!.name,
                playerScores: finalScores,
                isTeamGame: false,
              );
        }
      },
      onClearState: () =>
          ref.read(generalaTrackerProvider.notifier).clearLocalState(),
      onNavigateHome: () {
        if (mounted) context.go('/home');
      },
    );
  }

  // ── Diálogo de reinicio de puntajes (botón central) ─────────────────────────

  void _showResetDialog() {
    TrackerDialogs.showResetDialog(
      context: context,
      content: 'Todos los puntajes anotados volverán a cero.',
      onConfirm: () {
        ref.read(generalaTrackerProvider.notifier).resetAllScores();
        _completionDialogShown = false;
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generalaTrackerProvider);

    // Detección automática de fin de partida
    ref.listen<GeneralaTrackerState>(generalaTrackerProvider, (prev, next) {
      if (!_completionDialogShown &&
          prev != null &&
          !prev.isComplete &&
          next.isComplete) {
        _completionDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFinishDialog(next);
        });
      }
    });

    if (state.entities.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: TrackerAppBar(
        rightWidget: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GENERALA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(width: 8),
            Icon(Icons.casino, size: 24),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tabla de puntajes (scrolleable) ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 12.0),
                child: const GeneralaScoreTable(),
              ),
            ),

            // ── Panel de entrada ───────────────────────────────────────────────
            const GeneralaInputPanel(),

            // ── Barra inferior (TrackerBottomBar — igual que Akropolis) ────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p24,
                vertical: AppSizes.p16,
              ),
              child: TrackerBottomBar(
                onBack: () => context.pop(),
                onSave: () => _showFinishDialog(state),
                centerWidget: IconButton.filled(
                  iconSize: 28,
                  padding: const EdgeInsets.all(12),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reiniciar puntajes',
                  onPressed: _showResetDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
