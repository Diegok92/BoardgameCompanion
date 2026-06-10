import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/local_catalog/local_games_catalog.dart';
import '../../../../data/repositories/tracker_local_store.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';

class TrucoTeam {
  final String id;
  final String name;
  final Color color;
  final List<String?> playerNames;
  final int malas;
  final int buenas;

  TrucoTeam({
    required this.id,
    required this.name,
    required this.color,
    required this.playerNames,
    this.malas = 0,
    this.buenas = 0,
  });

  int get totalPoints => malas + buenas;

  TrucoTeam copyWith({
    String? name,
    Color? color,
    List<String?>? playerNames,
    int? malas,
    int? buenas,
  }) {
    return TrucoTeam(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
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
  final TrackerLocalStore _store = TrackerLocalStore();

  @override
  TrucoTrackerState build() {
    return TrucoTrackerState(teams: [], targetScore: 30);
  }

  Future<void> initialize(int playerCount, User user, {String? fullKey}) async {
    state = TrucoTrackerState(teams: [], targetScore: 30);

    _store.resolveKey(
      fullKey: fullKey,
      prefix: 'truco',
      userId: user.id,
      playerCount: _normalizePlayerCount(playerCount),
    );

    Game? trucoGame;

    try {
      trucoGame = LocalGamesCatalog.games.firstWhere(
        (game) => game.id == 'truco',
      );
    } catch (_) {}

    final decoded = await _store.load();
    if (decoded != null) {
      try {
        final teamsJson = decoded['teams'] as List;

        final restoredTeams = teamsJson.map((teamJson) {
          final namesJson = teamJson['playerNames'] as List;

          return TrucoTeam(
            id: teamJson['id'],
            name: teamJson['name'],
            color: teamJson['color'] != null
                ? Color(teamJson['color'])
                : _defaultTeamColor(teamJson['id']),
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
      } catch (_) {}
    }

    final normalizedPlayerCount = _normalizePlayerCount(playerCount);
    final playersPerTeam = normalizedPlayerCount ~/ 2;

    final nosotrosColor = user.favoriteColor ?? AppColors.red;
    final ellosColor = AppColors.availableColors.firstWhere(
      (c) => c.toARGB32() != nosotrosColor.toARGB32(),
      orElse: () => AppColors.blue,
    );

    final initialTeams = [
      TrucoTeam(
        id: 'team_1',
        name: 'Nosotros',
        color: nosotrosColor,
        playerNames: [
          user.username,
          ...List.generate(playersPerTeam - 1, (_) => null),
        ],
      ),
      TrucoTeam(
        id: 'team_2',
        name: 'Ellos',
        color: ellosColor,
        playerNames: List.generate(playersPerTeam, (_) => null),
      ),
    ];

    // Partida nueva: NO se guarda hasta que el usuario modifique algo
    // (puntos, nombres o colores). Si entra y sale sin tocar nada, no queda
    // ninguna partida en curso.
    state = TrucoTrackerState(
      teams: initialTeams,
      targetScore: 30,
      selectedGame: trucoGame,
    );
  }

  int _normalizePlayerCount(int playerCount) {
    if (playerCount == 2 || playerCount == 4 || playerCount == 6) {
      return playerCount;
    }

    return 4;
  }

  /// Color por defecto al restaurar partidas viejas sin color guardado.
  Color _defaultTeamColor(String teamId) =>
      teamId == 'team_1' ? AppColors.red : AppColors.blue;

  void _updateState(TrucoTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  void setTargetScore(int targetScore) {
    if (targetScore != 15 && targetScore != 30) return;

    final updatedTeams = state.teams.map((team) {
      final total = team.totalPoints;

      if (targetScore == 15) {
        return team.copyWith(malas: total.clamp(0, 15).toInt(), buenas: 0);
      }

      return team.copyWith(
        malas: team.malas.clamp(0, 15).toInt(),
        buenas: team.buenas.clamp(0, 15).toInt(),
      );
    }).toList();

    _updateState(state.copyWith(targetScore: targetScore, teams: updatedTeams));
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

      updatedTeams[teamIndex] = currentTeam.copyWith(malas: newMalas);
    }

    _updateState(state.copyWith(teams: updatedTeams));
  }

  /// Agrega o quita un fósforo respetando el orden del Truco: en "A 30" primero
  /// se completan las malas (0..15) y recién ahí empiezan las buenas (0..15).
  /// En "A 15" hay una sola tira de 0..15.
  void addPoint(int teamIndex, int delta) {
    if (!_isValidTeamIndex(teamIndex)) return;
    if (state.isFinished && delta > 0) return;

    final team = state.teams[teamIndex];

    if (state.targetScore == 15) {
      setMalasScore(teamIndex, team.malas + delta);
      return;
    }

    if (delta > 0) {
      if (team.malas < 15) {
        setMalasScore(teamIndex, team.malas + 1);
      } else {
        setBuenasScore(teamIndex, team.buenas + 1);
      }
    } else {
      if (team.buenas > 0) {
        setBuenasScore(teamIndex, team.buenas - 1);
      } else {
        setMalasScore(teamIndex, team.malas - 1);
      }
    }
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

    updatedTeams[teamIndex] = currentTeam.copyWith(buenas: newBuenas);

    _updateState(state.copyWith(teams: updatedTeams));
  }

  void updatePlayerNameInTeam(int teamIndex, int playerIndex, String? newName) {
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

    updatedTeams[teamIndex] = currentTeam.copyWith(playerNames: updatedNames);

    _updateState(state.copyWith(teams: updatedTeams));
  }

  void updateTeamColor(int teamIndex, Color color) {
    if (!_isValidTeamIndex(teamIndex)) return;

    final updatedTeams = List<TrucoTeam>.from(state.teams);
    updatedTeams[teamIndex] = updatedTeams[teamIndex].copyWith(color: color);

    _updateState(state.copyWith(teams: updatedTeams));
  }

  bool _canUsePlayerName(int teamIndex, int playerIndex, String? playerName) {
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
      return team.copyWith(malas: 0, buenas: 0);
    }).toList();

    _updateState(state.copyWith(teams: resetTeams));
  }

  bool _isValidTeamIndex(int teamIndex) {
    return teamIndex >= 0 && teamIndex < state.teams.length;
  }

  Future<void> saveLocalState() async {
    if (state.teams.isEmpty || !_store.hasKey) return;

    final data = {
      'teams': state.teams.map((team) {
        return {
          'id': team.id,
          'name': team.name,
          'color': team.color.toARGB32(),
          'playerNames': team.playerNames,
          'malas': team.malas,
          'buenas': team.buenas,
        };
      }).toList(),
      'targetScore': state.targetScore,
    };

    await _store.save(data);
  }

  Future<void> clearLocalState() async {
    await _store.clear();
    state = TrucoTrackerState(teams: [], targetScore: 30);
  }
}

final trucoTrackerProvider =
    NotifierProvider<TrucoTrackerNotifier, TrucoTrackerState>(() {
      return TrucoTrackerNotifier();
    });
