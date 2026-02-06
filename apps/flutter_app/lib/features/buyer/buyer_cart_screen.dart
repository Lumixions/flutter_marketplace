import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/buyer_api.dart';
import '../../auth/auth_controller.dart';
import 'cart_state.dart';

class BuyerCartScreen extends ConsumerStatefulWidget {
  const BuyerCartScreen({super.key});

  @override
  ConsumerState<BuyerCartScreen> createState() => _BuyerCartScreenState();
}

class _BuyerCartScreenState extends ConsumerState<BuyerCartScreen> {
  final _name = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _name.dispose();
    _line1.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = (cart.subtotalCents / 100).toStringAsFixed(2);

    if (cart.items.isEmpty) {
      return const Center(child: Text('Your cart is empty.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cart.items.map(
          (i) => Card(
            child: ListTile(
              title: Text(i.product.title),
              subtitle: Text('Qty ${i.quantity}'),
              trailing: IconButton(
                tooltip: 'Remove',
                onPressed: () => ref.read(cartProvider.notifier).remove(i.product),
                icon: const Icon(Icons.delete),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Subtotal: $total USD', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Shipping (MVP)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _line1,
                  decoration: const InputDecoration(
                    labelText: 'Address line 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _city,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _postal,
                        decoration: const InputDecoration(
                          labelText: 'Postal code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _placing
                      ? null
                      : () async {
                          setState(() => _placing = true);
                          try {
                            final token = await ref.read(authControllerProvider).getIdToken();
                            if (token == null) throw Exception('Not signed in');

                            final api = BuyerApi(ApiClient());
                            final order = await api.createOrder(
                              bearerToken: token,
                              items: cart.items
                                  .map(
                                    (i) => CartLineItem(
                                      productId: i.product.id,
                                      quantity: i.quantity,
                                    ),
                                  )
                                  .toList(),
                              address: ShippingAddress(
                                fullName: _name.text.trim(),
                                line1: _line1.text.trim(),
                                city: _city.text.trim(),
                                postalCode: _postal.text.trim(),
                              ),
                            );

                            final checkout = await api.checkoutOrder(
                              bearerToken: token,
                              orderId: order.id,
                            );

                            ref.read(cartProvider.notifier).clear();
                            if (!context.mounted) return;
                            final uri = Uri.parse(checkout.checkoutUrl);
                            final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Open this URL to pay: ${checkout.checkoutUrl}')),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Failed: $e')));
                          } finally {
                            if (mounted) setState(() => _placing = false);
                          }
                        },
                  child: Text(_placing ? 'Starting checkout...' : 'Checkout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

