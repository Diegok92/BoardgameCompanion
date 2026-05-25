import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/local_storage_repository.dart';
import '../../../../domain/repositories/i_local_storage_repository.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../data/local_catalog/local_games_catalog.dart';

enum AkropolisHexagon { blue, yellow, red, purple, green, stones }

class AkropolisScore {
  final int value;
  final int stars;
  const AkropolisScore({this.value = 0, this.stars = 0});

  int get total => stars == -1 ? value : value * stars; // -1 represents stones where no stars apply

  Map<String, dynamic> toJson() => {'value': value, 'stars': stars};
  factory AkropolisScore.fromJson(Map<String, dynamic> json) => AkropolisScore(
        value: json['value'] ?? 0,
        stars: json['stars'] ?? 0,
      );
}

class AkropolisEntity {
  final String id;
  final String name;
  final Color color;
  final Map<AkropolisHexagon, AkropolisScore> scores;

  AkropolisEntity({
    required this.id,
    required this.name,
    required this.color,
    Map<AkropolisHexagon, AkropolisScore>? scores,
  }) : scores = scores ?? {
          AkropolisHexagon.blue: const AkropolisScore(),
          AkropolisHexagon.yellow: const AkropolisScore(),
          AkropolisHexagon.red: const AkropolisScore(),
          AkropolisHexagon.purple: const AkropolisScore(),
          AkropolisHexagon.green: const AkropolisScore(),
          AkropolisHexagon.stones: const AkropolisScore(stars: -1),
        };

  int get totalScore => scores.values.fold(0, (sum, score) => sum + score.total);

  AkropolisEntity copyWith({
    String? name,
    Color? color,
    Map<AkropolisHexagon, AkropolisScore>? scores,
  }) {
    return AkropolisEntity(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      scores: scores ?? this.scores,
    );
  }
}

class AkropolisBuffer {
  final AkropolisHexagon selectedHexagon;
  final int districtValue;
  final int starsValue;

  const AkropolisBuffer({
    this.selectedHexagon = AkropolisHexagon.blue,
    this.districtValue = 0,
    this.starsValue = 0,
  });

  int get totalPoints => selectedHexagon == AkropolisHexagon.stones ? districtValue : districtValue * starsValue;

  AkropolisBuffer copyWith({
    AkropolisHexagon? selectedHexagon,
    int? districtValue,
    int? starsValue,
  }) {
    return AkropolisBuffer(
      selectedHexagon: selectedHexagon ?? this.selectedHexagon,
      districtValue: districtValue ?? this.districtValue,
      starsValue: starsValue ?? this.starsValue,
    );
  }
}

class AkropolisTrackerState {
  final List<AkropolisEntity> entities;
  final int activeEntityIndex;
  final AkropolisBuffer buffer;
  final Game? selectedGame;

  AkropolisTrackerState({
    required this.entities,
    required this.activeEntityIndex,
    required this.buffer,
    this.selectedGame,
  });

  AkropolisTrackerState copyWith({
    List<AkropolisEntity>? entities,
    int? activeEntityIndex,
    AkropolisBuffer? buffer,
    Game? selectedGame,
  }) {
    return AkropolisTrackerState(
      entities: entities ?? this.entities,
      activeEntityIndex: activeEntityIndex ?? this.activeEntityIndex,
      buffer: buffer ?? this.buffer,
      selectedGame: selectedGame ?? this.selectedGame,
    );
  }
}

