import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_model.dart';
import '../../data/repositories/games_repository.dart';

final gamesRepositoryProvider = Provider((ref) => GamesRepository());

// Proveedor asíncrono para obtener la lista base de juegos
final gamesProvider = FutureProvider<List<Game>>((ref) async {
  final repository = ref.watch(gamesRepositoryProvider);
  return await repository.getGames();
});

// Proveedor de estado para el campo de búsqueda de juegos
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

// Proveedor derivado que filtra la lista de juegos basada en el texto de búsqueda
final filteredGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
  final gamesAsyncValue = ref.watch(gamesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return gamesAsyncValue.whenData((games) {
    if (query.isEmpty) {
      return games;
    }
    return games
        .where((game) => game.name.toLowerCase().contains(query))
        .toList();
  });
});
