import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/partidas_repository.dart';
import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/repositories/i_local_storage_repository.dart';
import '../../../domain/models/partida_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/local_catalog/local_games_catalog.dart';

class HistorialState {
  final bool isLoading;
  final bool hasFetched;
  final bool isFetchingMore;
  final List<Partida> localPartidas;
  final List<Partida> firestorePartidas;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final String statusFilter; // 'TODOS', 'FINALIZADA', 'EN CURSO'

  HistorialState({
    this.isLoading = true,
    this.hasFetched = false,
    this.isFetchingMore = false,
    this.localPartidas = const [],
    this.firestorePartidas = const [],
    this.lastDocument,
    this.hasMore = true,
    this.statusFilter = 'TODOS',
  });

  List<Partida> get filteredPartidas {
    List<Partida> all = [];
    
    if (statusFilter == 'TODOS' || statusFilter == 'EN CURSO') {
      all.addAll(localPartidas);
    }
    
    if (statusFilter == 'TODOS' || statusFilter == 'FINALIZADA') {
      all.addAll(firestorePartidas);
    }

    // Ordenar de más reciente a más antigua
    all.sort((a, b) {
      if (a.fechaFinalizacion == null && b.fechaFinalizacion == null) return 0;
      if (a.fechaFinalizacion == null) return 1;
      if (b.fechaFinalizacion == null) return -1;
      return b.fechaFinalizacion!.compareTo(a.fechaFinalizacion!);
    });

    return all;
  }

