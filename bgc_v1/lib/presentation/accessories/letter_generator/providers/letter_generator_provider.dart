import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/local_storage_repository.dart';
import '../../../../domain/repositories/i_local_storage_repository.dart';
import '../../../../domain/models/user_model.dart';

class LetterGeneratorState {
  final List<String> history;
  final String? currentLetter;
  final bool allowRepeat;

  LetterGeneratorState({
    required this.history,
    required this.currentLetter,
    required this.allowRepeat,
  });

  bool get noLettersLeft =>
      !allowRepeat &&
      history.toSet().length >= LetterGeneratorNotifier.alphabet.length;

  List<String> get availableLetters {
    if (allowRepeat) return LetterGeneratorNotifier.alphabet;
    final used = history.toSet();
    return LetterGeneratorNotifier.alphabet
        .where((l) => !used.contains(l))
        .toList();
  }

  LetterGeneratorState copyWith({
    List<String>? history,
    String? currentLetter,
    bool clearCurrent = false,
    bool? allowRepeat,
  }) {
    return LetterGeneratorState(
      history: history ?? this.history,
      currentLetter: clearCurrent
          ? null
          : (currentLetter ?? this.currentLetter),
      allowRepeat: allowRepeat ?? this.allowRepeat,
    );
  }
}

class LetterGeneratorNotifier extends Notifier<LetterGeneratorState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  final Random _random = Random();
  String _currentKey = '';

  static const List<String> alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'Ñ',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  LetterGeneratorState build() {
    return LetterGeneratorState(
      history: [],
      currentLetter: null,
      allowRepeat: false,
    );
  }

  /// Restaura el estado guardado o crea uno vacío. Devuelve `true` si no hay
  /// nada para retomar (historial vacío); `false` si había una partida en curso.
  Future<bool> initialize(User user) async {
    _currentKey = 'letter_generator_state_${user.id}';

    final dataStr = await _localStorage.getData(_currentKey);
    if (dataStr != null) {
      try {
        final decoded = jsonDecode(dataStr);
        state = LetterGeneratorState(
          history: List<String>.from(decoded['history'] ?? []),
          currentLetter: decoded['currentLetter'],
          allowRepeat: decoded['allowRepeat'] ?? false,
        );
        return state.history.isEmpty;
      } catch (_) {
        // ignorado: cae al estado vacío de abajo
      }
    }

    state = LetterGeneratorState(
      history: [],
      currentLetter: null,
      allowRepeat: false,
    );
    await _save();
    return true;
  }

  void generateLetter() {
    final available = state.availableLetters;
    if (available.isEmpty) return;

    final letter = available[_random.nextInt(available.length)];
    state = state.copyWith(
      currentLetter: letter,
      history: [...state.history, letter],
    );
    _save();
  }

  void clearHistory() {
    state = state.copyWith(history: [], clearCurrent: true);
    _save();
  }

  void setAllowRepeat(bool value) {
    state = state.copyWith(allowRepeat: value);
    _save();
  }

  Future<void> _save() async {
    if (_currentKey.isEmpty) return;
    final data = {
      'history': state.history,
      'currentLetter': state.currentLetter,
      'allowRepeat': state.allowRepeat,
      'lastModified': DateTime.now().toIso8601String(),
    };
    await _localStorage.saveData(_currentKey, jsonEncode(data));
  }
}

final letterGeneratorProvider =
    NotifierProvider<LetterGeneratorNotifier, LetterGeneratorState>(() {
      return LetterGeneratorNotifier();
    });
