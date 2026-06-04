import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/repositories/local_storage_repository.dart';
import '../../../../../domain/repositories/i_local_storage_repository.dart';
import '../../../../../domain/models/game_model.dart';
import '../../../../../domain/models/user_model.dart';
import '../../../../../data/local_catalog/local_games_catalog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum de categorías
// ─────────────────────────────────────────────────────────────────────────────

enum GeneralaCategory {
  ones, twos, threes, fours, fives, sixes,
  escalera, full, poker, generala, dobleGenerala,
}

extension GeneralaCategoryExt on GeneralaCategory {
  /// Etiqueta para la tabla (puede ser multilinea)
  String get tableLabel {
    switch (this) {
      case GeneralaCategory.ones:          return '1';
      case GeneralaCategory.twos:          return '2';
      case GeneralaCategory.threes:        return '3';
      case GeneralaCategory.fours:         return '4';
      case GeneralaCategory.fives:         return '5';
      case GeneralaCategory.sixes:         return '6';
      case GeneralaCategory.escalera:      return 'Escalera';
      case GeneralaCategory.full:          return 'Full';
      case GeneralaCategory.poker:         return 'Poker';
      case GeneralaCategory.generala:      return 'Generala';
      case GeneralaCategory.dobleGenerala: return 'Doble\nGenerala';
    }
  }

  /// Etiqueta para dropdown (siempre una línea)
  String get dropdownLabel {
    if (this == GeneralaCategory.dobleGenerala) return 'Doble Generala';
    return tableLabel;
  }

  bool get isNumeric => index <= GeneralaCategory.sixes.index;
  int  get faceValue  => isNumeric ? (index + 1) : 0;

  int get servidaScore {
    switch (this) {
      case GeneralaCategory.escalera:      return 25;
      case GeneralaCategory.full:          return 35;
      case GeneralaCategory.poker:         return 45;
      case GeneralaCategory.generala:      return 50;
      case GeneralaCategory.dobleGenerala: return 100;
      default:                             return 0;
    }
  }

  int get noServidaScore {
    switch (this) {
      case GeneralaCategory.escalera: return 20;
      case GeneralaCategory.full:     return 30;
      case GeneralaCategory.poker:    return 40;
      default:                        return servidaScore;
    }
  }

  bool get hasServidaOption =>
      this == GeneralaCategory.escalera ||
      this == GeneralaCategory.full ||
      this == GeneralaCategory.poker;

  String get toKey => toString().split('.').last;

  static GeneralaCategory fromKey(String key) =>
      GeneralaCategory.values.firstWhere((c) => c.toKey == key);
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de entidad (jugador)
// ─────────────────────────────────────────────────────────────────────────────

class GeneralaEntity {
  final String id;
  final String name;
  final Color color;
  final Map<GeneralaCategory, int?> scores; // null = sin anotar

  GeneralaEntity({
    required this.id,
    required this.name,
    required this.color,
    Map<GeneralaCategory, int?>? scores,
  }) : scores = scores ?? {for (final c in GeneralaCategory.values) c: null};

  int get total =>
      scores.values.whereType<int>().fold(0, (sum, v) => sum + v);

  bool get isComplete =>
      scores.values.every((v) => v != null);

