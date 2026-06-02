import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/local_catalog/local_games_catalog.dart';
import '../../../../data/repositories/local_storage_repository.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../domain/repositories/i_local_storage_repository.dart';

/// Un jugador del anotador estándar de puntos (VP).
/// index 0 es siempre el usuario logueado.
class ScorePlayer {
  final int index;
  final String? name;
  final Color color;
  final int score;

  ScorePlayer({
    required this.index,
    this.name,
    required this.color,
    required this.score,
  });

  ScorePlayer copyWith({String? name, Color? color, int? score}) {
    return ScorePlayer(
      index: index,
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
    );
  }
}

class StandardScoreboardState {
  final List<ScorePlayer> players;
  final Game? selectedGame;
  final int initialScore;

  StandardScoreboardState({
    required this.players,
    this.selectedGame,
    this.initialScore = 0,
  });

  StandardScoreboardState copyWith({
    List<ScorePlayer>? players,
    Game? selectedGame,
    int? initialScore,
  }) {
    return StandardScoreboardState(
      players: players ?? this.players,
      selectedGame: selectedGame ?? this.selectedGame,
      initialScore: initialScore ?? this.initialScore,
    );
  }
}

class StandardScoreboardNotifier extends Notifier<StandardScoreboardState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentUserId = '';
  String _currentKey = '';

  @override
  StandardScoreboardState build() {
    return StandardScoreboardState(players: []);
  }

  Future<void> initialize(int playerCount, User user, {String? fullKey}) async {
    _currentUserId = user.id;
    state = StandardScoreboardState(players: []);

    String? localDataStr;
    if (fullKey != null) {
      _currentKey = fullKey;
      localDataStr = await _localStorage.getData(fullKey);
    } else {
      _currentKey =
          'scoreboard_state_${user.id}_${playerCount}_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (localDataStr != null) {
      try {
        final decoded = jsonDecode(localDataStr);
        final playersJson = decoded['players'] as List;
        final restoredPlayers = playersJson
            .map(
              (p) => ScorePlayer(
                index: p['index'],
                name: p['name'],
                color: Color(p['color']),
                score: p['score'] ?? 0,
              ),
            )
            .toList();

        final gameId = decoded['selectedGameId'] as String?;
        state = StandardScoreboardState(
          players: restoredPlayers,
          selectedGame: _resolveGame(gameId),
          initialScore: decoded['initialScore'] ?? 0,
        );
        return;
      } catch (_) {
        // Si falla el parseo, se cae al estado inicial de abajo.
      }
    }

    state = StandardScoreboardState(
      players: _buildInitialPlayers(playerCount, user),
    );
  }

  List<ScorePlayer> _buildInitialPlayers(int playerCount, User user) {
    final userColor = user.favoriteColor ?? AppColors.availableColors[0];

    final players = <ScorePlayer>[
      ScorePlayer(index: 0, name: user.username, color: userColor, score: 0),
    ];

    final remainingColors = List<Color>.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    for (int i = 1; i < playerCount; i++) {
      final color = remainingColors.isNotEmpty
          ? remainingColors.removeAt(0)
          : Colors.grey;
      players.add(ScorePlayer(index: i, name: null, color: color, score: 0));
    }

    return players;
  }

  Game? _resolveGame(String? gameId) {
    if (gameId == null) return null;
    try {
      return LocalGamesCatalog.trackerGames.firstWhere((g) => g.id == gameId);
    } catch (_) {
      return null;
    }
  }

  void _updateState(StandardScoreboardState newState) {
    state = newState;
    saveLocalState();
  }

  void addScore(int index, int delta) {
    final updated = List<ScorePlayer>.from(state.players);
    updated[index] = updated[index].copyWith(
      score: updated[index].score + delta,
    );
    _updateState(state.copyWith(players: updated));
  }

  void resetScores() {
    final updated = state.players
        .map((p) => p.copyWith(score: state.initialScore))
        .toList();
    _updateState(state.copyWith(players: updated));
  }

  void setInitialScore(int value) {
    _updateState(state.copyWith(initialScore: value));
  }

  void updatePlayerName(int index, String name) {
    final updated = List<ScorePlayer>.from(state.players);
    updated[index] = updated[index].copyWith(name: name);
    _updateState(state.copyWith(players: updated));
  }

  void updatePlayerColor(int index, Color color) {
    final updated = List<ScorePlayer>.from(state.players);
    updated[index] = updated[index].copyWith(color: color);
    _updateState(state.copyWith(players: updated));
  }

  void selectGame(Game? game) {
    // Se reconstruye el estado completo para permitir volver a "Sin Asignar" (null).
    _updateState(
      StandardScoreboardState(
        players: state.players,
        selectedGame: game,
        initialScore: state.initialScore,
      ),
    );
  }

  Future<void> saveLocalState() async {
    if (state.players.isEmpty ||
        _currentUserId.isEmpty ||
        _currentKey.isEmpty) {
      return;
    }

    final data = {
      'players': state.players
          .map(
            (p) => {
              'index': p.index,
              'name': p.name,
              'color': p.color.toARGB32(),
              'score': p.score,
            },
          )
          .toList(),
      'selectedGameId': state.selectedGame?.id,
      'initialScore': state.initialScore,
      'lastModified': DateTime.now().toIso8601String(),
    };

    await _localStorage.saveData(_currentKey, jsonEncode(data));
  }

  Future<void> clearLocalState() async {
    if (_currentUserId.isEmpty || _currentKey.isEmpty) return;
    await _localStorage.removeData(_currentKey);
  }
}

final standardScoreboardProvider =
    NotifierProvider<StandardScoreboardNotifier, StandardScoreboardState>(
      () => StandardScoreboardNotifier(),
    );
