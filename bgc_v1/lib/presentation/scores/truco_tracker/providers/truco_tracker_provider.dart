import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local_catalog/local_games_catalog.dart';
import '../../../../data/repositories/local_storage_repository.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../domain/repositories/i_local_storage_repository.dart';

class TrucoTeam {
  final String id;
  final String name;
  final List<String?> playerNames;
  final int malas;
  final int buenas;

  TrucoTeam({
    required this.id,
    required this.name,
    required this.playerNames,
    this.malas = 0,
    this.buenas = 0,
  });

  int get totalPoints => malas + buenas;

  TrucoTeam copyWith({
    String? name,
    List<String?>? playerNames,
    int? malas,
    int? buenas,
  }) {
    return TrucoTeam(
      id: id,
      name: name ?? this.name,
      playerNames: playerNames ?? this.playerNames,
      malas: malas ?? this.malas,
      buenas: buenas ?? this.buenas,
    );
  }
}

class TrucoTrackerState {
  final List<TrucoTeam> teams;
  final int targetScore;
  final Game? selectedGame;

  TrucoTrackerState({
    required this.teams,
    this.targetScore = 30,
    this.selectedGame,
  });

  TrucoTeam? get winner {
    for (final team in teams) {
      if (team.totalPoints >= targetScore) {
        return team;
      }
    }

    return null;
  }

  bool get isFinished => winner != null;

  TrucoTrackerState copyWith({
    List<TrucoTeam>? teams,
    int? targetScore,
    Game? selectedGame,
  }) {
    return TrucoTrackerState(
      teams: teams ?? this.teams,
      targetScore: targetScore ?? this.targetScore,
      selectedGame: selectedGame ?? this.selectedGame,
    );
  }
}

