import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pantry_item.dart';
import '../../services/image_service.dart';
import 'pantry_controller.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final PantryItem? existing;

  const AddEditItemScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;

  final _imageService = ImageService();
  String? _imagePath;

  DateTime? _expiryDate;
  bool _reminderEnabled = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _qtyCtrl = TextEditingController(
      text: (existing?.quantity ?? 1).toString(),
    );

    _expiryDate = existing?.expiryDate;
    _imagePath = existing?.imagePath;
    _reminderEnabled = existing?.reminderEnabled ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      ),
    );

    File? file;
    if (choice == 'camera') file = await _imageService.takePhoto();
    if (choice == 'gallery') file = await _imageService.pickFromGallery();

    if (file != null) {
      setState(() => _imagePath = file!.path);
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 7));
    final qty = int.parse(_qtyCtrl.text);
    final name = _nameCtrl.text.trim();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        name: name,
        quantity: qty,
        expiryDate: expiry,
        imagePath: _imagePath,
        reminderEnabled: _reminderEnabled,
      );
      await ref.read(pantryControllerProvider.notifier).updateItem(updated);
    } else {
      await ref
          .read(pantryControllerProvider.notifier)
          .addItem(
            name: name,
            quantity: qty,
            expiryDate: expiry,
            imagePath: _imagePath,
            reminderEnabled: _reminderEnabled,
          );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final expiryText = _expiryDate == null
        ? 'Pick expiry date (default: +7 days)'
        : 'Expiry: ${_expiryDate!.toLocal().toString().split(' ').first}';

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Item' : 'Add Item')),
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

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry reminder'),
                  subtitle: const Text(
                    'Notify me 2 days before expiry at 9:00 AM',
                  ),
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        _imagePath == null ? 'Add photo' : 'Change photo',
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_imagePath != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagePath!),
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Text('Could not load image'),
                          ),
                        ),
                      ),
                  ],
                ),

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isEdit ? 'Save changes' : 'Save'),
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
