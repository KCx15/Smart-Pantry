import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/pantry_item.dart';
import 'pantry_repository.dart';
import '../../services/notification_service.dart';

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
    _load();
    return [];
  }

  Future<void> _load() async {
    final items = await _repo.getAll();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = items;
  }

  Future<void> addItem({
    required String name,
    required int quantity,
    required DateTime expiryDate,
    String? imagePath,
    bool reminderEnabled = false,
  }) async {
    final notifId = DateTime.now().millisecondsSinceEpoch.remainder(2000000000);

    final item = PantryItem(
      id: _uuid.v4(),
      name: name.trim(),
      quantity: quantity,
      expiryDate: expiryDate,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      reminderEnabled: reminderEnabled,
      notificationId: notifId,
    );
    await _repo.upsert(item);
    if (reminderEnabled) {
      await NotificationService.instance.scheduleExpiryReminder(
        notificationId: item.notificationId,
        itemName: item.name,
        expiryDate: item.expiryDate,
      );
    }
    state = [item, ...state];
  }

  Future<void> updateItem(PantryItem updated) async {
    final old = state.firstWhere((i) => i.id == updated.id);

    await _repo.upsert(updated);

    if (old.reminderEnabled) {
      await NotificationService.instance.cancel(old.notificationId);
    }

    if (updated.reminderEnabled) {
      await NotificationService.instance.scheduleExpiryReminder(
        notificationId: updated.notificationId,
        itemName: updated.name,
        expiryDate: updated.expiryDate,
      );
    }

    state = [
      for (final i in state)
        if (i.id == updated.id) updated else i,
    ];
  }

  Future<void> deleteItem(String id) async {
    final item = state.firstWhere((i) => i.id == id);

    if (item.reminderEnabled) {
      await NotificationService.instance.cancel(item.notificationId);
    }

    await _repo.deleteById(id);
    state = state.where((i) => i.id != id).toList();
  }

  Future<void> reload() async => _load();
}
