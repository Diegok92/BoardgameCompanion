import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/tracker_local_store.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';
import '../../../../data/local_catalog/local_games_catalog.dart';

class BurakoEntity {
  final String id;
  final String name; // "Diego", "Jugador 2", "Nosotros", "Ellos"
  final List<String?> playerNames; // Los integrantes reales
  final Color color;
  final int totalScore;

  BurakoEntity({
    required this.id,
    required this.name,
    required this.playerNames,
    required this.color,
    this.totalScore = 0,
  });

  BurakoEntity copyWith({
    String? name,
    List<String?>? playerNames,
    Color? color,
    int? totalScore,
  }) {
    return BurakoEntity(
      id: id,
      name: name ?? this.name,
      playerNames: playerNames ?? this.playerNames,
      color: color ?? this.color,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}

class BurakoBuffer {
  final int pureCanastas;
  final int impureCanastas;
  final bool hasMuerto;
  final bool hasCierre;
  final int fichasScore;

  BurakoBuffer({
    this.pureCanastas = 0,
    this.impureCanastas = 0,
    this.hasMuerto = false,
    this.hasCierre = false,
    this.fichasScore = 0,
  });

  int get totalPoints =>
      (pureCanastas * 200) +
      (impureCanastas * 100) +
      (hasMuerto ? -100 : 0) +
      (hasCierre ? 100 : 0) +
      fichasScore;

  BurakoBuffer copyWith({
    int? pureCanastas,
    int? impureCanastas,
    bool? hasMuerto,
    bool? hasCierre,
    int? fichasScore,
  }) {
    return BurakoBuffer(
      pureCanastas: pureCanastas ?? this.pureCanastas,
      impureCanastas: impureCanastas ?? this.impureCanastas,
      hasMuerto: hasMuerto ?? this.hasMuerto,
      hasCierre: hasCierre ?? this.hasCierre,
      fichasScore: fichasScore ?? this.fichasScore,
    );
  }
}

class BurakoTrackerState {
  final List<BurakoEntity> entities;
  final int activeEntityIndex;
  final BurakoBuffer buffer;
  final Game? selectedGame;

  BurakoTrackerState({
    required this.entities,
    required this.activeEntityIndex,
    required this.buffer,
    this.selectedGame,
  });

  BurakoTrackerState copyWith({
    List<BurakoEntity>? entities,
    int? activeEntityIndex,
    BurakoBuffer? buffer,
    Game? selectedGame,
  }) {
    return BurakoTrackerState(
      entities: entities ?? this.entities,
      activeEntityIndex: activeEntityIndex ?? this.activeEntityIndex,
      buffer: buffer ?? this.buffer,
      selectedGame: selectedGame ?? this.selectedGame,
    );
  }
}

class BurakoTrackerNotifier extends Notifier<BurakoTrackerState> {
  final TrackerLocalStore _store = TrackerLocalStore();

  @override
  BurakoTrackerState build() {
    return BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );
  }

  Future<void> initialize(int playerCount, User user, {String? fullKey}) async {
    state = BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );

    _store.resolveKey(
      fullKey: fullKey,
      prefix: 'burako',
      userId: user.id,
      playerCount: playerCount,
    );

    Game? burakoGame;
    try {
      burakoGame = LocalGamesCatalog.games.firstWhere((g) => g.id == 'burako');
    } catch (_) {}

    final decoded = await _store.load();
    if (decoded != null) {
      try {
        final entitiesJson = decoded['entities'] as List;
        List<BurakoEntity> restoredEntities = entitiesJson.map((e) {
          final List<dynamic> namesJson = e['playerNames'];
          return BurakoEntity(
            id: e['id'],
            name: e['name'],
            playerNames: namesJson.map((n) => n as String?).toList(),
            color: Color(e['color']),
            totalScore: e['totalScore'],
          );
        }).toList();

        state = BurakoTrackerState(
          entities: restoredEntities,
          activeEntityIndex: decoded['activeEntityIndex'] ?? 0,
          buffer: BurakoBuffer(),
          selectedGame: burakoGame,
        );
        return;
      } catch (_) {}
    }

    List<BurakoEntity> initialEntities = [];
    Color userColor = user.favoriteColor ?? AppColors.availableColors[0];

    List<Color> remainingColors = List.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    if (playerCount == 4) {
      initialEntities.add(
        BurakoEntity(
          id: 'equipo_1',
          name: 'Nosotros',
          playerNames: [user.username, null],
          color: userColor,
        ),
      );
      initialEntities.add(
        BurakoEntity(
          id: 'equipo_2',
          name: 'Ellos',
          playerNames: [null, null],
          color: remainingColors[0],
        ),
      );
    } else {
      initialEntities.add(
        BurakoEntity(
          id: 'jugador_1',
          name: user.username,
          playerNames: [user.username],
          color: userColor,
        ),
      );

      for (int i = 1; i < playerCount; i++) {
        initialEntities.add(
          BurakoEntity(
            id: 'jugador_${i + 1}',
            name: 'Jugador ${i + 1}',
            playerNames: [null],
            color: remainingColors[i - 1],
          ),
        );
      }
    }

    state = BurakoTrackerState(
      entities: initialEntities,
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
      selectedGame: burakoGame,
    );
  }

