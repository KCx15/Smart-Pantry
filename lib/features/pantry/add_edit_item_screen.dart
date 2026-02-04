import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
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
    final qty = int.parse(_qtyCtrl.text.trim());
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
    final title = _isEdit ? 'Edit Item' : 'Add Item';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Item Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Milk',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const _SectionLabel('Quantity'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., 1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Quantity required';
                    }
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null) return 'Enter a whole number';
                    if (parsed <= 0) return 'Must be at least 1';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const _SectionLabel('Expiry Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickExpiryDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _expiryDate == null
                          ? 'dd/mm/yyyy'
                          : _expiryDate!.toLocal().toString().split(' ').first,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const _SectionLabel('Item Image (Optional)'),
                const SizedBox(height: 8),
                _UploadBox(imagePath: _imagePath, onTap: _pickImage),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Expiry Reminders'),
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _UploadBox({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [6, 4],
        color: Colors.grey.shade400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: hasImage
                ? _ImagePreview(path: imagePath!)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload,
                          size: 34,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 10),
                        const Text('Tap to upload image'),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG up to 5MB',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;
  const _ImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: Text(
          'Image preview not supported on Web',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Text('Could not load image')),
    );
  }
}