  GeneralaEntity copyWith({
    String? name,
    Color? color,
    Map<GeneralaCategory, int?>? scores,
  }) {
    return GeneralaEntity(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      scores: scores ?? Map.from(this.scores),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'scores': {
          for (final e in scores.entries) e.key.toKey: e.value,
        },
      };

  factory GeneralaEntity.fromJson(Map<String, dynamic> json) {
    final scoresRaw = (json['scores'] as Map<String, dynamic>?) ?? {};
    final parsed = <GeneralaCategory, int?>{};
    for (final c in GeneralaCategory.values) {
      parsed[c] = scoresRaw.containsKey(c.toKey)
          ? (scoresRaw[c.toKey] as int?)
          : null;
    }
    return GeneralaEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      scores: parsed,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buffer (selección en curso del panel de entrada)
// ─────────────────────────────────────────────────────────────────────────────

class GeneralaBuffer {
  final int activeEntityIndex;
  final GeneralaCategory selectedCategory;
  final int? pendingScore;

  const GeneralaBuffer({
    this.activeEntityIndex = 0,
    this.selectedCategory = GeneralaCategory.ones,
    this.pendingScore,
  });

  GeneralaBuffer copyWith({
    int? activeEntityIndex,
    GeneralaCategory? selectedCategory,
    int? pendingScore,
    bool clearPending = false,
  }) {
    return GeneralaBuffer(
      activeEntityIndex: activeEntityIndex ?? this.activeEntityIndex,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      pendingScore: clearPending ? null : (pendingScore ?? this.pendingScore),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado global del tracker
// ─────────────────────────────────────────────────────────────────────────────

class GeneralaTrackerState {
  final List<GeneralaEntity> entities;
  final GeneralaBuffer buffer;
  final Game? selectedGame;

  const GeneralaTrackerState({
    this.entities = const [],
    this.buffer = const GeneralaBuffer(),
    this.selectedGame,
  });

  bool get isComplete =>
      entities.isNotEmpty && entities.every((e) => e.isComplete);

  GeneralaTrackerState copyWith({
    List<GeneralaEntity>? entities,
    GeneralaBuffer? buffer,
    Game? selectedGame,
  }) {
    return GeneralaTrackerState(
      entities: entities ?? this.entities,
      buffer: buffer ?? this.buffer,
      selectedGame: selectedGame ?? this.selectedGame,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class GeneralaTrackerNotifier extends Notifier<GeneralaTrackerState> {
  final ILocalStorageRepository _localStorage = LocalStorageRepository();
  String _currentUserId = '';
  String _currentKey = '';

  @override
  GeneralaTrackerState build() => const GeneralaTrackerState();

  // ── Inicialización ──────────────────────────────────────────────────────────

  Future<void> initialize(int playerCount, User user, {String? fullKey}) async {
    _currentUserId = user.id;
    state = const GeneralaTrackerState();

    String? savedData;
    if (fullKey != null) {
      _currentKey = fullKey;
      savedData = await _localStorage.getData(fullKey);
    } else {
      _currentKey =
          'generala_state_${user.id}_${playerCount}_${DateTime.now().millisecondsSinceEpoch}';
    }

    Game? game;
    try {
      game = LocalGamesCatalog.games.firstWhere((g) => g.id == 'generala');
    } catch (_) {}

    // Restaurar partida guardada
    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData) as Map<String, dynamic>;
        final entities = (decoded['entities'] as List)
            .map((e) => GeneralaEntity.fromJson(e as Map<String, dynamic>))
            .toList();
        final savedIdx = (decoded['activeEntityIndex'] as int?) ?? 0;
        state = GeneralaTrackerState(
          entities: entities,
          buffer: GeneralaBuffer(
            activeEntityIndex: savedIdx.clamp(0, entities.length - 1),
            selectedCategory: _firstUnscoredFor(entities, savedIdx.clamp(0, entities.length - 1)),
          ),
          selectedGame: game,
        );
        return;
      } catch (_) {}
    }

    // Partida nueva
    final userColor = user.favoriteColor ?? AppColors.availableColors[0];
    final remaining = List<Color>.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32())
      ..shuffle(Random());

    final entities = <GeneralaEntity>[
      GeneralaEntity(id: 'jugador_1', name: user.username, color: userColor),
      for (int i = 1; i < playerCount; i++)
        GeneralaEntity(
          id: 'jugador_${i + 1}',
          name: 'Jugador ${i + 1}',
          color: remaining[(i - 1) % remaining.length],
        ),
    ];

    state = GeneralaTrackerState(entities: entities, selectedGame: game);
    saveLocalState();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  GeneralaCategory _firstUnscoredFor(List<GeneralaEntity> entities, int idx) {
    if (idx >= entities.length) return GeneralaCategory.ones;
    final scores = entities[idx].scores;
    for (final c in GeneralaCategory.values) {
      if (scores[c] == null) return c;
    }
    return GeneralaCategory.ones;
  }

  void _updateState(GeneralaTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  // ── Acciones del buffer ─────────────────────────────────────────────────────

  void setActiveEntity(int index) {
    _updateState(state.copyWith(
      buffer: state.buffer.copyWith(
        activeEntityIndex: index,
        selectedCategory: _firstUnscoredFor(state.entities, index),
        clearPending: true,
      ),
    ));
  }

  void setCategory(GeneralaCategory category) {
    _updateState(state.copyWith(
      buffer: state.buffer.copyWith(
        selectedCategory: category,
        clearPending: true,
      ),
    ));
  }

  void setPendingScore(int score) {
    _updateState(state.copyWith(
      buffer: state.buffer.copyWith(pendingScore: score),
    ));
  }

  /// Confirma el puntaje pendiente y lo guarda en el jugador activo.
  void commitScore() {
    final pending = state.buffer.pendingScore;
    if (pending == null) return;

    final idx = state.buffer.activeEntityIndex;
    final category = state.buffer.selectedCategory;
    final entity = state.entities[idx];

    // No sobreescribir si ya está anotada
    if (entity.scores[category] != null) return;

    final newScores = Map<GeneralaCategory, int?>.from(entity.scores)
      ..[category] = pending;

    final updated = List<GeneralaEntity>.from(state.entities);
    updated[idx] = entity.copyWith(scores: newScores);

    final nextCategory = _firstUnscoredFor(updated, idx);

    _updateState(state.copyWith(
      entities: updated,
      buffer: state.buffer.copyWith(
        selectedCategory: nextCategory,
        clearPending: true,
      ),
    ));
  }

  // ── Jugadores ───────────────────────────────────────────────────────────────

  void updateEntity(int index, {String? name, Color? color}) {
    final updated = List<GeneralaEntity>.from(state.entities);
    updated[index] = updated[index].copyWith(name: name, color: color);
    _updateState(state.copyWith(entities: updated));
  }

  // ── Persistencia ────────────────────────────────────────────────────────────

  void resetAllScores() {
    clearLocalState();
    state = const GeneralaTrackerState();
  }

  Future<void> saveLocalState() async {
    if (_currentUserId.isEmpty || _currentKey.isEmpty) return;
    final data = {
      'entities': state.entities.map((e) => e.toJson()).toList(),
      'activeEntityIndex': state.buffer.activeEntityIndex,
      'lastModified': DateTime.now().toIso8601String(),
    };
    await _localStorage.saveData(_currentKey, jsonEncode(data));
  }

  Future<void> clearLocalState() async {
    if (_currentKey.isNotEmpty) {
      await _localStorage.removeData(_currentKey);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final generalaTrackerProvider =
    NotifierProvider<GeneralaTrackerNotifier, GeneralaTrackerState>(
  () => GeneralaTrackerNotifier(),
);
