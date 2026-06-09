import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiceRollState {
  final List<int> diceTypes;
  final List<int> diceAmounts;
  final int selectedDice;
  final int diceAmount;
  final List<int> diceResults;
  final List<bool> lockedDice;
  final bool isRolling;

  DiceRollState({
    required this.diceTypes,
    required this.diceAmounts,
    required this.selectedDice,
    required this.diceAmount,
    required this.diceResults,
    required this.lockedDice,
    required this.isRolling,
  });

  int get total => diceResults.fold(0, (sum, value) => sum + value);

  bool get allDiceLocked => lockedDice.every((isLocked) => isLocked);

  DiceRollState copyWith({
    int? selectedDice,
    int? diceAmount,
    List<int>? diceResults,
    List<bool>? lockedDice,
    bool? isRolling,
  }) {
    return DiceRollState(
      diceTypes: diceTypes,
      diceAmounts: diceAmounts,
      selectedDice: selectedDice ?? this.selectedDice,
      diceAmount: diceAmount ?? this.diceAmount,
      diceResults: diceResults ?? this.diceResults,
      lockedDice: lockedDice ?? this.lockedDice,
      isRolling: isRolling ?? this.isRolling,
    );
  }
}

class DiceRollNotifier extends Notifier<DiceRollState> {
  final Random _random = Random();

  static const List<int> defaultDiceTypes = [4, 6, 10, 12, 20, 100];
  static const List<int> defaultDiceAmounts = [1, 2, 3, 4, 5];

  @override
  DiceRollState build() {
    const initialDice = 4;
    const initialAmount = 1;

    final initialResults = _generateResults(
      amount: initialAmount,
      selectedDice: initialDice,
    );

    return DiceRollState(
      diceTypes: defaultDiceTypes,
      diceAmounts: defaultDiceAmounts,
      selectedDice: initialDice,
      diceAmount: initialAmount,
      diceResults: initialResults,
      lockedDice: List.generate(initialAmount, (_) => false),
      isRolling: false,
    );
  }

  int _generateSingleResult({required int selectedDice}) {
    if (selectedDice == 100) {
      return (_random.nextInt(10) + 1) * 10;
    }
    return _random.nextInt(selectedDice) + 1;
  }

  List<int> _generateResults({required int amount, required int selectedDice}) {
    return List.generate(
      amount,
      (_) => _generateSingleResult(selectedDice: selectedDice),
    );
  }

  List<int> _generateResultsKeepingLocked() {
    return List.generate(state.diceAmount, (index) {
      if (state.lockedDice[index]) return state.diceResults[index];
      return _generateSingleResult(selectedDice: state.selectedDice);
    });
  }

  /// Devuelve `true` si el roll arrancó, `false` si todos los dados están bloqueados.
  bool rollDice() {
    if (state.isRolling) return false;
    if (state.allDiceLocked) return false;

    state = state.copyWith(isRolling: true);
    return true;
  }

  void onRollCompleted() {
    state = state.copyWith(
      diceResults: _generateResultsKeepingLocked(),
      isRolling: false,
    );
  }

  void selectDice(int dice) {
    if (state.isRolling) return;

    state = state.copyWith(
      selectedDice: dice,
      diceResults: _generateResults(
        amount: state.diceAmount,
        selectedDice: dice,
      ),
      lockedDice: List.generate(state.diceAmount, (_) => false),
    );
  }

  void changeDiceAmount(int amount) {
    if (state.isRolling) return;

    List<int> newResults;
    List<bool> newLocked;

    if (state.diceResults.length < amount) {
      final missing = amount - state.diceResults.length;
      newResults = [
        ...state.diceResults,
        ..._generateResults(amount: missing, selectedDice: state.selectedDice),
      ];
      newLocked = [
        ...state.lockedDice,
        ...List.generate(missing, (_) => false),
      ];
    } else {
      newResults = state.diceResults.take(amount).toList();
      newLocked = state.lockedDice.take(amount).toList();
    }

    state = state.copyWith(
      diceAmount: amount,
      diceResults: newResults,
      lockedDice: newLocked,
    );
  }

  void toggleDiceLock(int index) {
    if (state.isRolling) return;

    final updated = List<bool>.from(state.lockedDice);
    updated[index] = !updated[index];
    state = state.copyWith(lockedDice: updated);
  }
}

final diceRollProvider =
    NotifierProvider<DiceRollNotifier, DiceRollState>(() {
      return DiceRollNotifier();
    });