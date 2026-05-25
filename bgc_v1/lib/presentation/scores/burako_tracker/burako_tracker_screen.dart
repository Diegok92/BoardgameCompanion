import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../widgets/tracker_app_bar.dart';
import '../widgets/tracker_bottom_bar.dart';
import 'widgets/fichas_calculator_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_service.dart';
import '../widgets/tracker_dialogs.dart';
import '../../widgets/custom_alert.dart';
import 'providers/burako_tracker_provider.dart';
import 'widgets/burako_reference_card.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BurakoTrackerScreen extends ConsumerStatefulWidget {
  final int playerCount;

  const BurakoTrackerScreen({super.key, required this.playerCount});

  @override
  ConsumerState<BurakoTrackerScreen> createState() => _BurakoTrackerScreenState();
}

class _BurakoTrackerScreenState extends ConsumerState<BurakoTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        ref.read(burakoTrackerProvider.notifier).initialize(widget.playerCount, user);
      }
    });
  }

  void _showCalculator() async {
    final state = ref.read(burakoTrackerProvider);
    final initialVal = state.buffer.fichasScore;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => FichasCalculatorDialog(initialValue: initialVal),
    );

    if (result != null) {
      ref.read(burakoTrackerProvider.notifier).setFichasScore(result);
    }
  }



  void _checkWinCondition() {
    final state = ref.read(burakoTrackerProvider);
    for (var e in state.entities) {
      if (e.totalScore >= 3000) {
        CustomAlert.show(
          context, 
          'Termina de sumar a los demás y guarda la partida.', 
          title: '¡${e.name} ha superado los 3000 puntos!'
        );
        break; // Only show once per check
      }
    }
  }

  void _commitBuffer() {
    ref.read(burakoTrackerProvider.notifier).commitBuffer();
    _checkWinCondition();
  }

  void _showEntityEditor(int entityIndex) {
    final user = ref.read(authProvider);
    final invitados = user?.invitados ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentState = ref.read(burakoTrackerProvider);
            final currentEntity = currentState.entities[entityIndex];

            return AlertDialog(
              title: Text('Editar ${currentEntity.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(currentEntity.playerNames.length, (pIndex) {
                      final currName = currentEntity.playerNames[pIndex];
                      int globalIndex = 1;
                      for (int i = 0; i < entityIndex; i++) {
                        globalIndex += currentState.entities[i].playerNames.length;
                      }
                      globalIndex += pIndex;

                      if (entityIndex == 0 && pIndex == 0 && user != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Jugador 1: ${user.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: 'Jugador $globalIndex',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          initialValue: currName != user?.username && currName != 'NUEVO_INVITADO' && !invitados.contains(currName) ? null : currName,
                          items: [
                            ...invitados.where((inv) {
                              for (int i = 0; i < currentState.entities.length; i++) {
                                for (int j = 0; j < currentState.entities[i].playerNames.length; j++) {
                                  if (i == entityIndex && j == pIndex) continue;
                                  if (currentState.entities[i].playerNames[j] == inv) return false;
                                }
                              }
                              return true;
                            }).map((inv) => DropdownMenuItem(value: inv, child: Text(inv))),
                            const DropdownMenuItem(value: 'NUEVO_INVITADO', child: Text('+ Agregar Invitado', style: TextStyle(color: Colors.blue))),
                            if (currName == null) const DropdownMenuItem(value: null, child: Text('Sin Asignar', style: TextStyle(color: Colors.grey))),
                          ],
                          onChanged: (val) {
                            if (val == 'NUEVO_INVITADO') {
                              Navigator.pop(context);
                              context.push('/register-invitado');
                            } else {
                              ref.read(burakoTrackerProvider.notifier).updatePlayerNameInEntity(entityIndex, pIndex, val);
                              setDialogState(() {});
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text('Elige color:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: AppColors.availableColors.where((color) {
                        return !currentState.entities.any((e) => e.id != currentEntity.id && e.color.toARGB32() == color.toARGB32());
                      }).map((color) {
                        return InkWell(
                          onTap: () {
                            ref.read(burakoTrackerProvider.notifier).updateEntityColor(entityIndex, color);
                            Navigator.pop(context);
                          },
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: currentEntity.color.toARGB32() == color.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      }).toList(),
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
          }
        );
      }
    );
  }

  Widget _buildEntityHeader(BurakoEntity entity, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => _showEntityEditor(index),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: entity.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      entity.name,
                      style: TextStyle(color: entity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: entity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${entity.totalScore}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferEditor(BurakoTrackerState state) {
    final activeEntity = state.entities[state.activeEntityIndex];
    final buffer = state.buffer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Selector de Jugador Activo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: state.activeEntityIndex,
                underline: const SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: activeEntity.color),
                style: TextStyle(color: activeEntity.color, fontWeight: FontWeight.bold, fontSize: 18),
                items: List.generate(state.entities.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('SUMANDO PARA ${state.entities[index].name.toUpperCase()}', style: TextStyle(color: state.entities[index].color)),
                  );
                }),
                onChanged: (val) {
                  if (val != null) ref.read(burakoTrackerProvider.notifier).setActiveEntity(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Subtotal Actual a sumar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
            ),
            child: Text(
              'A sumar: ${buffer.totalPoints > 0 ? '+' : ''}${buffer.totalPoints}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: buffer.totalPoints < 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          const Spacer(flex: 1),

          // Puras (+200)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Canastas Puras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                    Text('(+200)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updatePureCanastas(-1),
                  ),
                  SizedBox(width: 48, child: Text('${buffer.pureCanastas}', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updatePureCanastas(1),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Impuras (+100)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Canastas Impuras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                    Text('(+100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updateImpureCanastas(-1),
                  ),
                  SizedBox(width: 48, child: Text('${buffer.impureCanastas}', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updateImpureCanastas(1),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Muerto y Cierre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: buffer.hasMuerto,
                      activeThumbColor: Colors.red,
                      onChanged: (val) => ref.read(burakoTrackerProvider.notifier).toggleMuerto(val),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('MUERTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14), overflow: TextOverflow.ellipsis),
                          Text('(-100)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('CIERRE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14), overflow: TextOverflow.ellipsis),
                          Text('(+100)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: buffer.hasCierre,
                      activeThumbColor: Colors.green,
                      onChanged: (val) => ref.read(burakoTrackerProvider.notifier).toggleCierre(val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Puntaje Fichas
          Row(
            children: [
              Text('Puntaje por Fichas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const Dialog(child: BurakoReferenceCard()),
                  );
                },
              ),
              const Spacer(),
              InkWell(
                onTap: _showCalculator,
                child: Container(
                  width: 100,
                  height: 50,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${buffer.fichasScore}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(flex: 2),
          
          const Spacer(flex: 2),

          // Sumar al total
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _commitBuffer,
              child: const Text('SUMAR AL TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(burakoTrackerProvider);

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
              'BURAKO',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/burako_icon.svg', height: 24, width: 24),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header de totales
              Row(
                children: List.generate(state.entities.length, (index) {
                  final e = state.entities[index];
                  return _buildEntityHeader(e, index);
                }),
              ),
              const Divider(height: 32),
              
              // Buffer Editor (sin scroll)
              Expanded(
                child: _buildBufferEditor(state),
              ),

              // Bottom Bar
              TrackerBottomBar(
                onBack: () async {
                  await ref.read(burakoTrackerProvider.notifier).saveLocalState();
                  if (context.mounted) Navigator.pop(context);
                },
                onSave: () {
                  final state = ref.read(burakoTrackerProvider);
                  
                  List<DialogPlayerInfo> flattenedPlayers = [];
                  for (var e in state.entities) {
                    for (var p in e.playerNames) {
                      flattenedPlayers.add(DialogPlayerInfo(p, e.totalScore));
                    }
                  }

                  int maxScore = state.entities.isNotEmpty ? state.entities.map((e) => e.totalScore).reduce((a, b) => a > b ? a : b) : 0;
                  String winners = state.entities.where((e) => e.totalScore == maxScore).map((e) => e.name).join(' y ');

                  TrackerDialogs.showFinishMatchDialog(
                    context: context,
                    gameId: state.selectedGame?.id,
                    gameName: state.selectedGame?.name,
                    players: flattenedPlayers,
                    customWinnerName: winners,
                    customMaxScore: maxScore,
                    onSaveMatch: (finalScores) async {
                      await ref.read(matchServiceProvider).saveMatch(
                        gameId: state.selectedGame!.id,
                        gameName: state.selectedGame!.name,
                        playerScores: finalScores,
                      );
                    },
                    onClearState: () => ref.read(burakoTrackerProvider.notifier).clearLocalState(),
                    onNavigateHome: () {
                      if (mounted) context.go('/home');
                    },
                  );
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
                      onConfirm: () => ref.read(burakoTrackerProvider.notifier).resetGame(),
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
