import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../api/seller_api.dart';
import '../../auth/auth_controller.dart';
import '../../models/product.dart';

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() async {
    final token = await ref.read(authControllerProvider).getIdToken();
    if (token == null) return [];
    final api = SellerApi(ApiClient());
    return api.listMyProducts(bearerToken: token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My products'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/seller'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/seller/products/new'),
        label: const Text('Add product'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = items[i];
              final price = (p.priceCents / 100).toStringAsFixed(2);
              return Card(
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text('$price ${p.currency} • stock ${p.stockQty}'),
                  trailing: Icon(p.isActive ? Icons.visibility : Icons.visibility_off),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

