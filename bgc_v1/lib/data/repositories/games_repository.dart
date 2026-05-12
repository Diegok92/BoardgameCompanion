import '../../domain/models/game_model.dart';
import '../mock/mock_games_database.dart';

class GamesRepository {
  // En el futuro, esto se conectará a una base de datos real (ej. Firestore)

  Future<List<Game>> getGames() async {
    // Simulamos latencia de red
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(MockGamesDatabase.games); // Devolvemos una copia
  }
}
