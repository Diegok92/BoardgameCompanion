import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/local_storage_repository.dart';
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

  int get totalPoints => (pureCanastas * 200) + (impureCanastas * 100) + (hasMuerto ? -100 : 0) + (hasCierre ? 100 : 0) + fichasScore;

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
  final LocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentUserId = '';

  @override
  BurakoTrackerState build() {
    return BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );
  }

  Future<void> initialize(int playerCount, User user) async {
    _currentUserId = user.id;

    // Resetear
    state = BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );

    final savedData = await _localStorage.getData('burako_state_${user.id}_$playerCount');

    Game? burakoGame;
    try {
      burakoGame = LocalGamesCatalog.games.firstWhere((g) => g.id == 'burako');
    } catch (_) {}

    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData);
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
          buffer: BurakoBuffer(), // El buffer siempre empieza limpio al cargar
          selectedGame: burakoGame,
        );
        return;
      } catch (e) {
        // Fallback
      }
    }

    // Inicialización por defecto
    List<BurakoEntity> initialEntities = [];
    Color userColor = user.favoriteColor ?? AppColors.availableColors[0];
    
    List<Color> remainingColors = List.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    if (playerCount == 4) {
      // 4 jugadores = 2 equipos
      initialEntities.add(BurakoEntity(
        id: 'equipo_1',
        name: 'Nosotros',
        playerNames: [user.username, null], // Usuario + Invitado
        color: userColor,
      ));
      initialEntities.add(BurakoEntity(
        id: 'equipo_2',
        name: 'Ellos',
        playerNames: [null, null], // Invitado + Invitado
        color: remainingColors[0],
      ));
    } else {
      // 2 o 3 jugadores = individuales
      initialEntities.add(BurakoEntity(
        id: 'jugador_1',
        name: user.username,
        playerNames: [user.username],
        color: userColor,
      ));
      
      for (int i = 1; i < playerCount; i++) {
        initialEntities.add(BurakoEntity(
          id: 'jugador_${i+1}',
          name: 'Jugador ${i+1}',
          playerNames: [null],
          color: remainingColors[i - 1],
        ));
      }
    }

    state = BurakoTrackerState(
      entities: initialEntities,
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
      selectedGame: burakoGame,
    );
  }

  void updatePureCanastas(int delta) {
    int val = max(0, state.buffer.pureCanastas + delta);
    state = state.copyWith(buffer: state.buffer.copyWith(pureCanastas: val));
  }

  void updateImpureCanastas(int delta) {
    int val = max(0, state.buffer.impureCanastas + delta);
    state = state.copyWith(buffer: state.buffer.copyWith(impureCanastas: val));
  }

  void _updateBuffer(BurakoBuffer newBuffer) {
    state = state.copyWith(buffer: newBuffer);
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
    state = state.copyWith(buffer: state.buffer.copyWith(fichasScore: val));
  }

  void setActiveEntity(int index) {
    state = state.copyWith(activeEntityIndex: index);
  }

  void commitBuffer() {
    if (state.entities.isEmpty) return;
    
    final points = state.buffer.totalPoints;
    final updatedEntities = List<BurakoEntity>.from(state.entities);
    
    final currentEntity = updatedEntities[state.activeEntityIndex];
    updatedEntities[state.activeEntityIndex] = currentEntity.copyWith(
      totalScore: currentEntity.totalScore + points
    );

    // Avanzar al siguiente jugador/equipo automáticamente y limpiar el buffer
    int nextIndex = (state.activeEntityIndex + 1) % state.entities.length;

    state = state.copyWith(
      entities: updatedEntities,
      buffer: BurakoBuffer(), // Reset buffer
      activeEntityIndex: nextIndex,
    );
  }

  void resetGame() {
    final updatedEntities = state.entities.map((e) => e.copyWith(totalScore: 0)).toList();
    state = state.copyWith(
      entities: updatedEntities,
      buffer: BurakoBuffer(),
      activeEntityIndex: 0,
    );
  }

  void updateEntityColor(int index, Color color) {
    final updated = List<BurakoEntity>.from(state.entities);
    updated[index] = updated[index].copyWith(color: color);
    state = state.copyWith(entities: updated);
  }

  void updatePlayerNameInEntity(int entityIndex, int playerIndex, String? newName) {
    final updated = List<BurakoEntity>.from(state.entities);
    final currentEntity = updated[entityIndex];
    final updatedNames = List<String?>.from(currentEntity.playerNames);
    updatedNames[playerIndex] = newName;
    
    // Si es juego individual, actualizar también el nombre de la entidad para que se vea reflejado en el header
    String entityName = currentEntity.name;
    if (updatedNames.length == 1) {
      entityName = newName ?? 'Jugador ${entityIndex + 1}';
    }

    updated[entityIndex] = currentEntity.copyWith(
      playerNames: updatedNames,
      name: entityName,
    );
    state = state.copyWith(entities: updated);
  }

  Future<void> saveLocalState() async {
    if (state.entities.isEmpty || _currentUserId.isEmpty) return;
    
    // Solo usamos count = 2 o 3 o 4 (que agrupa en 2 pero la inicialización pidió 4)
    // Para simplificar, la key se basará en la cantidad de jugadores totales.
    int totalPlayers = state.entities.fold(0, (sum, e) => sum + e.playerNames.length);

    final data = {
      'entities': state.entities.map((e) => {
        'id': e.id,
        'name': e.name,
        'playerNames': e.playerNames,
        'color': e.color.toARGB32(),
        'totalScore': e.totalScore,
      }).toList(),
      'activeEntityIndex': state.activeEntityIndex,
    };
    
    await _localStorage.saveData('burako_state_${_currentUserId}_$totalPlayers', jsonEncode(data));
  }

  Future<void> clearLocalState() async {
    if (state.entities.isEmpty || _currentUserId.isEmpty) return;
    int totalPlayers = state.entities.fold(0, (sum, e) => sum + e.playerNames.length);
    await _localStorage.removeData('burako_state_${_currentUserId}_$totalPlayers');
    
    // Clear state in memory so next time it initializes fresh
    state = BurakoTrackerState(
      entities: [],
      activeEntityIndex: 0,
      buffer: BurakoBuffer(),
    );
  }
}

final burakoTrackerProvider = NotifierProvider<BurakoTrackerNotifier, BurakoTrackerState>(() {
  return BurakoTrackerNotifier();
});
