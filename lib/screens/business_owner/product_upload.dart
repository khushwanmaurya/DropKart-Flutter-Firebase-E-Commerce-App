// lib/screens/business_owner/product_upload.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends StatefulWidget {
  final String businessId;
  final VoidCallback? onProductAdded;

  const AddProductScreen({
    super.key,
    required this.businessId,
    this.onProductAdded,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();

  bool _saving = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  // Pick multiple images (max 5)
  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked == null || picked.isEmpty) return;

      if (_images.length + picked.length > 5) {
        _showSnack("You can upload up to 5 images", isError: true);
        return;
      }

      setState(() {
        _images.addAll(picked);
      });
    } catch (e) {
      _showSnack("Image selection failed: $e", isError: true);
    }
  }

  void removeImageAt(int index) {
    setState(() => _images.removeAt(index));
  }

  void clearAllImages() {
    setState(() => _images.clear());
  }

  Future<List<String>> _uploadImages(String businessId) async {
    final List<String> urls = [];
    final storage = FirebaseStorage.instance;
    final uuid = const Uuid();

    // Reset progress
    _uploadProgress = 0;
    final total = _images.length;

    for (int i = 0; i < _images.length; i++) {
      final img = _images[i];
      try {
        final bytes = await img.readAsBytes();
        final id = uuid.v4();
        final ref = storage.ref().child('businesses/$businessId/products/$id.jpg');

        final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

        // listen progress
        final snapshot = await uploadTask.whenComplete(() {});
        // calculate progress (approx)
        _uploadProgress = (i + 1) / total;
        if (mounted) setState(() {});

        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        rethrow;
      }
    }

    // reset progress
    _uploadProgress = 0;
    if (mounted) setState(() {});
    return urls;
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnack("Please upload at least one image.", isError: true);
      return;
    }

    setState(() {
      _saving = true;
      _uploadProgress = 0;
    });

    try {
      final businessId = widget.businessId;
      final imageUrls = await _uploadImages(businessId);

      final productId = const Uuid().v4();

      final priceVal = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final stockVal = int.tryParse(_stockCtrl.text.trim()) ?? 0;

      final productData = {
        "id": productId,
        "name": _nameCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "price": priceVal,
        "stock": stockVal,
        "sku": _skuCtrl.text.trim(),
        "images": imageUrls,
        "sold": 0,
        "status": "Active",
        "createdAt": Timestamp.now(),
        "businessId": businessId,
      };

      await FirebaseFirestore.instance
          .collection("businesses")
          .doc(businessId)
          .collection("products")
          .doc(productId)
          .set(productData);

      if (mounted) {
        _showSnack("Product added successfully!", isError: false);
        _resetForm();

        // slight delay to improve UX before navigating/refreshing
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onProductAdded?.call();
        });
      }
    } catch (e) {
      _showSnack("Failed to add product: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _images.clear();
      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _skuCtrl.clear();
    });
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: pickImages,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 32, color: Colors.black54),
                SizedBox(height: 8),
                Text("Tap to upload images (max 5)"),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_images[i].path),
                      height: 110,
                      width: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      icon: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                      onPressed: () => removeImageAt(i),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text("${_images.length} image(s) selected", style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: clearAllImages,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text("Clear All"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text("Create a new product",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // Image area
                _buildImagePreview(),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: _saving ? null : pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_images.isEmpty ? "Upload Images" : "Add More Images"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Form fields
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Product name", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter product name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter description" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: "Price (INR)", border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Enter price";
                          if (double.tryParse(v.trim()) == null) return "Enter a valid number";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Stock", border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Enter stock";
                          if (int.tryParse(v.trim()) == null) return "Enter a valid integer";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: "SKU (optional)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 18),

                if (_saving)
                  Column(
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text("Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%"),
                      const SizedBox(height: 8),
                    ],
                  ),

                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text("Saving...", style: TextStyle(fontSize: 16)),
                      ],
                    )
                        : const Text("Save Product", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
