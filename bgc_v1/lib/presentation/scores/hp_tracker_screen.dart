import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/game_model.dart';
import '../../domain/models/partida_model.dart';
import '../../data/local_catalog/local_games_catalog.dart';
import '../../data/repositories/partidas_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/hp_tracker_provider.dart';

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
        // Initialize immediately without popup
        ref
            .read(hpTrackerProvider.notifier)
            .initialize(
              widget.playerCount,
              user,
              50, // Default initial HP
            );
      }
    });
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

    // Validación de nombres asignados
    if (state.players.any((p) => p.name == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes asignar un invitado a todos los jugadores.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validación de juego asignado
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
              Navigator.pop(context); // Cierra popup
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
      // Determinar ganadores (el/los que tengan más vida, o usar otra lógica)
      // Como es HP, asumimos que el ganador es el que tiene más puntos de vida al finalizar.
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
        id: '', // Se autogenera
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
        context.go('/home'); // Volver al inicio
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hpTrackerProvider);
    if (state.players.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authProvider);
    final invitados = user?.invitados ?? [];

    // Solo los trackerGames en orden alfabético
    final allDropdownGames = LocalGamesCatalog.trackerGames;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Personalizado
            Padding(
              padding: const EdgeInsets.only(
                left: 4.0,
                right: 12.0,
                top: 12.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Game?>(
                          value: state.selectedGame,
                          hint: const Text(
                            'Juego',
                            style: TextStyle(fontSize: 14),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                          items: [
                            const DropdownMenuItem<Game?>(
                              value: null,
                              child: Text(
                                'Sin Asignar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
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
                            ref
                                .read(hpTrackerProvider.notifier)
                                .selectGame(val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _confirmFinishMatch,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Terminar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset('assets/images/logo.svg', height: 32),
                ],
              ),
            ),

            // Tablero de Jugadores (Ajustado para no scrollear nunca)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = widget.playerCount > 2 ? 2 : 1;
                    int rowCount = (widget.playerCount / crossAxisCount).ceil();

                    // Cálculo de aspect ratio para que entre exacto en el espacio sin scroll
                    double itemWidth =
                        (constraints.maxWidth - (crossAxisCount - 1) * 8) /
                        crossAxisCount;
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
                        return _PlayerShieldCard(
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
                          onAdd: () => ref
                              .read(hpTrackerProvider.notifier)
                              .addHp(index, 1),
                          onSub: () => ref
                              .read(hpTrackerProvider.notifier)
                              .addHp(index, -1),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Panel Inferior: Vida Inicial y Reseteo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Vida Inicial:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.blue),
                          onPressed: () => ref
                              .read(hpTrackerProvider.notifier)
                              .changeInitialHp(-1),
                        ),
                        Text(
                          '${state.initialHp}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.blue),
                          onPressed: () => ref
                              .read(hpTrackerProvider.notifier)
                              .changeInitialHp(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerShieldCard extends StatelessWidget {
  final TrackerPlayer player;
  final List<String> invitados;
  final List<TrackerPlayer> allPlayers;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  const _PlayerShieldCard({
    required this.player,
    required this.invitados,
    required this.allPlayers,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onAdd,
    required this.onSub,
  });

  void _showColorPicker(BuildContext context) {
    // Filtrar colores ya elegidos por otros jugadores
    final usedColors = allPlayers.map((p) => p.color.toARGB32()).toSet();
    final available = AppColors.availableColors
        .where(
          (c) =>
              !usedColors.contains(c.toARGB32()) ||
              c.toARGB32() == player.color.toARGB32(),
        )
        .toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elegir Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: available.map((color) {
              return GestureDetector(
                onTap: () {
                  onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = player.index == 0;

    return Column(
      children: [
        // Bloque de Nombre y Color (Cápsula Unificada)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: player.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: player.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Mantiene todo junto y centrado
              children: [
                // Selector de Color
                GestureDetector(
                  onTap: () => _showColorPicker(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: player.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: player.color,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Separador visual
                Container(
                  width: 1.5,
                  height: 24,
                  color: player.color.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                // Selector de Nombre
                Flexible(
                  child: isUser
                      ? Text(
                          player.name ?? 'Usuario',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: player.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : PopupMenuButton<String>(
                          initialValue: player.name,
                          onSelected: onNameChanged,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (BuildContext context) {
                            return [
                              ...invitados.map(
                                (i) => PopupMenuItem(
                                  value: i,
                                  child: Text(
                                    i,
                                    style: TextStyle(
                                      color: player.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'NUEVO_INVITADO',
                                child: Text(
                                  '+ Agregar...',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ];
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  player.name ?? 'Jugador ${player.index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: player.name == null
                                        ? player.color.withValues(alpha: 0.6)
                                        : player.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: player.color),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // Escudo Gigante Interactivo sin Card (Usa LayoutBuilder para maximizar)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Hacemos el escudo tan grande como el espacio disponible
              double shieldSize = constraints.biggest.shortestSide * 0.9;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Fondo de Escudo gigante usando Icono y sombras para dar relieve
                  Icon(
                    Icons.shield,
                    size: shieldSize, // Muy grande dinámico
                    color: player.color.withValues(alpha: 0.2),
                  ),
                  Icon(
                    Icons.shield_outlined,
                    size: shieldSize,
                    color: player.color,
                  ),
                  // Número Central
                  Text(
                    '${player.hp}',
                    style: TextStyle(
                      fontSize: shieldSize * 0.35, // Número súper grande
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // Chevrones con posicionamiento exacto
                  const Align(
                    alignment: Alignment(0, -0.55),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      size: 64,
                      color: Colors.black45,
                    ),
                  ),
                  const Align(
                    alignment: Alignment(0, 0.55),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 64,
                      color: Colors.black45,
                    ),
                  ),
                  // Zonas Táctiles Invisibles (Mitad Superior y Mitad Inferior completas)
                  Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onAdd,
                          child: Container(),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onSub,
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
