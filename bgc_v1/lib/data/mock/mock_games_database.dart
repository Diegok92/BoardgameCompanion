import '../../domain/models/game_model.dart';

class MockGamesDatabase {
  static const List<Game> games = [
    Game(
      id: 'hp_tracker',
      name: 'De Vida (HP)',
      isStandard: true,
      validPlayerCounts: [1, 2, 3, 4, 5, 6],
    ),
    Game(
      id: 'vp_tracker',
      name: 'De Puntos (VP)',
      isStandard: true,
      validPlayerCounts: [1, 2, 3, 4, 5, 6],
    ),
    Game(id: 'truco', name: 'Truco', validPlayerCounts: [2, 4, 6]),
    Game(id: 'burako', name: 'Burako', validPlayerCounts: [2, 3, 4]),
    Game(id: 'generala', name: 'Generala', validPlayerCounts: [2, 3, 4, 5, 6]),
    Game(id: 'akropolis', name: 'Akropolis', validPlayerCounts: [1, 2, 3, 4]),
  ];
}
