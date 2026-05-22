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
import 'providers/burako_tracker_provider.dart';
import 'widgets/burako_reference_card.dart';

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

  void _confirmFinishMatch() {
    final state = ref.read(burakoTrackerProvider);
    
    // Check if game selected
    if (state.selectedGame == null) return;

    bool hasUnassigned = false;
    for (var e in state.entities) {
      for (var p in e.playerNames) {
        if (p == null || p.isEmpty || p == 'Sin Asignar' || p == 'NUEVO_INVITADO') {
          hasUnassigned = true;
          break;
        }
      }
    }

    if (hasUnassigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, asigna todos los jugadores a un invitado antes de guardar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int maxScore = 0;
    if (state.entities.isNotEmpty) {
      maxScore = state.entities.map((e) => e.totalScore).reduce((a, b) => a > b ? a : b);
    }
    final winners = state.entities.where((e) => e.totalScore == maxScore).map((e) => e.name).join(' y ');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Terminar Partida?'),
        content: Text('Ganador actual: $winners con $maxScore puntos.\n\n¿Deseas registrar esta partida y sus puntajes finales en el historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              Map<String, int> finalScores = {};
              for (var e in state.entities) {
                for (var p in e.playerNames) {
                  if (p != null && p.isNotEmpty && p != 'Sin Asignar' && p != 'NUEVO_INVITADO') {
                    finalScores[p] = e.totalScore;
                  }
                }
              }

              try {
                await ref.read(matchServiceProvider).saveMatch(
                  gameId: state.selectedGame!.id,
                  gameName: state.selectedGame!.name,
                  playerScores: finalScores,
                );
                await ref.read(burakoTrackerProvider.notifier).clearLocalState();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partida registrada con éxito!'), backgroundColor: Colors.green),
                  );
                  context.go('/home');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _checkWinCondition() {
    final state = ref.read(burakoTrackerProvider);
    for (var e in state.entities) {
      if (e.totalScore >= 3000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡${e.name} ha superado los 3000 puntos! Termina de sumar a los demás y guarda la partida.'),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 4),
          ),
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
    final state = ref.read(burakoTrackerProvider);
    final entity = state.entities[entityIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Editar ${entity.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...List.generate(entity.playerNames.length, (pIndex) {
                    final currName = entity.playerNames[pIndex];
                    int globalIndex = 1;
                    for (int i = 0; i < entityIndex; i++) {
                      globalIndex += state.entities[i].playerNames.length;
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
                            for (int i = 0; i < state.entities.length; i++) {
                              for (int j = 0; j < state.entities[i].playerNames.length; j++) {
                                if (i == entityIndex && j == pIndex) continue;
                                if (state.entities[i].playerNames[j] == inv) return false;
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
                            setModalState(() {});
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
                      return !state.entities.any((e) => e.id != entity.id && e.color.toARGB32() == color.toARGB32());
                    }).map((color) {
                      return InkWell(
                        onTap: () {
                          ref.read(burakoTrackerProvider.notifier).updateEntityColor(entityIndex, color);
                          Navigator.pop(context);
                        },
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: entity.color.toARGB32() == color.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${entity.totalScore}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
          const Divider(),
          const Spacer(),

          // Puras (+200)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canastas Puras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900])),
                  const Text('(+200)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                ],
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updatePureCanastas(-1),
                  ),
                  SizedBox(width: 48, child: Text('${buffer.pureCanastas}', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updatePureCanastas(1),
                  ),
                ],
              )
            ],
          ),
          const Spacer(),

          // Impuras (+100)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canastas Impuras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900])),
                  const Text('(+100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                ],
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updateImpureCanastas(-1),
                  ),
                  SizedBox(width: 48, child: Text('${buffer.impureCanastas}', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]))),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref.read(burakoTrackerProvider.notifier).updateImpureCanastas(1),
                  ),
                ],
              )
            ],
          ),
          const Spacer(),

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
          const Spacer(),

          // Puntaje Fichas
          Row(
            children: [
              Text('Puntaje por Fichas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900])),
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
          
          // Subtotal Actual a sumar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!)
            ),
            child: Text(
              'A sumar: ${buffer.totalPoints > 0 ? '+' : ''}${buffer.totalPoints}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: buffer.totalPoints < 0 ? Colors.red : Colors.blue[800],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: const TrackerAppBar(
        rightWidget: Text(
          'BURAKO',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
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
                onSave: _confirmFinishMatch,
                centerWidget: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  iconSize: 20,
                  padding: const EdgeInsets.all(12),
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Resetear puntajes?'),
                        content: const Text('Todos volverán a 0.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              ref.read(burakoTrackerProvider.notifier).resetGame();
                              Navigator.pop(context);
                            },
                            child: const Text('Resetear'),
                          ),
                        ],
                      ),
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
