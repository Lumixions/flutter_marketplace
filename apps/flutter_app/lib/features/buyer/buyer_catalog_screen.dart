import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/buyer_api.dart';
import '../../models/product.dart';
import 'cart_state.dart';

class BuyerCatalogScreen extends ConsumerStatefulWidget {
  const BuyerCatalogScreen({super.key});

  @override
  ConsumerState<BuyerCatalogScreen> createState() => _BuyerCatalogScreenState();
}

class _BuyerCatalogScreenState extends ConsumerState<BuyerCatalogScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = BuyerApi(ApiClient()).listProducts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return const Center(child: Text('No products yet.'));

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = BuyerApi(ApiClient()).listProducts());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = items[i];
              final price = (p.priceCents / 100).toStringAsFixed(2);
              final imageUrl = p.images.isNotEmpty ? p.images.first.url : null;
              return Card(
                child: ListTile(
                  leading: imageUrl == null
                      ? const SizedBox(width: 56, height: 56)
                      : Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                  title: Text(p.title),
                  subtitle: Text('$price ${p.currency}'),
                  trailing: FilledButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).add(p);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Added to cart')));
                    },
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

