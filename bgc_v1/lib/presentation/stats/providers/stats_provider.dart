import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/partida_model.dart';
import '../../../data/repositories/partidas_repository.dart';
import '../../providers/auth_provider.dart';

class StatsState {
  final bool isLoading;
  final bool hasFetched;
  final List<Partida> allPartidas;
  final String selectedJuego;
  final String selectedOpponent;

  final int totalPartidas;
  final int ganadas;
  final int perdidas;
  final int empatadas;
  final int rachaActual;

  StatsState({
    this.isLoading = true,
    this.hasFetched = false,
    this.allPartidas = const [],
    this.selectedJuego = 'TODOS',
    this.selectedOpponent = 'TODOS',
    this.totalPartidas = 0,
    this.ganadas = 0,
    this.perdidas = 0,
    this.empatadas = 0,
    this.rachaActual = 0,
  });

  StatsState copyWith({
    bool? isLoading,
    bool? hasFetched,
    List<Partida>? allPartidas,
    String? selectedJuego,
    String? selectedOpponent,
    int? totalPartidas,
    int? ganadas,
    int? perdidas,
    int? empatadas,
    int? rachaActual,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      allPartidas: allPartidas ?? this.allPartidas,
      selectedJuego: selectedJuego ?? this.selectedJuego,
      selectedOpponent: selectedOpponent ?? this.selectedOpponent,
      totalPartidas: totalPartidas ?? this.totalPartidas,
      ganadas: ganadas ?? this.ganadas,
      perdidas: perdidas ?? this.perdidas,
      empatadas: empatadas ?? this.empatadas,
      rachaActual: rachaActual ?? this.rachaActual,
    );
  }
}

class StatsNotifier extends Notifier<StatsState> {
  final PartidasRepository _repository = PartidasRepository();

  @override
  StatsState build() {
    return StatsState();
  }

  Future<void> fetchPartidas() async {
    if (state.hasFetched) return; // <-- CACHING LOGIC

    final user = ref.read(authProvider);
    if (user == null) return;

    state = state.copyWith(
      isLoading: true,
      selectedJuego: 'TODOS',
      selectedOpponent: 'TODOS',
    );
    try {
      final historial = await _repository.getHistorialPartidas(user.id);
      final validPartidas = historial
          .where((p) => p.estado == 'finalizada')
          .toList();

      validPartidas.sort((a, b) {
        if (a.fechaFinalizacion == null) return 1;
        if (b.fechaFinalizacion == null) return -1;
        return b.fechaFinalizacion!.compareTo(a.fechaFinalizacion!);
      });

      state = state.copyWith(
        allPartidas: validPartidas,
        isLoading: false,
        hasFetched: true,
      );

      _calculateStats();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Suma una partida recién terminada al cache en memoria y recalcula, SIN
  /// volver a leer Firestore. Si las stats todavía no se cargaron en esta
  /// sesión, no hace nada: la próxima carga ya la va a incluir.
  void addFinishedMatch(Partida partida) {
    if (!state.hasFetched || partida.estado != 'finalizada') return;

    final conFecha = partida.copyWith(
      fechaFinalizacion: partida.fechaFinalizacion ?? DateTime.now(),
    );
    // Va al frente porque es la más reciente (la lista está ordenada desc).
    state = state.copyWith(allPartidas: [conFecha, ...state.allPartidas]);
    _calculateStats();
  }

  void setJuegoFilter(String juego) {
    state = state.copyWith(selectedJuego: juego);
    _calculateStats();
  }

  void setOpponentFilter(String opponent) {
    state = state.copyWith(selectedOpponent: opponent);
    _calculateStats();
  }

  void _calculateStats() {
    final username = ref.read(authProvider)?.username;
    if (username == null) return;

    List<Partida> filtered = state.allPartidas.where((p) {
      bool matchJuego =
          state.selectedJuego == 'TODOS' ||
          p.juegoNombre.toUpperCase() == state.selectedJuego;
      bool matchOpponent = true;

      if (state.selectedOpponent != 'TODOS') {
        matchOpponent = p.participantes
            .map((n) => n.toUpperCase())
            .contains(state.selectedOpponent.toUpperCase());

        if (matchOpponent && p.isTeamGame) {
          bool isGanador = p.ganadores.contains(username);
          bool opponentWon = p.ganadores
              .map((g) => g.toUpperCase())
              .contains(state.selectedOpponent.toUpperCase());

          if (isGanador == opponentWon) {
            // Están en el mismo equipo (ambos ganaron o ambos perdieron). Ignorar la partida.
            matchOpponent = false;
          }
        }
      }

      return matchJuego && matchOpponent;
    }).toList();

    int ganadas = 0;
    int empatadas = 0;
    int perdidas = 0;
    int racha = 0;
    // Racha consecutiva desde la partida más reciente (lista ordenada desc).
    bool rachaRota = false;

    for (var p in filtered) {
      bool isGanador = p.ganadores.contains(username);

      if (state.selectedOpponent == 'TODOS') {
        bool isEmpate = isGanador && p.ganadores.length > 1 && !p.isTeamGame;
        if (isEmpate) {
          empatadas++;
          rachaRota = true;
        } else if (isGanador) {
          ganadas++;
          if (!rachaRota) racha++;
        } else {
          perdidas++;
          rachaRota = true;
        }
      } else {
        // Head-to-head contra el oponente seleccionado
        bool opponentWon = p.ganadores
            .map((g) => g.toUpperCase())
            .contains(state.selectedOpponent.toUpperCase());

        if (isGanador && opponentWon) {
          empatadas++;
          rachaRota = true;
        } else if (isGanador && !opponentWon) {
          ganadas++;
          if (!rachaRota) racha++;
        } else if (!isGanador && opponentWon) {
          perdidas++;
          rachaRota = true;
        } else {
          // Ganó un tercero: no cuenta en el mano a mano
          rachaRota = true;
        }
      }
    }

    state = state.copyWith(
      totalPartidas: filtered.length,
      ganadas: ganadas,
      empatadas: empatadas,
      perdidas: perdidas,
      rachaActual: racha,
    );
  }

  List<String> get uniqueJuegos {
    final juegos = state.allPartidas
        .map((p) => p.juegoNombre.toUpperCase())
        .toSet()
        .toList();
    juegos.sort();
    return ['TODOS', ...juegos];
  }

  List<String> get uniqueOpponents {
    final username = ref.read(authProvider)?.username ?? '';
    final ops = state.allPartidas
        .expand((p) => p.participantes)
        .where((p) => p != username)
        .map((p) => p.toUpperCase())
        .toSet()
        .toList();
    ops.sort();
    return ['TODOS', ...ops];
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(() {
  return StatsNotifier();
});
