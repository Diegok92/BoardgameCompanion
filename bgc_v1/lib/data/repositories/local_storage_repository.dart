import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/i_local_storage_repository.dart';

class LocalStorageRepository implements ILocalStorageRepository {
  /// Guarda un valor String en local storage
  @override
  Future<void> saveData(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  /// Recupera un valor String de local storage
  @override
  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Recupera todas las llaves almacenadas
  @override
  Future<Set<String>> getKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  /// Borra un valor de local storage
  @override
  Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Borra todos los valores de local storage (Caché de partidas)
  @override
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
