import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accessory_model.dart';
import '../../data/repositories/accessories_repository.dart';

final accessoriesRepositoryProvider = Provider(
  (ref) => AccessoriesRepository(),
);

final accessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  final repository = ref.watch(accessoriesRepositoryProvider);
  return await repository.getAccessories();
});