  HistorialState copyWith({
    bool? isLoading,
    bool? hasFetched,
    bool? isFetchingMore,
    List<Partida>? localPartidas,
    List<Partida>? firestorePartidas,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    String? statusFilter,
  }) {
    // Si pasamos lastDocument como null explícitamente, no lo copiamos, lo sobreescribimos.
    // Usamos un pequeño truco: pasamos un valor especial o simplemente comprobamos.
    // Para simplificar, asumiremos que se pasa correctamente.
    return HistorialState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      localPartidas: localPartidas ?? this.localPartidas,
      firestorePartidas: firestorePartidas ?? this.firestorePartidas,
      lastDocument: lastDocument, // Forzamos la actualización directa para manejar nulls
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
  
  // Custom copy para manejar nullable explícito de lastDocument
  HistorialState copyWithNullDocument({
    bool? isLoading,
    bool? hasFetched,
    List<Partida>? localPartidas,
    List<Partida>? firestorePartidas,
    bool? hasMore,
    String? statusFilter,
  }) {
    return HistorialState(
      isLoading: isLoading ?? this.isLoading,
      hasFetched: hasFetched ?? this.hasFetched,
      isFetchingMore: false,
      localPartidas: localPartidas ?? this.localPartidas,
      firestorePartidas: firestorePartidas ?? this.firestorePartidas,
      lastDocument: null,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class HistorialNotifier extends Notifier<HistorialState> {
  final PartidasRepository _firestoreRepo = PartidasRepository();
  final ILocalStorageRepository _localRepo = LocalStorageRepository();

  @override
  HistorialState build() {
    // Iniciamos la carga al instanciar
    Future.microtask(() => initialFetch());
    return HistorialState();
  }

  Future<void> initialFetch() async {
    if (state.hasFetched) return; // <-- CACHING LOGIC

    final user = ref.read(authProvider);
    if (user == null) return;

    state = state.copyWithNullDocument(isLoading: true, hasMore: true);

    try {
      // 1. Cargar locales
      final localMatches = await fetchLocalMatches(user.id);

      // 2. Cargar primera página de Firestore
      final result = await _firestoreRepo.getHistorialPartidasPaginated(user.id, limit: 15);
      
      state = state.copyWith(
        isLoading: false,
        hasFetched: true,
        localPartidas: localMatches,
        firestorePartidas: result['partidas'] as List<Partida>,
        lastDocument: result['lastDocument'] as DocumentSnapshot?,
        hasMore: result['hasMore'] as bool,
      );
    } catch (e) {
      state = state.copyWithNullDocument(isLoading: false, hasMore: false);
    }
  }

  void invalidateData() {
    state = state.copyWith(hasFetched: false);
    initialFetch();
  }

  Future<void> fetchMore() async {
    if (!state.hasMore || state.isFetchingMore || state.isLoading) return;

    final user = ref.read(authProvider);
    if (user == null || state.lastDocument == null) return;

    state = state.copyWith(isFetchingMore: true, lastDocument: state.lastDocument);

    try {
      final result = await _firestoreRepo.getHistorialPartidasPaginated(
        user.id,
        lastDocument: state.lastDocument,
        limit: 15,
      );

      final newPartidas = result['partidas'] as List<Partida>;
      
      state = state.copyWith(
        isFetchingMore: false,
        firestorePartidas: [...state.firestorePartidas, ...newPartidas],
        lastDocument: result['lastDocument'] as DocumentSnapshot?,
        hasMore: result['hasMore'] as bool,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, lastDocument: state.lastDocument);
    }
  }

  Future<List<Partida>> fetchLocalMatches(String userId) async {
    final keys = await _localRepo.getKeys();
    List<Partida> locales = [];

    for (final key in keys) {
      if (key.startsWith('burako_state_${userId}_') ||
          key.startsWith('akropolis_state_${userId}_') ||
          key.startsWith('tracker_state_${userId}_')) {
        
        final dataStr = await _localRepo.getData(key);
        if (dataStr == null) continue;

        try {
          final decoded = jsonDecode(dataStr);
          DateTime? lastModified;
          if (decoded['lastModified'] != null) {
            lastModified = DateTime.parse(decoded['lastModified']);
          } else {
            // Fallback si la crearon antes de añadir el campo
            lastModified = null; 
          }

          String gameName = 'Desconocido';
          String gameId = '';
          List<String> participantes = [];
          bool isTeamGame = false;

          if (key.startsWith('burako_state_')) {
            gameName = 'Burako';
            gameId = 'burako';
            final entities = decoded['entities'] as List;
            for (var e in entities) {
              final names = e['playerNames'] as List;
              for (var n in names) {
                if (n != null && n.toString().isNotEmpty) {
                  participantes.add(n.toString());
                } else {
                  participantes.add('Jugador');
                }
              }
            }
            if (participantes.length == 4) isTeamGame = true;
          } 
          else if (key.startsWith('akropolis_state_')) {
            gameName = 'Akropolis';
            gameId = 'akropolis';
            final entities = decoded['entities'] as List;
            participantes = entities.map((e) => e['name'].toString()).toList();
          }
          else if (key.startsWith('tracker_state_')) {
            String? selectedId = decoded['selectedGameId'];
            if (selectedId != null && selectedId.isNotEmpty) {
              gameId = selectedId;
              try {
                gameName = LocalGamesCatalog.trackerGames.firstWhere((g) => g.id == selectedId).name;
              } catch (_) {
                gameName = 'Por Puntos - HP';
              }
            } else {
              gameId = 'hp_tracker';
              gameName = 'Por Puntos - HP';
            }
            final players = decoded['players'] as List;
            participantes = players.map((p) => p['name']?.toString() ?? 'Jugador').toList();
          }

          locales.add(Partida(
            id: key, // Usamos la key como ID para saber cuál borrar o cargar
            juegoId: gameId, 
            juegoNombre: gameName,
            participantes: participantes,
            ganadores: [],
            puntajesFinales: {},
            estado: 'en curso',
            isTeamGame: isTeamGame,
            fechaFinalizacion: lastModified, // Usamos este campo para ordenar
          ));
        } catch (e) {
          // Ignorar error de parseo
        }
      }
    }
    
    // Ordenar locales por lastModified descendente
    locales.sort((a, b) {
      if (a.fechaFinalizacion == null && b.fechaFinalizacion == null) return 0;
      if (a.fechaFinalizacion == null) return 1;
      if (b.fechaFinalizacion == null) return -1;
      return b.fechaFinalizacion!.compareTo(a.fechaFinalizacion!);
    });
    return locales;
  }

  void setFilter(String filter) {
    state = state.copyWith(statusFilter: filter, lastDocument: state.lastDocument);
  }

  Future<void> removeLocalMatch(String key) async {
    await _localRepo.removeData(key);
    // Remover del estado actual para no recargar todo de Firestore
    final updated = state.localPartidas.where((p) => p.id != key).toList();
    state = state.copyWith(localPartidas: updated, lastDocument: state.lastDocument);
  }

  Future<void> removeFirestoreMatch(String id) async {
    final user = ref.read(authProvider);
    if (user != null) {
      await _firestoreRepo.borrarPartida(user.id, id);
      final updated = state.firestorePartidas.where((p) => p.id != id).toList();
      state = state.copyWith(firestorePartidas: updated, lastDocument: state.lastDocument);
    }
  }
}

final historialProvider = NotifierProvider<HistorialNotifier, HistorialState>(() {
  return HistorialNotifier();
});
