
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// removed app colors
import '../../../data/local_catalog/local_games_catalog.dart';
import '../../../domain/models/game_model.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import 'providers/hp_tracker_provider.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../widgets/tracker_dialogs.dart';
import 'widgets/hp_player_card.dart';

class HpTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;
  const HpTrackerScreen({super.key, required this.playerCount});

  @override
  ConsumerState<HpTrackerScreen> createState() => _HpTrackerScreenState();
}

class _HpTrackerScreenState extends ConsumerState<HpTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref
            .read(hpTrackerProvider.notifier)
            .initialize(widget.playerCount, user, 50);
      }
    });
  }


  int _getCrossAxisCount(int players, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      if (players <= 3) return 1; // 1, 2 y 3 jugadores ocupan todo el ancho
      return 2; // 4, 5 y 6 jugadores se dividen en 2 columnas
    } else {
      if (players <= 3) return players;
      if (players == 4) return 2;
      return 3;
    }
  }

  Widget _buildDropdownWidget(
    HpTrackerState state,
    List<Game> allDropdownGames,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Game?>(
          value: state.selectedGame,
          hint: const Text('Juego', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          items: [
            DropdownMenuItem<Game?>(
              value: null,
              child: Text(
                'Sin Asignar',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            ...allDropdownGames.map((g) {
              return DropdownMenuItem<Game?>(
                value: g,
                child: Text(
                  g.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
          ],
          onChanged: (val) {
            ref.read(hpTrackerProvider.notifier).selectGame(val);
          },
        ),
      ),
    );
  }

  // _buildSaveButton removed
  Widget _buildControls(HpTrackerState state) {
    return TrackerBottomBar(
      onBack: () async {
        final nav = Navigator.of(context);
        await ref.read(hpTrackerProvider.notifier).saveLocalState();
        nav.pop();
      },
      onSave: () {
        final user = ref.read(authProvider);
        if (user == null) return;
        TrackerDialogs.showFinishMatchDialog(
          context: context,
          gameId: state.selectedGame?.id,
          gameName: state.selectedGame?.name,
          players: state.players.map((p) => DialogPlayerInfo(p.name, p.hp)).toList(),
          onSaveMatch: (finalScores) async {
            await ref.read(matchServiceProvider).saveMatch(
              gameId: state.selectedGame!.id,
              gameName: state.selectedGame!.name,
              playerScores: finalScores,
              isTeamGame: false,
            );
          },
          onClearState: () => ref.read(hpTrackerProvider.notifier).clearLocalState(),
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
            'Vida Inicial',
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  TrackerDialogs.showNumberInputDialog(
                    context: context,
                    title: 'Setear Vida Inicial',
                    label: 'Vida Inicial',
                    initialValue: state.initialHp,
                    onConfirm: (val) => ref.read(hpTrackerProvider.notifier).setInitialHp(val),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${state.initialHp}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
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
                    onConfirm: () => ref.read(hpTrackerProvider.notifier).resetHp(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    HpTrackerState state,
    List<String> invitados,
    Orientation orientation,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _getCrossAxisCount(
          state.players.length,
          orientation,
        );
        int rowCount = (state.players.length / crossAxisCount).ceil();

        double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
        double itemHeight =
            (constraints.maxHeight - (rowCount - 1) * 8) / rowCount;
        double aspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: state.players.length,
          itemBuilder: (context, index) {
            return HpPlayerCard(
              player: state.players[index],
              invitados: invitados,
              allPlayers: state.players,
              onNameChanged: (name) {
                if (name == 'NUEVO_INVITADO') {
                  context.push('/register-invitado');
                } else {
                  ref
                      .read(hpTrackerProvider.notifier)
                      .updatePlayerName(index, name!);
                }
              },
              onColorChanged: (color) {
                ref
                    .read(hpTrackerProvider.notifier)
                    .updatePlayerColor(index, color);
              },
              onHpChange: (delta) {
                ref.read(hpTrackerProvider.notifier).addHp(index, delta);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hpTrackerProvider);
    if (state.players.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authProvider);
    final invitados = user?.invitados ?? [];
    final allDropdownGames = LocalGamesCatalog.trackerGames;

    return Scaffold(
      appBar: TrackerAppBar(
        rightWidget: SizedBox(
          width: 200,
          child: _buildDropdownWidget(state, allDropdownGames),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 16.0,
                        ),
                        child: _buildGrid(state, invitados, orientation),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 16.0, right: 16.0), // Equilibré el padding de los controles
                      child: _buildControls(state),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: Border(
                          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () =>
                                      Scaffold.of(context).openDrawer(),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/logo.svg',
                                        height: 40,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'BG Companion',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownWidget(state, allDropdownGames),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildControls(state),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildGrid(state, invitados, orientation),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
