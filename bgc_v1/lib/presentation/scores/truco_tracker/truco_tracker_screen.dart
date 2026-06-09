import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../../widgets/app_drawer.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../widgets/tracker_dialogs.dart';
import 'providers/truco_tracker_provider.dart';
import 'widgets/truco_score_column.dart';

class TrucoTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;
  final String? fullKey;

  const TrucoTrackerScreen({
    super.key,
    required this.playerCount,
    this.fullKey,
  });

  @override
  ConsumerState<TrucoTrackerScreen> createState() => _TrucoTrackerScreenState();
}

class _TrucoTrackerScreenState extends ConsumerState<TrucoTrackerScreen> {
  bool _winnerDialogShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);

      if (user != null) {
        ref.read(trucoTrackerProvider.notifier).initialize(
              widget.playerCount,
              user,
              fullKey: widget.fullKey,
            );
      }
    });
  }

  void _showFinishMatchDialog() {
    final state = ref.read(trucoTrackerProvider);

    if (state.teams.length < 2) return;

    final winner = state.winner;
    final maxScore = winner?.totalPoints ??
        state.teams
            .map((team) => team.totalPoints)
            .reduce((a, b) => a > b ? a : b);

    final winners = winner?.name ??
        state.teams
            .where((team) => team.totalPoints == maxScore)
            .map((team) => team.name)
            .join(' y ');

    final flattenedPlayers = <DialogPlayerInfo>[];

    for (final team in state.teams) {
      for (final player in team.playerNames) {
        flattenedPlayers.add(
          DialogPlayerInfo(
            player,
            team.totalPoints,
          ),
        );
      }
    }

    final gameId = state.selectedGame?.id ?? 'truco';
    final gameName = state.selectedGame?.name ?? 'Truco';

    TrackerDialogs.showFinishMatchDialog(
      context: context,
      gameId: gameId,
      gameName: gameName,
      players: flattenedPlayers,
      customWinnerName: winners,
      customMaxScore: maxScore,
      onSaveMatch: (finalScores) async {
        await ref.read(matchServiceProvider).saveMatch(
              gameId: gameId,
              gameName: gameName,
              playerScores: finalScores,
              isTeamGame: widget.playerCount != 2,
            );
      },
onClearState: () {
  ref.read(trucoTrackerProvider.notifier).clearLocalState();
},
      onNavigateHome: () {
        if (mounted) context.go('/home');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(trucoTrackerProvider, (previous, next) {
      final winner = next.winner;

      if (winner != null && !_winnerDialogShown) {
        _winnerDialogShown = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showFinishMatchDialog();
        });
      }

      if (winner == null) {
        _winnerDialogShown = false;
      }
    });

    final state = ref.watch(trucoTrackerProvider);

    if (state.teams.length < 2) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final nosotros = state.teams[0];
    final ellos = state.teams[1];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: TrackerAppBar(
        rightWidget: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TRUCO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.style,
              size: 24,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              _TargetScoreSelector(
                selectedTarget: state.targetScore,
                onChanged: (value) {
                  ref.read(trucoTrackerProvider.notifier).setTargetScore(value);
                },
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TrucoScoreColumn(
                          teamIndex: 0,
                          team: nosotros,
                          targetScore: state.targetScore,
                        ),
                      ),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: TrucoScoreColumn(
                          teamIndex: 1,
                          team: ellos,
                          targetScore: state.targetScore,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              TrackerBottomBar(
                onBack: () {
                  Navigator.pop(context);
                },
                onSave: () {
                  _showFinishMatchDialog();
                },
                centerWidget: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  iconSize: 20,
                  padding: const EdgeInsets.all(12),
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () {
                    TrackerDialogs.showResetDialog(
                      context: context,
                      onConfirm: () {
                        ref.read(trucoTrackerProvider.notifier).resetGame();
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetScoreSelector extends StatelessWidget {
  final int selectedTarget;
  final ValueChanged<int> onChanged;

  const _TargetScoreSelector({
    required this.selectedTarget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TargetOption(
            label: 'A 15',
            value: 15,
            selectedTarget: selectedTarget,
            onChanged: onChanged,
          ),
          const SizedBox(width: 4),
          _TargetOption(
            label: 'A 30',
            value: 30,
            selectedTarget: selectedTarget,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TargetOption extends StatelessWidget {
  final String label;
  final int value;
  final int selectedTarget;
  final ValueChanged<int> onChanged;

  const _TargetOption({
    required this.label,
    required this.value,
    required this.selectedTarget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTarget == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}