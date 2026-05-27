import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/partidas_repository.dart';
import '../../domain/models/partida_model.dart';
import 'auth_provider.dart';
import '../stats/providers/stats_provider.dart';
import '../historial/providers/historial_provider.dart';

// Proveedor del repositorio de partidas
final partidasRepositoryProvider = Provider<PartidasRepository>((ref) {
  return PartidasRepository();
});

final matchServiceProvider = Provider<MatchService>((ref) {
  final repository = ref.watch(partidasRepositoryProvider);
  final userId = ref.watch(authProvider)?.id;
  return MatchService(repository, userId, ref);
});

class MatchService {
  final PartidasRepository _repository;
  final String? _userId;
  final Ref _ref;

  MatchService(this._repository, this._userId, this._ref);

  /// Guarda una partida genérica calculando ganadores en base a los puntajes (el puntaje más alto gana)
  /// Si el juego tiene otras condiciones de victoria (ej. gana el que tiene menos puntos), 
  /// se deberá ajustar este método o sobrecargarlo a futuro.
  Future<void> saveMatch({
    required String gameId,
    required String gameName,
    required Map<String, int> playerScores,
    String status = 'finalizada',
    bool isTeamGame = false,
  }) async {
    if (_userId == null || _userId.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    if (playerScores.isEmpty) {
      throw Exception('No hay jugadores en la partida');
    }

    // Calcular ganadores (el que tiene más puntos)
    int maxScore = playerScores.values.reduce((a, b) => a > b ? a : b);
    List<String> ganadores = playerScores.entries
        .where((entry) => entry.value == maxScore)
        .map((entry) => entry.key)
        .toList();

    final partida = Partida(
      id: '',
      juegoId: gameId,
      juegoNombre: gameName,
      participantes: playerScores.keys.toList(),
      ganadores: ganadores,
      puntajesFinales: playerScores,
      estado: status,
      isTeamGame: isTeamGame,
    );

    await _repository.registrarPartida(_userId, partida);

    // Invalidar caché de estadísticas e historial para forzar actualización
    _ref.read(statsProvider.notifier).invalidateData();
    _ref.read(historialProvider.notifier).invalidateData();
  }
}
