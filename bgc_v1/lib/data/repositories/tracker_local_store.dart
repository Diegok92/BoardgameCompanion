import 'dart:convert';

import '../../domain/repositories/i_local_storage_repository.dart';
import 'local_storage_repository.dart';

/// Helper de persistencia local reutilizable por todos los anotadores (trackers).
///
/// Centraliza lo que antes repetía cada provider: la generación de la clave, la
/// (de)serialización JSON, el sellado de `lastModified` y el guardado/borrado.
/// Cada anotador sigue definiendo SU `toJson`/`fromJson` y su estado por defecto
/// (lo específico del juego); esta clase solo se ocupa de la plomería común.
class TrackerLocalStore {
  final ILocalStorageRepository _storage;
  String _key = '';

  TrackerLocalStore({ILocalStorageRepository? storage})
    : _storage = storage ?? LocalStorageRepository();

  String get key => _key;
  bool get hasKey => _key.isNotEmpty;

  /// Define la clave de la partida: usa [fullKey] si viene (retomar una partida
  /// en curso) o genera una nueva con el formato estándar
  /// `{prefix}_state_{userId}_{playerCount}_{timestamp}`.
  void resolveKey({
    String? fullKey,
    required String prefix,
    required String userId,
    required int playerCount,
  }) {
    _key =
        fullKey ??
        '${prefix}_state_${userId}_${playerCount}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Devuelve el estado guardado decodificado, o `null` si no hay nada / falla.
  Future<Map<String, dynamic>?> load() async {
    if (_key.isEmpty) return null;
    final raw = await _storage.getData(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Guarda [data] bajo la clave actual, agregando `lastModified` automáticamente.
  Future<void> save(Map<String, dynamic> data) async {
    if (_key.isEmpty) return;
    final payload = <String, dynamic>{
      ...data,
      'lastModified': DateTime.now().toIso8601String(),
    };
    await _storage.saveData(_key, jsonEncode(payload));
  }

  Future<void> clear() async {
    if (_key.isEmpty) return;
    await _storage.removeData(_key);
  }
}
