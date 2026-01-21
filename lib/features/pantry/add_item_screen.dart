import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pantry_controller.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 7));
    final qty = int.parse(_qtyCtrl.text);

    await ref
        .read(pantryControllerProvider.notifier)
        .addItem(name: _nameCtrl.text, quantity: qty, expiryDate: expiry);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final expiryText = _expiryDate == null
        ? 'Pick expiry date (default: +7 days)'
        : 'Expiry: ${_expiryDate!.toLocal().toString().split(' ').first}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g., Pasta',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g., 2',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Quantity required';
                    final parsed = int.tryParse(v);
                    if (parsed == null) return 'Enter a whole number';
                    if (parsed <= 0) return 'Must be at least 1';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickExpiryDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(expiryText),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
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
