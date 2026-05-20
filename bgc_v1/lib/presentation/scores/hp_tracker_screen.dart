import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/game_model.dart';
import '../../domain/models/partida_model.dart';
import '../../data/local_catalog/local_games_catalog.dart';
import '../../data/repositories/partidas_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/hp_tracker_provider.dart';
import '../widgets/app_drawer.dart';
import 'widgets/hp_tracker/layouts/single_player_layout.dart';
import 'widgets/hp_tracker/hp_player_card.dart';

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

  Widget _buildSinglePlayerLayout(HpTrackerState state, List<String> invitados) {
    if (state.players.isEmpty) return const SizedBox.shrink();
    final usedColors = state.players.map((p) => p.color.toARGB32()).toSet();
    return SinglePlayerLayout(
      player: state.players.first,
      invitados: invitados,
      usedColorsArgb: usedColors,
      onNameChanged: (val) {
        if (val == 'NUEVO_INVITADO') {
          context.push('/register-invitado');
        } else if (val != null) {
          ref.read(hpTrackerProvider.notifier).updatePlayerName(0, val);
        }
      },
      onColorChanged: (color) {
        ref.read(hpTrackerProvider.notifier).updatePlayerColor(0, color);
      },
      onHpChange: (delta) {
        ref.read(hpTrackerProvider.notifier).addHp(0, delta);
      },
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Resetear contadores?'),
        content: const Text(
          'Todos los jugadores volverán al valor inicial de la partida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(hpTrackerProvider.notifier).resetHp();
              Navigator.pop(context);
            },
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  void _confirmFinishMatch() {
    final state = ref.read(hpTrackerProvider);
    final user = ref.read(authProvider);

    if (user == null) return;

    if (state.players.any((p) => p.name == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes asignar un invitado a todos los jugadores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (state.selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar un juego para registrar la partida.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar Partida?'),
        content: const Text(
          '¿Estás seguro de que deseas terminar y registrar esta partida en tu historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveMatch(state, user.id);
            },
            child: const Text('Registrar Partida'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMatch(HpTrackerState state, String userId) async {
    try {
      int maxHp = state.players
          .map((p) => p.hp)
          .reduce((a, b) => a > b ? a : b);
      List<String> ganadores = state.players
          .where((p) => p.hp == maxHp)
          .map((p) => p.name!)
          .toList();

      Map<String, int> puntajes = {};
      for (var p in state.players) {
        puntajes[p.name!] = p.hp;
      }

      final partida = Partida(
        id: '',
        juegoId: state.selectedGame!.id,
        juegoNombre: state.selectedGame!.name,
        participantes: state.players.map((p) => p.name!).toList(),
        ganadores: ganadores,
        puntajesFinales: puntajes,
        estado: 'finalizada',
      );

      final repo = PartidasRepository();
      await repo.registrarPartida(userId, partida);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partida registrada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Game?>(
          value: state.selectedGame,
          hint: const Text('Juego', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          items: [
            const DropdownMenuItem<Game?>(
              value: null,
              child: Text(
                'Sin Asignar',
                style: TextStyle(fontSize: 14, color: Colors.black54),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vida Inicial',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.restart_alt, color: Colors.white),
                    onPressed: _confirmReset,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.blue),
                        onPressed: () => ref.read(hpTrackerProvider.notifier).changeInitialHp(-1),
                      ),
                      Text(
                        '${state.initialHp}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () => ref.read(hpTrackerProvider.notifier).changeInitialHp(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _confirmFinishMatch,
          ),
        ),
      ],
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
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.grey[50]!],
          ),
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 12.0,
                        bottom: 8.0,
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: SvgPicture.asset(
                                'assets/images/logo.svg',
                                height: 40,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 200,
                            child: _buildDropdownWidget(
                              state,
                              allDropdownGames,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: state.players.length == 1
                            ? _buildSinglePlayerLayout(state, invitados)
                            : _buildGrid(state, invitados, orientation),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 32.0, left: 16.0, right: 16.0),
                      child: _buildControls(state),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(hpTrackerProvider.notifier).saveLocalState();
                            if (context.mounted) context.pop();
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al Inicio', style: TextStyle(fontSize: 16)),
                        ),
                      ),
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
                        color: Colors.white.withValues(alpha: 0.5),
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
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
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    height: 40,
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
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(hpTrackerProvider.notifier).saveLocalState();
                              if (context.mounted) context.pop();
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver al Inicio'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: state.players.length == 1
                            ? _buildSinglePlayerLayout(state, invitados)
                            : _buildGrid(state, invitados, orientation),
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
