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

extension AkropolisHexagonExtension on AkropolisHexagon {
  Color get color {
    switch (this) {
      case AkropolisHexagon.blue: return const Color(0xFF2D7DCA);
      case AkropolisHexagon.yellow: return const Color(0xFFF4C300);
      case AkropolisHexagon.red: return const Color(0xFFD9382E);
      case AkropolisHexagon.purple: return const Color(0xFF7D3C98);
      case AkropolisHexagon.green: return const Color(0xFF3E9C35);
      case AkropolisHexagon.stones: return const Color(0xFF9E9E9E);
    }
  }

  String get explanation {
    switch (this) {
      case AkropolisHexagon.blue:
        return "Residencias (Azul): Solo puntúa el grupo contiguo más grande.";
      case AkropolisHexagon.yellow:
        return "Mercados (Amarillo): Solo puntúan los que NO están adyacentes a otro mercado.";
      case AkropolisHexagon.red:
        return "Cuarteles (Rojo): Solo puntúan los que están en los bordes de la ciudad.";
      case AkropolisHexagon.purple:
        return "Templos (Violeta): Solo puntúan los que están completamente rodeados.";
      case AkropolisHexagon.green:
        return "Jardines (Verde): Puntúan siempre, sin restricciones.";
      case AkropolisHexagon.stones:
        return "Piedras: Valen 1 punto cada una.";
    }
  }
}

class AkropolisScore {
  final int value;
  final int stars;
  final bool isScored;
  const AkropolisScore({this.value = 0, this.stars = 0, this.isScored = false});

  int get total => stars == -1 ? value : value * stars; // -1 represents stones where no stars apply

  Map<String, dynamic> toJson() => {'value': value, 'stars': stars, 'isScored': isScored};
  factory AkropolisScore.fromJson(Map<String, dynamic> json) => AkropolisScore(
        value: json['value'] ?? 0,
        stars: json['stars'] ?? 0,
        isScored: json['isScored'] ?? true, // if saved without this field, assume it was scored
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
  String _currentKey = '';

  @override
  AkropolisTrackerState build() {
    return AkropolisTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: const AkropolisBuffer(),
    );
  }

  Future<void> initialize(int playerCount, User user, {String? fullKey}) async {
    _currentUserId = user.id;

    state = AkropolisTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: const AkropolisBuffer(),
    );

    String? localDataStr;
    if (fullKey != null) {
      _currentKey = fullKey;
      localDataStr = await _localStorage.getData(fullKey);
    } else {
      _currentKey = 'akropolis_state_${user.id}_${playerCount}_${DateTime.now().millisecondsSinceEpoch}';
    }

    Game? akropolisGame;
    try {
      akropolisGame = LocalGamesCatalog.games.firstWhere((g) => g.id == 'akropolis');
    } catch (_) {}

    if (localDataStr != null) {
      try {
        final decoded = jsonDecode(localDataStr);
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
  }

  void _updateState(AkropolisTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  void setActiveEntity(int index) {
    _updateState(state.copyWith(activeEntityIndex: index));
  }

  void updateEntity(int index, {String? name, Color? color}) {
    final newEntities = List<AkropolisEntity>.from(state.entities);
    newEntities[index] = newEntities[index].copyWith(name: name, color: color);
    _updateState(state.copyWith(entities: newEntities));
  }

  void setBufferHexagon(AkropolisHexagon hexagon) {
    _updateState(state.copyWith(
      buffer: state.buffer.copyWith(
        selectedHexagon: hexagon,
        districtValue: 0,
        starsValue: hexagon == AkropolisHexagon.stones ? -1 : 0,
      ),
    ));
  }

  void updateBuffer({int? districtValue, int? starsValue}) {
    _updateState(state.copyWith(
      buffer: state.buffer.copyWith(
        districtValue: districtValue,
        starsValue: starsValue,
      ),
    ));
  }

  void commitBuffer() {
    final activeIndex = state.activeEntityIndex;
    final entity = state.entities[activeIndex];
    
    final hex = state.buffer.selectedHexagon;
    final newScore = AkropolisScore(
      value: state.buffer.districtValue,
      stars: state.buffer.starsValue,
      isScored: true,
    );

    final newScores = Map<AkropolisHexagon, AkropolisScore>.from(entity.scores);
    newScores[hex] = newScore;

    final newEntity = entity.copyWith(scores: newScores);
    
    final newEntities = List<AkropolisEntity>.from(state.entities);
    newEntities[activeIndex] = newEntity;

    final nextIndex = (activeIndex + 1) % state.entities.length;
    var nextHex = hex;
    if (nextIndex == 0) {
      final hexValues = AkropolisHexagon.values;
      final currentHexIndex = hexValues.indexOf(hex);
      nextHex = hexValues[(currentHexIndex + 1) % hexValues.length];
    }

    _updateState(state.copyWith(
      entities: newEntities,
      activeEntityIndex: nextIndex,
      buffer: AkropolisBuffer(
        selectedHexagon: nextHex,
        districtValue: 0,
        starsValue: nextHex == AkropolisHexagon.stones ? -1 : 0,
      ),
    ));
  }

  void resetAllScores() {
    final newEntities = state.entities.map((e) => AkropolisEntity(
      id: e.id,
      name: e.name,
      color: e.color,
    )).toList();

    _updateState(state.copyWith(
      entities: newEntities,
      buffer: const AkropolisBuffer(),
    ));
  }

  Future<void> saveLocalState() async {
    if (_currentUserId.isEmpty || state.entities.isEmpty || _currentKey.isEmpty) return;
    
    final encoded = jsonEncode({
      'activeEntityIndex': state.activeEntityIndex,
      'entities': state.entities.map((e) => {
        'id': e.id,
        'name': e.name,
        'color': e.color.toARGB32(),
        'scores': e.scores.map((key, value) => MapEntry(key.toString(), value.toJson())),
      }).toList(),
      'lastModified': DateTime.now().toIso8601String(),
    });
    
    await _localStorage.saveData(_currentKey, encoded);
  }

  Future<void> clearLocalState() async {
    if (_currentUserId.isEmpty || _currentKey.isEmpty) return;
    await _localStorage.removeData(_currentKey);
  }
}

final akropolisTrackerProvider = NotifierProvider<AkropolisTrackerNotifier, AkropolisTrackerState>(() {
  return AkropolisTrackerNotifier();
});
