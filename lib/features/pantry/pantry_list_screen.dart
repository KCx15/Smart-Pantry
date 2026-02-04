import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pantry_item.dart';
import 'add_edit_item_screen.dart';
import 'pantry_controller.dart';

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
        return daysLeft <= 3;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Pantry')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SearchBar(onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
              Row(
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
              const SizedBox(height: 8),
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
                          return _PantryCard(item: item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditItemScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search pantry items...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _PantryCard extends ConsumerWidget {
  final PantryItem item;

  const _PantryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    final String daysText = daysLeft < 0
        ? 'Expired'
        : '${daysLeft == 1 ? 1 : daysLeft} day${daysLeft == 1 ? '' : 's'} left';

    final Color daysColor = daysLeft <= 2
        ? Colors.red
        : (daysLeft <= 5 ? Colors.orange : Colors.green);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
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
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditItemScreen(existing: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingImage(imagePath: item.imagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  daysText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: daysColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingImage extends StatelessWidget {
  final String? imagePath;

  const _LeadingImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const CircleAvatar(radius: 22, child: Icon(Icons.inventory_2));
    }

    // Web cannot preview Image.file
    if (kIsWeb) {
      return const CircleAvatar(
        radius: 22,
        child: Icon(Icons.image_not_supported),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath!),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const CircleAvatar(radius: 22, child: Icon(Icons.broken_image)),
      ),
    );
  }
}
