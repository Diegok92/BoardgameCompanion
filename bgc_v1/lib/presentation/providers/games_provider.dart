import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_model.dart';
import '../../data/repositories/games_repository.dart';

final gamesRepositoryProvider = Provider((ref) => GamesRepository());

final gamesProvider = FutureProvider<List<Game>>((ref) async {
  final repository = ref.watch(gamesRepositoryProvider);
  return await repository.getGames();
});

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
