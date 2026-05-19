import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../domain/models/game_model.dart';
import '../../domain/models/user_model.dart';

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

  TrackerPlayer copyWith({
    String? name,
    Color? color,
    int? hp,
  }) {
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
  @override
  HpTrackerState build() {
    return HpTrackerState(players: [], initialHp: 0);
  }

  void initialize(int playerCount, User user, int initialHp) {
    List<TrackerPlayer> initialPlayers = [];
    
    // Obtener color del usuario, por defecto rojo si no tiene
    Color userColor = user.favoriteColor ?? AppColors.availableColors[0];
    
    initialPlayers.add(
      TrackerPlayer(
        index: 0,
        name: user.username,
        color: userColor,
        hp: initialHp,
      )
    );

    // Asignar colores random a los demás (que no sean el del usuario)
    List<Color> remainingColors = List.from(AppColors.availableColors)
      ..removeWhere((c) => c.toARGB32() == userColor.toARGB32());
    remainingColors.shuffle(Random());

    for (int i = 1; i < playerCount; i++) {
      Color randomColor = remainingColors.isNotEmpty 
          ? remainingColors.removeAt(0) 
          : Colors.grey; // Fallback si son más de 10 jugadores

      initialPlayers.add(
        TrackerPlayer(
          index: i,
          name: null, // Sin invitado asignado por defecto
          color: randomColor,
          hp: initialHp,
        )
      );
    }

    state = HpTrackerState(
      players: initialPlayers,
      selectedGame: null,
      initialHp: initialHp,
    );
  }

  void addHp(int index, int amount) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(
      hp: updatedPlayers[index].hp + amount
    );
    state = state.copyWith(players: updatedPlayers);
  }

  void resetHp() {
    final updatedPlayers = state.players.map((p) => p.copyWith(hp: state.initialHp)).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  void changeInitialHp(int delta) {
    int newInitial = state.initialHp + delta;
    if (newInitial < 1) newInitial = 1;
    state = state.copyWith(initialHp: newInitial);
  }

  void updatePlayerName(int index, String name) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(name: name);
    state = state.copyWith(players: updatedPlayers);
  }

  void updatePlayerColor(int index, Color newColor) {
    final updatedPlayers = List<TrackerPlayer>.from(state.players);
    updatedPlayers[index] = updatedPlayers[index].copyWith(color: newColor);
    state = state.copyWith(players: updatedPlayers);
  }

  void selectGame(Game? game) {
    state = HpTrackerState(
      players: state.players,
      selectedGame: game,
      initialHp: state.initialHp,
    );
  }
}

// Para pasarlo con parámetros usamos un Family si necesitamos instanciarlo con datos,
// pero como el popup va a definir el initialHp, lo hacemos NotifierProvider estándar
// y llamamos a initialize() al cargar la pantalla.
final hpTrackerProvider = NotifierProvider<HpTrackerNotifier, HpTrackerState>(() {
  return HpTrackerNotifier();
});
