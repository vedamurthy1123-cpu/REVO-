import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/admin_provider.dart';
import '../../widgets/revo_app_bar.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  XFile? _pickedImage;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    // 1. Upload image if picked
    String? finalImageUrl;
    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      finalImageUrl = await admin.uploadProductImage(bytes, _pickedImage!.name);
    }

    // 2. Add item
    final ok = await admin.addItem(
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
      imageUrl: finalImageUrl,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Item added successfully!')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(admin.error ?? 'Failed to add item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RevoAppBar(showBack: true, showCart: false, showMenu: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Item',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),

              // Image Selector
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.none),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('ADD PRODUCT IMAGE', 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.5)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              _field('Item Name', _nameCtrl, 'e.g. A4 Notebook',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _field('Price (₹)', _priceCtrl, '25.00',
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return 'Invalid';
                          return null;
                        }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field('Stock', _stockCtrl, '50',
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = int.tryParse(v);
                          if (n == null || n < 0) return 'Invalid';
                          return null;
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _field('Category', _catCtrl, 'e.g. Stationery'),
              const SizedBox(height: 20),
              _field('Description', _descCtrl, 'Brief description',
                  maxLines: 3),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('ADD ITEM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }
}
