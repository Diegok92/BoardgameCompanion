import '../../domain/models/accessory_model.dart';
import '../local_catalog/local_accessories_catalog.dart';

class AccessoriesRepository {
  Future<List<Accessory>> getAccessories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(LocalAccessoriesCatalog.accessories);
  }
}
