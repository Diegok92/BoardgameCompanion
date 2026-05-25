abstract class ILocalStorageRepository {
  Future<void> saveData(String key, String data);
  Future<String?> getData(String key);
  Future<void> removeData(String key);
  Future<void> clearAllData();
}
