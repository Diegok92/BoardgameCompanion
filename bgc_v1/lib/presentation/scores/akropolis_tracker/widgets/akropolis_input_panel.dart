import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/akropolis_tracker_provider.dart';
import '../../widgets/tracker_dialogs.dart';

class AkropolisInputPanel extends ConsumerWidget {
  const AkropolisInputPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(akropolisTrackerProvider);
    final notifier = ref.read(akropolisTrackerProvider.notifier);

    final activeEntity = state.entities[state.activeEntityIndex];
    final buffer = state.buffer;
    final isStones = buffer.selectedHexagon == AkropolisHexagon.stones;
    final hexColor = buffer.selectedHexagon.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      color: activeEntity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: List.generate(state.entities.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: state.entities[index].color,
                          child: Text(
                            state.entities[index].name.toUpperCase(),
                            style: TextStyle(
                              color: state.entities[index].color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                          hex == AkropolisHexagon.stones ? Icons.square : Icons.hexagon,
                          color: hex.color,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return AkropolisHexagon.values.map((hex) {
                        return Container(
                          alignment: Alignment.center,
                          child: Icon(
                            hex == AkropolisHexagon.stones ? Icons.square : Icons.hexagon,
                            color: hex.color,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: activeEntity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${buffer.totalPoints} pts',
                      style: TextStyle(
                        color: activeEntity.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
                    TrackerDialogs.showNumberPadDialog(
                      context: context,
                      title: 'Cantidad de Estrellas',
                      initialValue: buffer.starsValue,
                      explanation: 'Suma la cantidad de estrellas del color del hexagono seleccionado.',
                      onConfirm: (val) {
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
                  TrackerDialogs.showNumberPadDialog(
                    context: context,
                    title: isStones ? 'Cantidad de Piedras' : 'Tamaño del Distrito',
                    initialValue: buffer.districtValue,
                    explanation: isStones
                        ? 'Suma la cantidad de piedras sobrantes.'
                        : buffer.selectedHexagon.explanation,
                    onConfirm: (val) {
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
                  buffer.selectedHexagon.explanation,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                notifier.commitBuffer();
              },
              child: const Text('SUMAR AL TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