  void _updateState(BurakoTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  void updatePureCanastas(int delta) {
    int val = max(0, state.buffer.pureCanastas + delta);
    _updateState(
      state.copyWith(buffer: state.buffer.copyWith(pureCanastas: val)),
    );
  }

  void updateImpureCanastas(int delta) {
    int val = max(0, state.buffer.impureCanastas + delta);
    _updateState(
      state.copyWith(buffer: state.buffer.copyWith(impureCanastas: val)),
    );
  }

  void _updateBuffer(BurakoBuffer newBuffer) {
    _updateState(state.copyWith(buffer: newBuffer));
  }

  void toggleMuerto(bool value) {
    var newBuffer = state.buffer.copyWith(hasMuerto: value);
    if (value && newBuffer.hasCierre) {
      newBuffer = newBuffer.copyWith(hasCierre: false);
    }
    _updateBuffer(newBuffer);
  }

  void toggleCierre(bool value) {
    var newBuffer = state.buffer.copyWith(hasCierre: value);
    if (value && newBuffer.hasMuerto) {
      newBuffer = newBuffer.copyWith(hasMuerto: false);
    }
    _updateBuffer(newBuffer);
  }

  void setFichasScore(int val) {
    _updateState(
      state.copyWith(buffer: state.buffer.copyWith(fichasScore: val)),
    );
  }

  void setActiveEntity(int index) {
    _updateState(state.copyWith(activeEntityIndex: index));
  }

  void commitBuffer() {
    if (state.entities.isEmpty) return;

    final points = state.buffer.totalPoints;
    final updatedEntities = List<BurakoEntity>.from(state.entities);

    final currentEntity = updatedEntities[state.activeEntityIndex];
    updatedEntities[state.activeEntityIndex] = currentEntity.copyWith(
      totalScore: currentEntity.totalScore + points,
    );

    int nextIndex = (state.activeEntityIndex + 1) % state.entities.length;

    _updateState(
      state.copyWith(
        entities: updatedEntities,
        buffer: BurakoBuffer(),
        activeEntityIndex: nextIndex,
      ),
    );
  }

  void resetGame() {
    final updatedEntities = state.entities
        .map((e) => e.copyWith(totalScore: 0))
        .toList();
    _updateState(
      state.copyWith(
        entities: updatedEntities,
        buffer: BurakoBuffer(),
        activeEntityIndex: 0,
      ),
    );
  }

  void updateEntityColor(int index, Color color) {
    final updated = List<BurakoEntity>.from(state.entities);
    updated[index] = updated[index].copyWith(color: color);
    _updateState(state.copyWith(entities: updated));
  }

  void updatePlayerNameInEntity(
    int entityIndex,
    int playerIndex,
    String? newName,
  ) {
    final updated = List<BurakoEntity>.from(state.entities);
    final currentEntity = updated[entityIndex];
    final updatedNames = List<String?>.from(currentEntity.playerNames);
    updatedNames[playerIndex] = newName;

    // En juego individual el nombre de entidad refleja el del jugador
    String entityName = currentEntity.name;
    if (updatedNames.length == 1) {
      entityName = newName ?? 'Jugador ${entityIndex + 1}';
    }

    updated[entityIndex] = currentEntity.copyWith(
      playerNames: updatedNames,
      name: entityName,
    );
    _updateState(state.copyWith(entities: updated));
  }

  Future<void> saveLocalState() async {
    if (state.entities.isEmpty || !_store.hasKey) return;

    final data = {
      'entities': state.entities
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'playerNames': e.playerNames,
              'color': e.color.toARGB32(),
              'totalScore': e.totalScore,
            },
          )
          .toList(),
      'activeEntityIndex': state.activeEntityIndex,
    };

    await _store.save(data);
  }

  Future<void> clearLocalState() async {
    await _store.clear();
    state = BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );
  }
}

final burakoTrackerProvider =
    NotifierProvider<BurakoTrackerNotifier, BurakoTrackerState>(() {
      return BurakoTrackerNotifier();
    });
