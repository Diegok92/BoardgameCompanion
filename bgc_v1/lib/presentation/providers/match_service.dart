import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/partidas_repository.dart';
import '../../domain/models/partida_model.dart';
import 'auth_provider.dart';

// Proveedor del repositorio de partidas
final partidasRepositoryProvider = Provider<PartidasRepository>((ref) {
  return PartidasRepository();
});

// Proveedor del servicio de partidas
final matchServiceProvider = Provider<MatchService>((ref) {
  final repository = ref.watch(partidasRepositoryProvider);
  final userId = ref.watch(authProvider)?.id;
  return MatchService(repository, userId);
});

class MatchService {
  final PartidasRepository _repository;
  final String? _userId;

  MatchService(this._repository, this._userId);

  /// Guarda una partida genérica calculando ganadores en base a los puntajes (el puntaje más alto gana)
  /// Si el juego tiene otras condiciones de victoria (ej. gana el que tiene menos puntos), 
  /// se deberá ajustar este método o sobrecargarlo a futuro.
  Future<void> saveMatch({
    required String gameId,
    required String gameName,
    required Map<String, int> playerScores,
    String status = 'finalizada',
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
    );

    await _repository.registrarPartida(_userId, partida);
  }
}
