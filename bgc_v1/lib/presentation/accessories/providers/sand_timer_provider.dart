import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/repositories/i_local_storage_repository.dart';
import '../../../domain/models/user_model.dart';

class SandTimerState {
  final int initialSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool hasStarted;

  SandTimerState({
    required this.initialSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.hasStarted,
  });

  double get progress =>
      initialSeconds == 0 ? 0 : remainingSeconds / initialSeconds;

  bool get isFinished => hasStarted && remainingSeconds == 0;

  SandTimerState copyWith({
    int? initialSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? hasStarted,
  }) {
    return SandTimerState(
      initialSeconds: initialSeconds ?? this.initialSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      hasStarted: hasStarted ?? this.hasStarted,
    );
  }
}

class SandTimerNotifier extends Notifier<SandTimerState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentKey = '';
  Timer? _timer;

  static const int _defaultSeconds = 60;

  @override
  SandTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return SandTimerState(
      initialSeconds: _defaultSeconds,
      remainingSeconds: _defaultSeconds,
      isRunning: false,
      hasStarted: false,
    );
  }

  /// Restaura el estado guardado (siempre pausado) o crea uno nuevo.
  /// Devuelve `true` si es un temporizador nuevo (no había estado guardado).
  Future<bool> initialize(User user) async {
    _currentKey = 'sand_timer_state_${user.id}';
    _timer?.cancel();

    final localDataStr = await _localStorage.getData(_currentKey);
    if (localDataStr != null) {
      try {
        final decoded = jsonDecode(localDataStr);
        final initial = decoded['initialSeconds'] ?? _defaultSeconds;
        state = SandTimerState(
          initialSeconds: initial,
          remainingSeconds: decoded['remainingSeconds'] ?? initial,
          isRunning: false, // Siempre se reanuda pausado
          hasStarted: decoded['hasStarted'] ?? false,
        );
        return false; // No es nuevo
      } catch (_) {
        // Si falla el parseo, cae al estado por defecto.
      }
    }

    state = SandTimerState(
      initialSeconds: _defaultSeconds,
      remainingSeconds: _defaultSeconds,
      isRunning: false,
      hasStarted: false,
    );
    await _saveState();
    return true; // Es nuevo
  }

  Future<void> setInitialSeconds(int seconds) async {
    _timer?.cancel();
    state = SandTimerState(
      initialSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
      hasStarted: false,
    );
    await _saveState();
  }

  void start() {
    if (state.isRunning || state.remainingSeconds <= 0) return;

    state = state.copyWith(isRunning: true, hasStarted: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      state = state.copyWith(remainingSeconds: next);
      if (next <= 0) {
        pause();
      } else {
        _saveState();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveState();
  }

  /// Detiene y vuelve al tiempo inicial.
  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.initialSeconds,
      isRunning: false,
      hasStarted: false,
    );
    _saveState();
  }

  Future<void> _saveState() async {
    if (_currentKey.isEmpty) return;
    final data = {
      'initialSeconds': state.initialSeconds,
      'remainingSeconds': state.remainingSeconds,
      'hasStarted': state.hasStarted,
      'lastModified': DateTime.now().toIso8601String(),
    };
    await _localStorage.saveData(_currentKey, jsonEncode(data));
  }
}

final sandTimerProvider =
    NotifierProvider<SandTimerNotifier, SandTimerState>(() {
      return SandTimerNotifier();
    });
