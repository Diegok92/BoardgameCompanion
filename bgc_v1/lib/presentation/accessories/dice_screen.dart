import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../accessories/providers/dice_provider.dart';
import '../accessories/widgets/dice_widgets.dart';

class DiceRollScreen extends ConsumerStatefulWidget {
  const DiceRollScreen({super.key});

  @override
  ConsumerState<DiceRollScreen> createState() => _DiceRollScreenState();
}

class _DiceRollScreenState extends ConsumerState<DiceRollScreen>
    with SingleTickerProviderStateMixin {
  static const Color redColor = AppColors.red;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: pi * 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(diceRollProvider.notifier).onRollCompleted();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDice() {
    final started = ref.read(diceRollProvider.notifier).rollDice();

    if (!started && ref.read(diceRollProvider).allDiceLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los dados están bloqueados. Desbloqueá uno para tirar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (started) _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(diceRollProvider);
    final notifier = ref.read(diceRollProvider.notifier);

    final diceSize = state.diceAmount == 1 ? 220.0 : state.diceAmount == 2 ? 145.0 : 115.0;
    final buttonText = state.isRolling ? 'TIRANDO...' : state.diceAmount == 1 ? 'TIRAR DADO' : 'TIRAR DADOS';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG Companion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/logo.svg', height: 24),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 145,
                height: 45,
                child: DropdownButtonFormField<int>(
                  initialValue: state.diceAmount,
                  dropdownColor: colorScheme.surface,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 22),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: redColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: redColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: redColor),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  selectedItemBuilder: (context) => state.diceAmounts.map((amount) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text('DADOS: $amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  )).toList(),
                  items: state.diceAmounts.map((amount) => DropdownMenuItem<int>(
                    value: amount,
                    child: Text(
                      amount == 1 ? '1 dado' : '$amount dados',
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  )).toList(),
                  onChanged: state.isRolling ? null : (value) { if (value != null) notifier.changeDiceAmount(value); },
                ),
              ),
              const SizedBox(height: 18),
              Text('TIPO DE DADO (CARAS)', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: state.diceTypes.map((dice) {
                    final isSelected = dice == state.selectedDice;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => notifier.selectDice(dice),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 50,
                          height: 35,
                          decoration: BoxDecoration(
                            color: isSelected ? redColor : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? redColor : colorScheme.outlineVariant),
                          ),
                          child: Center(
                            child: Text('D$dice', style: TextStyle(color: isSelected ? Colors.white : colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tocá el candado para bloquear un dado y seguir tirando solo los demás.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: List.generate(state.diceAmount, (index) {
                            final isLocked = state.lockedDice[index];
                            return DiceLockWrapper(
                              isLocked: isLocked,
                              onTapLock: () => notifier.toggleDiceLock(index),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateZ(isLocked ? 0 : _animation.value),
                                child: DiceWidget(
                                  result: state.isRolling && !isLocked ? '?' : state.diceResults[index].toString(),
                                  diceType: 'D${state.selectedDice}',
                                  size: diceSize,
                                  isLocked: isLocked,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      state.isRolling ? 'TOTAL: ...' : 'TOTAL: ${state.total}',
                      style: const TextStyle(color: redColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _rollDice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: redColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}