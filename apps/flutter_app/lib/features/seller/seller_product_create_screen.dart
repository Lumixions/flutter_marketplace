import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../api/seller_api.dart';
import '../../auth/auth_controller.dart';

class SellerProductCreateScreen extends ConsumerStatefulWidget {
  const SellerProductCreateScreen({super.key});

  @override
  ConsumerState<SellerProductCreateScreen> createState() => _SellerProductCreateScreenState();
}

class _SellerProductCreateScreenState extends ConsumerState<SellerProductCreateScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  bool _active = true;

  XFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  String _contentTypeForFilename(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    final sellerApi = SellerApi(ApiClient());

    return Scaffold(
      appBar: AppBar(
        title: const Text('New product'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/seller?tab=products'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (USD)',
                        hintText: 'e.g. 19.99',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock qty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Main image (optional)'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.gallery);
                          if (picked == null) return;
                          setState(() => _image = picked);
                        },
                        icon: const Icon(Icons.image),
                        label: Text(_image == null ? 'Choose image' : _image!.name),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          final token = await auth.getIdToken();
                          if (token == null) throw Exception('Not signed in');

                          final dollars = double.parse(_price.text.trim());
                          final priceCents = (dollars * 100).round();
                          final stockQty = int.tryParse(_stock.text.trim()) ?? 0;

                          final created = await sellerApi.createProduct(
                            bearerToken: token,
                            title: _title.text.trim(),
                            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                            priceCents: priceCents,
                            currency: 'USD',
                            stockQty: stockQty,
                            isActive: _active,
                          );

                          if (_image != null) {
                            final contentType = _contentTypeForFilename(_image!.name);
                            final presign = await sellerApi.presignProductImageUpload(
                              bearerToken: token,
                              productId: created.id,
                              filename: _image!.name,
                              contentType: contentType,
                            );

                            final Uint8List bytes = await _image!.readAsBytes();
                            await sellerApi.uploadToPresignedUrl(
                              uploadUrl: presign.uploadUrl,
                              bytes: bytes,
                              contentType: contentType,
                            );

                            await sellerApi.attachProductImages(
                              bearerToken: token,
                              productId: created.id,
                              s3Keys: [presign.s3Key],
                            );
                          }

                          if (!context.mounted) return;
                          context.go('/seller?tab=products');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(_saving ? 'Saving...' : 'Create product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

