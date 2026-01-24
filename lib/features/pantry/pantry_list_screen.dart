import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pantry_item.dart';
import 'pantry_controller.dart';
import 'add_edit_item_screen.dart';
import 'dart:io';
import '../../services/notification_service.dart';

class PantryListScreen extends ConsumerStatefulWidget {
  const PantryListScreen({super.key});

  @override
  ConsumerState<PantryListScreen> createState() => _PantryListScreenState();
}

class _PantryListScreenState extends ConsumerState<PantryListScreen> {
  String _query = '';
  bool _expiringOnly = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(pantryControllerProvider);

    final filtered = items.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      if (!matchesQuery) return false;

      if (_expiringOnly) {
        final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;
        return daysLeft <= 3; // expiring in 3 days or less (incl expired)
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Pantry')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search items',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Expiring soon'),
                  selected: _expiringOnly,
                  onSelected: (v) => setState(() => _expiringOnly = v),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Reload',
                  onPressed: () =>
                      ref.read(pantryControllerProvider.notifier).reload(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      items.isEmpty
                          ? 'No items yet. Tap + to add one.'
                          : 'No matches. Try a different search.',
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _PantryListTile(item: item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditItemScreen()));
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

    final (label, icon) = daysLeft < 0
        ? ('Expired', Icons.error)
        : (
            daysLeft <= 3 ? 'Expiring' : 'OK',
            daysLeft <= 3 ? Icons.warning : Icons.check_circle,
          );

    final chipColor = daysLeft < 0
        ? Colors.red
        : (daysLeft <= 3 ? Colors.orange : Colors.green);

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
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditItemScreen(existing: item),
            ),
          );
        },
        title: Text(item.name),
        subtitle: Text('Qty: ${item.quantity} • $daysLeft day(s) left'),
        trailing: Chip(
          avatar: Icon(icon, size: 18, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white)),
          backgroundColor: chipColor,
        ),
        leading: item.imagePath == null
            ? const CircleAvatar(child: Icon(Icons.inventory_2))
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.imagePath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const CircleAvatar(child: Icon(Icons.broken_image)),
                ),
              ),
      ),
    );
  }
}
