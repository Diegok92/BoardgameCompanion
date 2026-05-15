import '../../domain/models/accessory_model.dart';
import '../local_catalog/local_accessories_catalog.dart';

class AccessoriesRepository {
  // En el futuro, esto se conectará a una base de datos real

  Future<List<Accessory>> getAccessories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(LocalAccessoriesCatalog.accessories);
  }
}
