import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../../widgets/app_drawer.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../widgets/tracker_dialogs.dart';
import '../widgets/tracker_game_dropdown.dart';
import 'providers/standard_scoreboard_provider.dart';
import 'widgets/score_player_card.dart';

class StandardScoreboardScreen extends ConsumerStatefulWidget {
  final int playerCount;
  final String? fullKey;

  const StandardScoreboardScreen({
    super.key,
    required this.playerCount,
    this.fullKey,
  });

  @override
  ConsumerState<StandardScoreboardScreen> createState() =>
      _StandardScoreboardScreenState();
}

class _StandardScoreboardScreenState
    extends ConsumerState<StandardScoreboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref
            .read(standardScoreboardProvider.notifier)
            .initialize(widget.playerCount, user, fullKey: widget.fullKey);
      }
    });
  }

  int _getCrossAxisCount(int players) => players <= 3 ? 1 : 2;

  Widget _buildDropdown(StandardScoreboardState state) {
    return TrackerGameDropdown(
      selectedGame: state.selectedGame,
      onChanged: (game) =>
          ref.read(standardScoreboardProvider.notifier).selectGame(game),
    );
  }

  Widget _buildGrid(StandardScoreboardState state, List<String> invitados) {
    final crossAxisCount = _getCrossAxisCount(state.players.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (state.players.length / crossAxisCount).ceil();
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
        final itemHeight = (constraints.maxHeight - (rows - 1) * 12) / rows;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.players.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return ScorePlayerCard(
              player: state.players[index],
              allPlayers: state.players,
              invitados: invitados,
              onNameChanged: (name) {
                if (name == 'NUEVO_INVITADO') {
                  context.push('/register-invitado');
                } else if (name != null) {
                  ref
                      .read(standardScoreboardProvider.notifier)
                      .updatePlayerName(index, name);
                }
              },
              onColorChanged: (color) => ref
                  .read(standardScoreboardProvider.notifier)
                  .updatePlayerColor(index, color),
              onScoreChange: (delta) => ref
                  .read(standardScoreboardProvider.notifier)
                  .addScore(index, delta),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(StandardScoreboardState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return TrackerBottomBar(
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      onSave: () {
        final user = ref.read(authProvider);
        if (user == null) return;
        TrackerDialogs.showFinishMatchDialog(
          context: context,
          gameId: state.selectedGame?.id,
          gameName: state.selectedGame?.name,
          players: state.players
              .map((p) => DialogPlayerInfo(p.name, p.score))
              .toList(),
          onSaveMatch: (finalScores) async {
            await ref
                .read(matchServiceProvider)
                .saveMatch(
                  gameId: state.selectedGame!.id,
                  gameName: state.selectedGame!.name,
                  playerScores: finalScores,
                  isTeamGame: false,
                );
          },
          onClearState: () =>
              ref.read(standardScoreboardProvider.notifier).clearLocalState(),
          onNavigateHome: () {
            if (mounted) context.go('/home');
          },
        );
      },
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Puntaje Inicial',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  TrackerDialogs.showNumberInputDialog(
                    context: context,
                    title: 'Setear Puntaje Inicial',
                    label: 'Puntaje Inicial',
                    initialValue: state.initialScore,
                    onConfirm: (val) => ref
                        .read(standardScoreboardProvider.notifier)
                        .setInitialScore(val),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${state.initialScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                iconSize: 20,
                padding: const EdgeInsets.all(12),
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reiniciar puntajes',
                onPressed: () {
                  TrackerDialogs.showResetDialog(
                    context: context,
                    content:
                        'Todos los jugadores volverán al puntaje inicial.',
                    onConfirm: () => ref
                        .read(standardScoreboardProvider.notifier)
                        .resetScores(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standardScoreboardProvider);
    if (state.players.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authProvider);
    final invitados = user?.invitados ?? [];

    return Scaffold(
      appBar: TrackerAppBar(
        rightWidget: SizedBox(width: 200, child: _buildDropdown(state)),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: _buildGrid(state, invitados),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: _buildControls(state),
            ),
          ],
        ),
      ),
    );
  }
}
