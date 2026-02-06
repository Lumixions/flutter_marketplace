import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import 'buyer_cart_screen.dart';
import 'buyer_catalog_screen.dart';
import 'buyer_orders_screen.dart';

class BuyerShell extends ConsumerStatefulWidget {
  const BuyerShell({super.key});

  @override
  ConsumerState<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends ConsumerState<BuyerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    final pages = const [
      BuyerCatalogScreen(),
      BuyerCartScreen(),
      BuyerOrdersScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          TextButton(
            onPressed: () => context.go('/seller'),
            child: const Text('Seller portal'),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}

