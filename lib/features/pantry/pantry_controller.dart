import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/pantry_item.dart';
import 'pantry_repository.dart';

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepository();
});

final pantryControllerProvider =
    NotifierProvider<PantryController, List<PantryItem>>(PantryController.new);

class PantryController extends Notifier<List<PantryItem>> {
  final _uuid = const Uuid();

  PantryRepository get _repo => ref.read(pantryRepositoryProvider);

  @override
  List<PantryItem> build() {
    // start empty, then load from storage
    _load();
    return [];
  }

  Future<void> _load() async {
    final items = await _repo.getAll();
    // Sort newest first (optional)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = items;
  }

  Future<void> addItem({
    required String name,
    required int quantity,
    required DateTime expiryDate,
    String? imagePath,
  }) async {
    final item = PantryItem(
      id: _uuid.v4(),
      name: name.trim(),
      quantity: quantity,
      expiryDate: expiryDate,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(item);
    state = [item, ...state];
  }

  Future<void> updateItem(PantryItem updated) async {
    await _repo.upsert(updated);
    state = [
      for (final i in state)
        if (i.id == updated.id) updated else i,
    ];
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteById(id);
    state = state.where((i) => i.id != id).toList();
  }

  Future<void> reload() async => _load();
}
