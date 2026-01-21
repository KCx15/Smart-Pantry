import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pantry_item.dart';
import 'pantry_controller.dart';
import 'add_item_screen.dart';

class PantryListScreen extends ConsumerWidget {
  const PantryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pantryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pantry'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: () =>
                ref.read(pantryControllerProvider.notifier).reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _PantryListTile(item: item);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddItemScreen()));
        },
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PantryListTile extends ConsumerWidget {
  final PantryItem item;

  const _PantryListTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete item?'),
                content: Text('Delete "${item.name}" from your pantry?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(pantryControllerProvider.notifier).deleteItem(item.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted ${item.name}')));
      },
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('Qty: ${item.quantity} • $daysLeft day(s) left'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
