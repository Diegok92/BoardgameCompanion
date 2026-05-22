import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRepository {
  /// Guarda un valor String en local storage
  Future<void> saveData(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  /// Recupera un valor String de local storage
  Future<String?> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Borra un valor de local storage
  Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
