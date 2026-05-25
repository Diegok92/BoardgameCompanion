import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import '../../widgets/app_drawer.dart';
import 'providers/akropolis_tracker_provider.dart';
import '../widgets/tracker_dialogs.dart';

class AkropolisTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;

  const AkropolisTrackerScreen({super.key, required this.playerCount});

  @override
  ConsumerState<AkropolisTrackerScreen> createState() =>
      _AkropolisTrackerScreenState();
}

class _AkropolisTrackerScreenState
    extends ConsumerState<AkropolisTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref
            .read(akropolisTrackerProvider.notifier)
            .initialize(widget.playerCount, user);
      }
    });
  }

  void _showEntityEditor(int entityIndex) {
    final user = ref.read(authProvider);
    final invitados = user?.invitados ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentState = ref.read(akropolisTrackerProvider);
            final currentEntity = currentState.entities[entityIndex];

            return AlertDialog(
              title: Text(
                'Editar ${currentEntity.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entityIndex == 0 && user != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Jugador 1: ${user.username}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                      )
                    else if (currentEntity.id == 'ilustre')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Jugador Virtual: Ilustre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Jugador ${entityIndex + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: currentEntity.name.startsWith('Jugador')
                              ? null
                              : currentEntity.name,
                          items: [
                            ...invitados
                                .where((inv) {
                                  for (
                                    int i = 0;
                                    i < currentState.entities.length;
                                    i++
                                  ) {
                                    if (i == entityIndex) continue;
                                    if (currentState.entities[i].name == inv)
                                      return false;
                                  }
                                  return true;
                                })
                                .map(
                                  (inv) => DropdownMenuItem(
                                    value: inv,
                                    child: Text(inv),
                                  ),
                                ),
                            const DropdownMenuItem(
                              value: 'NUEVO_INVITADO',
                              child: Text(
                                '+ Agregar Invitado',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            if (currentEntity.name.startsWith('Jugador'))
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Sin Asignar',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == 'NUEVO_INVITADO') {
                              Navigator.pop(context);
                              context.push('/register-invitado');
                            } else {
                              ref
                                  .read(akropolisTrackerProvider.notifier)
                                  .updateEntity(
                                    entityIndex,
                                    name: val ?? 'Jugador ${entityIndex + 1}',
                                  );
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Elige color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppColors.availableColors
                          .where((color) {
                            return !currentState.entities.any(
                              (e) =>
                                  e.id != currentEntity.id &&
                                  e.color.toARGB32() == color.toARGB32(),
                            );
                          })
                          .map((color) {
                            return InkWell(
                              onTap: () {
                                ref
                                    .read(akropolisTrackerProvider.notifier)
                                    .updateEntity(entityIndex, color: color);
                                Navigator.pop(context);
                              },
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 16,
                                child:
                                    currentEntity.color.toARGB32() ==
                                        color.toARGB32()
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getExplanation(AkropolisHexagon hex) {
    switch (hex) {
      case AkropolisHexagon.blue:
        return "Residencias (Azul): Solo puntúa el grupo contiguo más grande.";
      case AkropolisHexagon.yellow:
        return "Mercados (Amarillo): Solo puntúan los que NO están adyacentes a otro mercado.";
      case AkropolisHexagon.red:
        return "Cuarteles (Rojo): Solo puntúan los que están en los bordes de la ciudad.";
      case AkropolisHexagon.purple:
        return "Templos (Violeta): Solo puntúan los que están completamente rodeados.";
      case AkropolisHexagon.green:
        return "Jardines (Verde): Puntúan siempre, sin restricciones.";
      case AkropolisHexagon.stones:
        return "Piedras: Valen 1 punto cada una.";
    }
  }

  Color _getHexColor(AkropolisHexagon hex) {
    switch (hex) {
      case AkropolisHexagon.blue:
        return Colors.blue;
      case AkropolisHexagon.yellow:
        return Colors.amber;
      case AkropolisHexagon.red:
        return Colors.red;
      case AkropolisHexagon.purple:
        return Colors.purple;
      case AkropolisHexagon.green:
        return Colors.green;
      case AkropolisHexagon.stones:
        return Colors.grey;
    }
  }

  // Removed _getHexName

  // Removed _showInfoDialog

  void _showNumberPad(
    String title,
    int initialValue,
    String explanation,
    Function(int) onConfirm,
  ) {
    int currentValue = initialValue;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void appendDigit(int digit) {
              setDialogState(() {
                if (currentValue.toString().length < 4) {
                  currentValue = int.parse('$currentValue$digit');
                }
              });
            }

            void backspace() {
              setDialogState(() {
                if (currentValue > 9) {
                  currentValue = int.parse(
                    currentValue.toString().substring(
                      0,
                      currentValue.toString().length - 1,
                    ),
                  );
                } else {
                  currentValue = 0;
                }
              });
            }

            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentValue.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: Builder(
                      builder: (context) {
                        Widget buildNumBtn(int i) {
                          return Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => appendDigit(i),
                              child: Text(
                                i.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                buildNumBtn(1),
                                const SizedBox(width: 8),
                                buildNumBtn(2),
                                const SizedBox(width: 8),
                                buildNumBtn(3),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildNumBtn(4),
                                const SizedBox(width: 8),
                                buildNumBtn(5),
                                const SizedBox(width: 8),
                                buildNumBtn(6),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildNumBtn(7),
                                const SizedBox(width: 8),
                                buildNumBtn(8),
                                const SizedBox(width: 8),
                                buildNumBtn(9),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      setDialogState(() => currentValue = 0);
                                    },
                                    child: const Icon(Icons.delete_outline),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                buildNumBtn(0),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: backspace,
                                    child: const Icon(Icons.backspace_outlined),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onConfirm(currentValue);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGridTable(AkropolisTrackerState state) {
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
                onTap: () => _showEntityEditor(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: state.entities[i].color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      state.entities[i].name.toUpperCase(),
                      style: TextStyle(
                        color: state.entities[i].color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  color: _getHexColor(hex),
                  size: 36,
                ),
              ),
              for (final entity in state.entities)
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    entity.scores[hex]?.total == 0
                        ? ''
                        : entity.scores[hex]!.total.toString(),
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

  Widget _buildInputPanel(
    BuildContext context,
    AkropolisTrackerState state,
    AkropolisTrackerNotifier notifier,
  ) {
    final activeEntity = state.entities[state.activeEntityIndex];
    final buffer = state.buffer;
    final isStones = buffer.selectedHexagon == AkropolisHexagon.stones;
    final hexColor = _getHexColor(buffer.selectedHexagon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Row 1: Player Select, Hex Select, Preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Player Select
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activeEntity.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.activeEntityIndex,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: activeEntity.color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: List.generate(state.entities.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: state.entities[index].color,
                          child: Text(
                            state.entities[index].name.toUpperCase(),
                            style: TextStyle(
                              color:
                                  state.entities[index].color
                                          .computeLuminance() >
                                      0.5
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) notifier.setActiveEntity(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Hex Select
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AkropolisHexagon>(
                    value: buffer.selectedHexagon,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: AkropolisHexagon.values.map((hex) {
                      return DropdownMenuItem(
                        value: hex,
                        child: Icon(
                          hex == AkropolisHexagon.stones
                              ? Icons.square
                              : Icons.hexagon,
                          color: _getHexColor(hex),
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return AkropolisHexagon.values.map((hex) {
                        return Container(
                          alignment: Alignment.center,
                          child: Icon(
                            hex == AkropolisHexagon.stones
                                ? Icons.square
                                : Icons.hexagon,
                            color: _getHexColor(hex),
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (val) {
                      if (val != null) notifier.setBufferHexagon(val);
                    },
                  ),
                ),
              ),
              const Spacer(),
              // Preview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activeEntity.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sumando a ${activeEntity.name}',
                      style: TextStyle(
                        color: activeEntity.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${buffer.totalPoints} pts',
                      style: TextStyle(
                        color: activeEntity.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isStones) ...[
                // Star
                GestureDetector(
                  onTap: () {
                    _showNumberPad(
                      'Cantidad de Estrellas',
                      buffer.starsValue,
                      'Suma la cantidad de estrellas del color del hexagono seleccionado.',
                      (val) {
                        notifier.updateBuffer(starsValue: val);
                      },
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.star_border, size: 84, color: hexColor),
                      Text(
                        buffer.starsValue.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
              ],
              // Hexagon
              GestureDetector(
                onTap: () {
                  _showNumberPad(
                    isStones ? 'Cantidad de Piedras' : 'Valor de Distritos',
                    buffer.districtValue,
                    isStones
                        ? 'Valen 1 punto cada una. (No llevan estrellas)'
                        : '1 punto por distrito en planta baja, 2 en primer piso, 3 en segundo piso...',
                    (val) {
                      notifier.updateBuffer(districtValue: val);
                    },
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isStones ? Icons.square_outlined : Icons.hexagon_outlined,
                      size: 84,
                      color: hexColor,
                    ),
                    Text(
                      buffer.districtValue.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Explanation
              Expanded(
                child: Text(
                  _getExplanation(buffer.selectedHexagon),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 3: Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                notifier.commitBuffer();
              },
              child: const Text(
                'SUMAR AL TOTAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(akropolisTrackerProvider);
    final notifier = ref.read(akropolisTrackerProvider.notifier);

    if (state.entities.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: TrackerAppBar(
        rightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AKROPOLIS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/burako_icon.svg',
              height: 24,
              width: 24,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: _buildGridTable(state),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildInputPanel(context, state, notifier),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p24,
                vertical: AppSizes.p16,
              ),
              child: TrackerBottomBar(
                onBack: () => context.pop(),
                onSave: () {
                  List<DialogPlayerInfo> flattenedPlayers = [];
                  for (var e in state.entities) {
                    flattenedPlayers.add(
                      DialogPlayerInfo(e.name, e.totalScore),
                    );
                  }

                  int maxScore = state.entities.isNotEmpty
                      ? state.entities
                            .map((e) => e.totalScore)
                            .reduce((a, b) => a > b ? a : b)
                      : 0;
                  String winners = state.entities
                      .where((e) => e.totalScore == maxScore)
                      .map((e) => e.name)
                      .join(' y ');

                  TrackerDialogs.showFinishMatchDialog(
                    context: context,
                    gameId: state.selectedGame?.id,
                    gameName: state.selectedGame?.name,
                    players: flattenedPlayers,
                    customWinnerName: winners,
                    customMaxScore: maxScore,
                    onSaveMatch: (finalScores) async {
                      if (state.selectedGame != null) {
                        await ref
                            .read(matchServiceProvider)
                            .saveMatch(
                              gameId: state.selectedGame!.id,
                              gameName: state.selectedGame!.name,
                              playerScores: finalScores,
                            );
                      }
                    },
                    onClearState: () {
                      notifier.resetAllScores();
                    },
                    onNavigateHome: () {
                      if (mounted) context.go('/home');
                    },
                  );
                },
                centerWidget: IconButton.filledTonal(
                  iconSize: 28,
                  padding: const EdgeInsets.all(12),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
                  ),
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    TrackerDialogs.showResetDialog(
                      context: context,
                      onConfirm: () {
                        notifier.resetAllScores();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
