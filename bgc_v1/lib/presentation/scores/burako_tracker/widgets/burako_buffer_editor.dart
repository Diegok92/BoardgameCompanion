import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/burako_tracker_provider.dart';
import 'burako_reference_card.dart';
import '../../widgets/calculator_dialog.dart';
import '../../../widgets/custom_alert.dart';

class BurakoBufferEditor extends ConsumerWidget {
  const BurakoBufferEditor({super.key});

  void _showCalculator(BuildContext context, WidgetRef ref) async {
    final state = ref.read(burakoTrackerProvider);
    final initialVal = state.buffer.fichasScore;

    final result = await CalculatorDialog.show(
      context,
      initialValue: initialVal,
    );

    if (result != null) {
      ref.read(burakoTrackerProvider.notifier).setFichasScore(result);
    }
  }

  void _checkWinCondition(BuildContext context, WidgetRef ref) {
    final state = ref.read(burakoTrackerProvider);
    for (var e in state.entities) {
      if (e.totalScore >= 3000) {
        CustomAlert.show(
          context,
          'Termina de sumar a los demás y guarda la partida.',
          title: '¡${e.name} ha superado los 3000 puntos!',
        );
        break;
      }
    }
  }

  void _commitBuffer(BuildContext context, WidgetRef ref) {
    ref.read(burakoTrackerProvider.notifier).commitBuffer();
    _checkWinCondition(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(burakoTrackerProvider);
    final activeEntity = state.entities[state.activeEntityIndex];
    final buffer = state.buffer;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: state.activeEntityIndex,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: activeEntity.color,
                ),
                style: TextStyle(
                  color: activeEntity.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                items: List.generate(state.entities.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(
                      'SUMANDO PARA ${state.entities[index].name.toUpperCase()}',
                      style: TextStyle(color: state.entities[index].color),
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(burakoTrackerProvider.notifier)
                        .setActiveEntity(val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'A sumar: ${buffer.totalPoints > 0 ? '+' : ''}${buffer.totalPoints}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: buffer.totalPoints < 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          const Spacer(flex: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Canastas Puras',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '(+200)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref
                        .read(burakoTrackerProvider.notifier)
                        .updatePureCanastas(-1),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${buffer.pureCanastas}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref
                        .read(burakoTrackerProvider.notifier)
                        .updatePureCanastas(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Canastas Impuras',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '(+100)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.remove, size: 28),
                    onPressed: () => ref
                        .read(burakoTrackerProvider.notifier)
                        .updateImpureCanastas(-1),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${buffer.impureCanastas}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () => ref
                        .read(burakoTrackerProvider.notifier)
                        .updateImpureCanastas(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: buffer.hasMuerto,
                      activeThumbColor: Colors.red,
                      onChanged: (val) => ref
                          .read(burakoTrackerProvider.notifier)
                          .toggleMuerto(val),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MUERTO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '(-100)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                          Text(
                            'CIERRE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '(+100)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: buffer.hasCierre,
                      activeThumbColor: Colors.green,
                      onChanged: (val) => ref
                          .read(burakoTrackerProvider.notifier)
                          .toggleCierre(val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Puntaje por Fichas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        const Dialog(child: BurakoReferenceCard()),
                  );
                },
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showCalculator(context, ref),
                child: Container(
                  width: 100,
                  height: 50,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${buffer.fichasScore}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _commitBuffer(context, ref),
              child: const Text(
                'SUMAR AL TOTAL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
