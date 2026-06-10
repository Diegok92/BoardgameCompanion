import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/tracker_local_store.dart';
import '../../../../data/local_catalog/local_games_catalog.dart';
import '../../../../domain/models/game_model.dart';
import '../../../../domain/models/user_model.dart';

class TrackerPlayer {
  final int index; // 0 es el usuario
  final String? name; // null significa "Seleccionar invitado" o "Jugador X"
  final Color color;
  final int hp;

  TrackerPlayer({
    required this.index,
    this.name,
    required this.color,
    required this.hp,
  });

  TrackerPlayer copyWith({String? name, Color? color, int? hp}) {
    return TrackerPlayer(
      index: index,
      name: name ?? this.name,
      color: color ?? this.color,
      hp: hp ?? this.hp,
    );
  }
}

class HpTrackerState {
  final List<TrackerPlayer> players;
  final Game? selectedGame;
  final int initialHp;

  HpTrackerState({
    required this.players,
    this.selectedGame,
    required this.initialHp,
  });

  HpTrackerState copyWith({
    List<TrackerPlayer>? players,
    Game? selectedGame,
    int? initialHp,
  }) {
    return HpTrackerState(
      players: players ?? this.players,
      selectedGame: selectedGame ?? this.selectedGame,
      initialHp: initialHp ?? this.initialHp,
    );
  }
}

class HpTrackerNotifier extends Notifier<HpTrackerState> {
  final TrackerLocalStore _store = TrackerLocalStore();

  @override
  HpTrackerState build() {
    return HpTrackerState(players: [], initialHp: 0);
  }

  Future<void> initialize(
    int playerCount,
    User user,
    int initialHp, {
    String? fullKey,
  }) async {
    state = HpTrackerState(players: [], initialHp: 0);

    _store.resolveKey(
      fullKey: fullKey,
      prefix: 'tracker',
      userId: user.id,
      playerCount: playerCount,
    );

    final decoded = await _store.load();
    if (decoded != null) {
      try {
        final playersJson = decoded['players'] as List;
        List<TrackerPlayer> restoredPlayers = playersJson
            .map(
              (p) => TrackerPlayer(
                index: p['index'],
                name: p['name'],
                color: Color(p['color']),
                hp: p['hp'],
              ),
            )
            .toList();
        String? gameId = decoded['selectedGameId'];
        Game? restoredGame;
        if (gameId != null) {
          try {
            restoredGame = LocalGamesCatalog.trackerGames.firstWhere(
              (g) => g.id == gameId,
            );
          } catch (_) {}
        }

        state = HpTrackerState(
          players: restoredPlayers,
          selectedGame: restoredGame,
          initialHp: decoded['initialHp'] ?? initialHp,
        );
        return;
      } catch (e) {
        // ignore
      }
    }

    List<TrackerPlayer> initialPlayers = [];

    Color userColor = user.favoriteColor ?? AppColors.availableColors[0];

    initialPlayers.add(
      TrackerPlayer(
        index: 0,
        name: user.username,
        color: userColor,
        hp: initialHp,
      ),
    );

    List<Color> remainingColors = List.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    for (int i = 1; i < playerCount; i++) {
      // Fallback grey if palette exhausted (>10 players)
      Color randomColor = remainingColors.isNotEmpty
          ? remainingColors.removeAt(0)
          : Colors.grey;

      initialPlayers.add(
        TrackerPlayer(index: i, name: null, color: randomColor, hp: initialHp),
      );
    }

    state = HpTrackerState(
      players: initialPlayers,
      selectedGame: null,
      initialHp: initialHp,
    );
  }

  void _updateState(HpTrackerState newState) {
    state = newState;
    saveLocalState();
  }

  void addHp(int index, int amount) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(
      hp: updatedPlayers[index].hp + amount,
    );
    _updateState(state.copyWith(players: updatedPlayers));
  }

  void resetHp() {
    final updatedPlayers = state.players
        .map((p) => p.copyWith(hp: state.initialHp))
        .toList();
    _updateState(state.copyWith(players: updatedPlayers));
  }

  void setInitialHp(int val) {
    if (val < 1) val = 1;
    _updateState(state.copyWith(initialHp: val));
  }

  void updatePlayerName(int index, String name) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(name: name);
    _updateState(state.copyWith(players: updatedPlayers));
  }

  void updatePlayerColor(int index, Color newColor) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(color: newColor);
    _updateState(state.copyWith(players: updatedPlayers));
  }

  void selectGame(Game? game) {
    _updateState(
      HpTrackerState(
        players: state.players,
        selectedGame: game,
        initialHp: state.initialHp,
      ),
    );
  }

  Future<void> saveLocalState() async {
    if (state.players.isEmpty || !_store.hasKey) return;

    final data = {
      'players': state.players
          .map(
            (p) => {
              'index': p.index,
              'name': p.name,
              'color': p.color.toARGB32(),
              'hp': p.hp,
            },
          )
          .toList(),
      'initialHp': state.initialHp,
      'selectedGameId': state.selectedGame?.id,
    };

    await _store.save(data);
  }

  Future<void> clearLocalState() async {
    await _store.clear();
  }
}

final hpTrackerProvider = NotifierProvider<HpTrackerNotifier, HpTrackerState>(
  () {
    return HpTrackerNotifier();
  },
);