class AkropolisTrackerNotifier extends Notifier<AkropolisTrackerState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentUserId = '';
  int _playerCount = 2;

  @override
  AkropolisTrackerState build() {
    return AkropolisTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: const AkropolisBuffer(),
    );
  }

  Future<void> initialize(int playerCount, User user) async {
    _currentUserId = user.id;
    _playerCount = playerCount;

    state = AkropolisTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: const AkropolisBuffer(),
    );

    final savedData = await _localStorage.getData('akropolis_state_${user.id}_$_playerCount');

    Game? akropolisGame;
    try {
      akropolisGame = LocalGamesCatalog.games.firstWhere((g) => g.id == 'akropolis');
    } catch (_) {}

    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData);
        final entitiesJson = decoded['entities'] as List;
        List<AkropolisEntity> restoredEntities = entitiesJson.map((e) {
          final scoresJson = e['scores'] as Map<String, dynamic>;
          final Map<AkropolisHexagon, AkropolisScore> restoredScores = {};
          scoresJson.forEach((key, value) {
            restoredScores[AkropolisHexagon.values.firstWhere((e) => e.toString() == key)] = AkropolisScore.fromJson(value);
          });
          return AkropolisEntity(
            id: e['id'],
            name: e['name'],
            color: Color(e['color']),
            scores: restoredScores,
          );
        }).toList();

        state = AkropolisTrackerState(
          entities: restoredEntities,
          activeEntityIndex: decoded['activeEntityIndex'] ?? 0,
          buffer: const AkropolisBuffer(),
          selectedGame: akropolisGame,
        );
        return;
      } catch (e) {
        // Fallback si falla
      }
    }

    List<AkropolisEntity> initialEntities = [];
    Color userColor = user.favoriteColor ?? AppColors.availableColors[0];
    
    List<Color> remainingColors = List.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    initialEntities.add(AkropolisEntity(
      id: 'jugador_1',
      name: user.username,
      color: userColor,
    ));

    if (playerCount == 1) {
      initialEntities.add(AkropolisEntity(
        id: 'ilustre',
        name: 'Ilustre',
        color: remainingColors[0],
      ));
    } else {
      for (int i = 1; i < playerCount; i++) {
        initialEntities.add(AkropolisEntity(
          id: 'jugador_${i + 1}',
          name: 'Jugador ${i + 1}',
          color: remainingColors[i - 1],
        ));
      }
    }

    state = state.copyWith(
      entities: initialEntities,
      selectedGame: akropolisGame,
    );

    saveLocalState();
  }

  void setActiveEntity(int index) {
    state = state.copyWith(activeEntityIndex: index);
    saveLocalState();
  }

  void updateEntity(int index, {String? name, Color? color}) {
    final newEntities = List<AkropolisEntity>.from(state.entities);
    newEntities[index] = newEntities[index].copyWith(name: name, color: color);
    state = state.copyWith(entities: newEntities);
    saveLocalState();
  }

  void setBufferHexagon(AkropolisHexagon hexagon) {
    state = state.copyWith(
      buffer: state.buffer.copyWith(
        selectedHexagon: hexagon,
        districtValue: 0,
        starsValue: hexagon == AkropolisHexagon.stones ? -1 : 0,
      ),
    );
  }

  void updateBuffer({int? districtValue, int? starsValue}) {
    state = state.copyWith(
      buffer: state.buffer.copyWith(
        districtValue: districtValue,
        starsValue: starsValue,
      ),
    );
  }

  void commitBuffer() {
    final activeIndex = state.activeEntityIndex;
    final entity = state.entities[activeIndex];
    
    final hex = state.buffer.selectedHexagon;
    final newScore = AkropolisScore(
      value: state.buffer.districtValue,
      stars: state.buffer.starsValue,
    );

    final newScores = Map<AkropolisHexagon, AkropolisScore>.from(entity.scores);
    newScores[hex] = newScore;

    final newEntity = entity.copyWith(scores: newScores);
    
    final newEntities = List<AkropolisEntity>.from(state.entities);
    newEntities[activeIndex] = newEntity;

    state = state.copyWith(
      entities: newEntities,
      buffer: const AkropolisBuffer(), // Reset buffer (default is blue)
    );
    saveLocalState();
  }

  void resetAllScores() {
    final newEntities = state.entities.map((e) => AkropolisEntity(
      id: e.id,
      name: e.name,
      color: e.color,
    )).toList();

    state = state.copyWith(
      entities: newEntities,
      buffer: const AkropolisBuffer(),
    );
    saveLocalState();
  }

  Future<void> saveLocalState() async {
    if (_currentUserId.isEmpty) return;
    
    final encoded = jsonEncode({
      'activeEntityIndex': state.activeEntityIndex,
      'entities': state.entities.map((e) => {
        'id': e.id,
        'name': e.name,
        'color': e.color.toARGB32(),
        'scores': e.scores.map((key, value) => MapEntry(key.toString(), value.toJson())),
      }).toList(),
    });
    
    await _localStorage.saveData('akropolis_state_${_currentUserId}_$_playerCount', encoded);
  }
}

final akropolisTrackerProvider = NotifierProvider<AkropolisTrackerNotifier, AkropolisTrackerState>(() {
  return AkropolisTrackerNotifier();
});