class TrucoTrackerNotifier extends Notifier<TrucoTrackerState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();

  String _currentUserId = '';
  String _currentKey = '';

  @override
  TrucoTrackerState build() {
    return TrucoTrackerState(
      teams: [],
      targetScore: 30,
    );
  }

  Future<void> initialize(
    int playerCount,
    User user, {
    String? fullKey,
  }) async {
    _currentUserId = user.id;

    state = TrucoTrackerState(
      teams: [],
      targetScore: 30,
    );

    String? localDataStr;

    if (fullKey != null) {
      _currentKey = fullKey;
      localDataStr = await _localStorage.getData(fullKey);
    } else {
      final normalizedPlayerCount = _normalizePlayerCount(playerCount);

      _currentKey =
          'truco_state_${user.id}_${normalizedPlayerCount}_${DateTime.now().millisecondsSinceEpoch}';
    }

    Game? trucoGame;

    try {
      trucoGame = LocalGamesCatalog.games.firstWhere(
        (game) => game.id == 'truco',
      );
    } catch (_) {}

    if (localDataStr != null) {
      try {
        final decoded = jsonDecode(localDataStr);
        final teamsJson = decoded['teams'] as List;

        final restoredTeams = teamsJson.map((teamJson) {
          final namesJson = teamJson['playerNames'] as List;

          return TrucoTeam(
            id: teamJson['id'],
            name: teamJson['name'],
            playerNames: namesJson.map((name) => name as String?).toList(),
            malas: teamJson['malas'] ?? 0,
            buenas: teamJson['buenas'] ?? 0,
          );
        }).toList();

        state = TrucoTrackerState(
          teams: restoredTeams,
          targetScore: decoded['targetScore'] ?? 30,
          selectedGame: trucoGame,
        );

        return;
      } catch (_) {
        // Si falla la carga local, se crea una partida nueva.
      }
    }

    final normalizedPlayerCount = _normalizePlayerCount(playerCount);
    final playersPerTeam = normalizedPlayerCount ~/ 2;

    final initialTeams = [
      TrucoTeam(
        id: 'team_1',
        name: 'Nosotros',
        playerNames: [
          user.username,
          ...List.generate(playersPerTeam - 1, (_) => null),
        ],
      ),
      TrucoTeam(
        id: 'team_2',
        name: 'Ellos',
        playerNames: List.generate(playersPerTeam, (_) => null),
      ),
    ];

    state = TrucoTrackerState(
      teams: initialTeams,
      targetScore: 30,
      selectedGame: trucoGame,
    );

    await saveLocalState();
  }

  int _normalizePlayerCount(int playerCount) {
    if (playerCount == 2 || playerCount == 4 || playerCount == 6) {
      return playerCount;
    }

    return 4;
  }

  void _updateState(TrucoTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  void setTargetScore(int targetScore) {
    if (targetScore != 15 && targetScore != 30) return;

    final updatedTeams = state.teams.map((team) {
      final total = team.totalPoints;

      if (targetScore == 15) {
        return team.copyWith(
          malas: total.clamp(0, 15).toInt(),
          buenas: 0,
        );
      }

      return team.copyWith(
        malas: team.malas.clamp(0, 15).toInt(),
        buenas: team.buenas.clamp(0, 15).toInt(),
      );
    }).toList();

    _updateState(
      state.copyWith(
        targetScore: targetScore,
        teams: updatedTeams,
      ),
    );
  }

  void addMalas(int teamIndex, int delta) {
    if (!_isValidTeamIndex(teamIndex)) return;
    if (state.isFinished && delta > 0) return;

    final currentTeam = state.teams[teamIndex];

    if (state.targetScore == 15) {
      setMalasScore(teamIndex, currentTeam.totalPoints + delta);
    } else {
      setMalasScore(teamIndex, currentTeam.malas + delta);
    }
  }

  void addBuenas(int teamIndex, int delta) {
    if (!_isValidTeamIndex(teamIndex)) return;
    if (state.isFinished && delta > 0) return;

    if (state.targetScore == 15) {
      addMalas(teamIndex, delta);
      return;
    }

    final currentTeam = state.teams[teamIndex];

    setBuenasScore(teamIndex, currentTeam.buenas + delta);
  }

  void setMalasScore(int teamIndex, int score) {
    if (!_isValidTeamIndex(teamIndex)) return;
    if (state.isFinished && score > state.teams[teamIndex].totalPoints) return;

    final updatedTeams = List<TrucoTeam>.from(state.teams);
    final currentTeam = updatedTeams[teamIndex];

    if (state.targetScore == 15) {
      final newScore = score.clamp(0, 15).toInt();

      updatedTeams[teamIndex] = currentTeam.copyWith(
        malas: newScore,
        buenas: 0,
      );
    } else {
      final newMalas = score.clamp(0, 15).toInt();

      updatedTeams[teamIndex] = currentTeam.copyWith(
        malas: newMalas,
      );
    }

    _updateState(
      state.copyWith(teams: updatedTeams),
    );
  }

  void setBuenasScore(int teamIndex, int score) {
    if (!_isValidTeamIndex(teamIndex)) return;
    if (state.targetScore == 15) {
      setMalasScore(teamIndex, score);
      return;
    }

    if (state.isFinished && score > state.teams[teamIndex].buenas) return;

    final updatedTeams = List<TrucoTeam>.from(state.teams);
    final currentTeam = updatedTeams[teamIndex];

    final newBuenas = score.clamp(0, 15).toInt();

    updatedTeams[teamIndex] = currentTeam.copyWith(
      buenas: newBuenas,
    );

    _updateState(
      state.copyWith(teams: updatedTeams),
    );
  }

  void updatePlayerNameInTeam(
    int teamIndex,
    int playerIndex,
    String? newName,
  ) {
    if (!_isValidTeamIndex(teamIndex)) return;

    final currentTeam = state.teams[teamIndex];

    if (playerIndex < 0 || playerIndex >= currentTeam.playerNames.length) {
      return;
    }

    if (!_canUsePlayerName(teamIndex, playerIndex, newName)) {
      return;
    }

    final updatedTeams = List<TrucoTeam>.from(state.teams);
    final updatedNames = List<String?>.from(currentTeam.playerNames);

    updatedNames[playerIndex] = newName;

    updatedTeams[teamIndex] = currentTeam.copyWith(
      playerNames: updatedNames,
    );

    _updateState(
      state.copyWith(teams: updatedTeams),
    );
  }

  bool _canUsePlayerName(
    int teamIndex,
    int playerIndex,
    String? playerName,
  ) {
    if (playerName == null) return true;

    for (int i = 0; i < state.teams.length; i++) {
      for (int j = 0; j < state.teams[i].playerNames.length; j++) {
        if (i == teamIndex && j == playerIndex) continue;

        if (state.teams[i].playerNames[j] == playerName) {
          return false;
        }
      }
    }

    return true;
  }

  void resetGame() {
    final resetTeams = state.teams.map((team) {
      return team.copyWith(
        malas: 0,
        buenas: 0,
      );
    }).toList();

    _updateState(
      state.copyWith(
        teams: resetTeams,
      ),
    );
  }

  bool _isValidTeamIndex(int teamIndex) {
    return teamIndex >= 0 && teamIndex < state.teams.length;
  }

  Future<void> saveLocalState() async {
    if (state.teams.isEmpty || _currentUserId.isEmpty || _currentKey.isEmpty) {
      return;
    }

    final data = {
      'teams': state.teams.map((team) {
        return {
          'id': team.id,
          'name': team.name,
          'playerNames': team.playerNames,
          'malas': team.malas,
          'buenas': team.buenas,
        };
      }).toList(),
      'targetScore': state.targetScore,
      'lastModified': DateTime.now().toIso8601String(),
    };

    await _localStorage.saveData(
      _currentKey,
      jsonEncode(data),
    );
  }

  Future<void> clearLocalState() async {
    if (_currentUserId.isEmpty || _currentKey.isEmpty) return;

    await _localStorage.removeData(_currentKey);

    state = TrucoTrackerState(
      teams: [],
      targetScore: 30,
    );
  }
}

final trucoTrackerProvider =
    NotifierProvider<TrucoTrackerNotifier, TrucoTrackerState>(() {
  return TrucoTrackerNotifier();
});