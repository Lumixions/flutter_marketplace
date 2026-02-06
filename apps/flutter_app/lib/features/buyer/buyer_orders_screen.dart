import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/buyer_api.dart';
import '../../auth/auth_controller.dart';
import '../../models/order.dart';

class BuyerOrdersScreen extends ConsumerStatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  ConsumerState<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends ConsumerState<BuyerOrdersScreen> {
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() async {
    final token = await ref.read(authControllerProvider).getIdToken();
    if (token == null) return [];
    return BuyerApi(ApiClient()).listOrders(bearerToken: token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? const [];
        if (orders.isEmpty) return const Center(child: Text('No orders yet.'));

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final o = orders[i];
              final total = (o.totalCents / 100).toStringAsFixed(2);
              final payable = o.status == 'PENDING_PAYMENT';
              return Card(
                child: ListTile(
                  title: Text('Order #${o.id}'),
                  subtitle: Text('${o.status} • $total ${o.currency}'),
                  trailing: payable
                      ? TextButton(
                          onPressed: () async {
                            try {
                              final token = await ref.read(authControllerProvider).getIdToken();
                              if (token == null) throw Exception('Not signed in');
                              final checkout = await BuyerApi(ApiClient()).checkoutOrder(
                                bearerToken: token,
                                orderId: o.id,
                              );
                              await launchUrl(
                                Uri.parse(checkout.checkoutUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          },
                          child: const Text('Pay'),
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

