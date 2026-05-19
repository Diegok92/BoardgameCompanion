import '../../domain/models/game_model.dart';

class LocalGamesCatalog {
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

  // Juegos que NO tienen un anotador especial, sino que se juegan
  // usando los anotadores estándar (HP o VP). Solo aparecen en los dropdowns de los anotadores.
  static const List<Game> trackerGames = [
    Game(id: 'carcassonne', name: 'Carcassonne'),
    Game(id: 'epic', name: 'Epic Card Game'),
    Game(id: 'mindbug', name: 'Mindbug'),
    Game(id: 'oceanos_de_papel', name: 'Océanos de Papel'),
    Game(id: 'red7', name: 'Red 7'),
    Game(id: 'star_realms', name: 'Star Realms'),
    Game(id: 'uno', name: 'UNO'),
  ];
}
