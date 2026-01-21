import '../../models/pantry_item.dart';
import '../../services/hive_service.dart';

class PantryRepository {
  Future<List<PantryItem>> getAll() async {
    final box = HiveService.pantryBox();
    return box.values.toList();
  }

  Future<void> upsert(PantryItem item) async {
    final box = HiveService.pantryBox();
    await box.put(item.id, item);
  }

  Future<void> deleteById(String id) async {
    final box = HiveService.pantryBox();
    await box.delete(id);
  }
}
