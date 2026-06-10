import '../../domain/models/game_model.dart';
import '../local_catalog/local_games_catalog.dart';

class GamesRepository {
  Future<List<Game>> getGames() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(LocalGamesCatalog.games);
  }
}
