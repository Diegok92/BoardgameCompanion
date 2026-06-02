import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/local_storage_repository.dart';
import '../../../../domain/repositories/i_local_storage_repository.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';

class ChessClockState {
  final String playerOneName;
  final Color playerOneColor;
  final int playerOneSeconds;

  final String playerTwoName;
  final Color playerTwoColor;
  final int playerTwoSeconds;

  final int activePlayer; // 1 or 2
  final bool isRunning;
  final int initialSeconds;

  ChessClockState({
    required this.playerOneName,
    required this.playerOneColor,
    required this.playerOneSeconds,
    required this.playerTwoName,
    required this.playerTwoColor,
    required this.playerTwoSeconds,
    required this.activePlayer,
    required this.isRunning,
    required this.initialSeconds,
  });

  ChessClockState copyWith({
    String? playerOneName,
    Color? playerOneColor,
    int? playerOneSeconds,
    String? playerTwoName,
    Color? playerTwoColor,
    int? playerTwoSeconds,
    int? activePlayer,
    bool? isRunning,
    int? initialSeconds,
  }) {
    return ChessClockState(
      playerOneName: playerOneName ?? this.playerOneName,
      playerOneColor: playerOneColor ?? this.playerOneColor,
      playerOneSeconds: playerOneSeconds ?? this.playerOneSeconds,
      playerTwoName: playerTwoName ?? this.playerTwoName,
      playerTwoColor: playerTwoColor ?? this.playerTwoColor,
      playerTwoSeconds: playerTwoSeconds ?? this.playerTwoSeconds,
      activePlayer: activePlayer ?? this.activePlayer,
      isRunning: isRunning ?? this.isRunning,
      initialSeconds: initialSeconds ?? this.initialSeconds,
    );
  }
}

class ChessClockNotifier extends Notifier<ChessClockState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentKey = '';
  Timer? _timer;

  @override
  ChessClockState build() {
    return ChessClockState(
      playerOneName: '',
      playerOneColor: AppColors.blue,
      playerOneSeconds: 300,
      playerTwoName: 'Jugador 2',
      playerTwoColor: AppColors.red,
      playerTwoSeconds: 300,
      activePlayer: 1,
      isRunning: false,
      initialSeconds: 300,
    );
  }

  Future<bool> initialize(User user) async {
    _currentKey = 'chess_clock_state_${user.id}';

    String? localDataStr = await _localStorage.getData(_currentKey);
    
    if (localDataStr != null) {
      try {
        final decoded = jsonDecode(localDataStr);
        state = ChessClockState(
          playerOneName: decoded['playerOneName'] ?? user.username,
          playerOneColor: decoded['playerOneColor'] != null ? Color(decoded['playerOneColor']) : (user.favoriteColor ?? AppColors.blue),
          playerOneSeconds: decoded['playerOneSeconds'] ?? 300,
          playerTwoName: decoded['playerTwoName'] ?? 'Jugador 2',
          playerTwoColor: decoded['playerTwoColor'] != null ? Color(decoded['playerTwoColor']) : AppColors.red,
          playerTwoSeconds: decoded['playerTwoSeconds'] ?? 300,
          activePlayer: decoded['activePlayer'] ?? 1,
          isRunning: false, // Always initialize paused
          initialSeconds: decoded['initialSeconds'] ?? 300,
        );
        return false; // Not new
      } catch (e) {
        // Fallback to default
      }
    }

    // Default initialization
    final playerOneColor = user.favoriteColor ?? AppColors.blue;
    // El jugador 2 arranca con un color distinto al del usuario.
    final playerTwoColor = AppColors.availableColors.firstWhere(
      (c) => c.toARGB32() != playerOneColor.toARGB32(),
      orElse: () => AppColors.red,
    );
    state = ChessClockState(
      playerOneName: user.username,
      playerOneColor: playerOneColor,
      playerOneSeconds: 300,
      playerTwoName: 'Jugador 2',
      playerTwoColor: playerTwoColor,
      playerTwoSeconds: 300,
      activePlayer: 1,
      isRunning: false,
      initialSeconds: 300,
    );
    await _saveState();
    return true; // Is new
  }

  Future<void> setInitialSeconds(int seconds) async {
    state = state.copyWith(
      initialSeconds: seconds,
      playerOneSeconds: seconds,
      playerTwoSeconds: seconds,
      activePlayer: 1,
      isRunning: false,
    );
    _timer?.cancel();
    await _saveState();
  }

  Future<void> updatePlayer(int player, {String? name, Color? color}) async {
    if (player == 1) {
      state = state.copyWith(playerOneName: name, playerOneColor: color);
    } else {
      state = state.copyWith(playerTwoName: name, playerTwoColor: color);
    }
    await _saveState();
  }

  void start() {
    if (state.isRunning || state.playerOneSeconds <= 0 || state.playerTwoSeconds <= 0) return;
    
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.activePlayer == 1) {
        final newTime = state.playerOneSeconds - 1;
        state = state.copyWith(playerOneSeconds: newTime);
        if (newTime <= 0) {
          pause();
        }
      } else {
        final newTime = state.playerTwoSeconds - 1;
        state = state.copyWith(playerTwoSeconds: newTime);
        if (newTime <= 0) {
          pause();
        }
      }
      // Save state every second to prevent data loss if app is closed suddenly
      _saveState();
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveState();
  }

  void switchTurn() {
    if (!state.isRunning) return;
    state = state.copyWith(activePlayer: state.activePlayer == 1 ? 2 : 1);
    _saveState();
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      playerOneSeconds: state.initialSeconds,
      playerTwoSeconds: state.initialSeconds,
      activePlayer: 1,
    );
    _saveState();
  }

  Future<void> _saveState() async {
    if (_currentKey.isEmpty) return;

    final data = {
      'playerOneName': state.playerOneName,
      'playerOneColor': state.playerOneColor.toARGB32(),
      'playerOneSeconds': state.playerOneSeconds,
      'playerTwoName': state.playerTwoName,
      'playerTwoColor': state.playerTwoColor.toARGB32(),
      'playerTwoSeconds': state.playerTwoSeconds,
      'activePlayer': state.activePlayer,
      'initialSeconds': state.initialSeconds,
      'lastModified': DateTime.now().toIso8601String(),
    };
    
    await _localStorage.saveData(_currentKey, jsonEncode(data));
  }
}

final chessClockProvider = NotifierProvider<ChessClockNotifier, ChessClockState>(() {
  return ChessClockNotifier();
});
