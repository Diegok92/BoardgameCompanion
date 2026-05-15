import '../../domain/models/game_model.dart';
import '../local_catalog/local_games_catalog.dart';

class GamesRepository {
  // En el futuro, esto se conectará a una base de datos real (ej. Firestore)

  Future<List<Game>> getGames() async {
    // Simulamos latencia de red
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(LocalGamesCatalog.games); // Devolvemos una copia
  }
}
