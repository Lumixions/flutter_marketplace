import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../api/seller_api.dart';
import '../../auth/auth_controller.dart';
import '../../models/product.dart';

class SellerShell extends ConsumerStatefulWidget {
  const SellerShell({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends ConsumerState<SellerShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = switch (widget.initialTab) {
      'products' => 1,
      'orders' => 2,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    final sellerApi = SellerApi(ApiClient());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_index) {
            1 => 'Products',
            2 => 'Orders',
            _ => 'Seller',
          },
        ),
        leading: IconButton(
          tooltip: 'Back to buyer',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder(
        future: auth.getIdToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final token = snapshot.data;
          if (token == null) return const Center(child: Text('Not signed in.'));

          return FutureBuilder(
            future: sellerApi.getProfile(bearerToken: token),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData && profileSnap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = profileSnap.data;
              final needsProfile = profile == null;

              if (_index == 1) {
                if (needsProfile) return _SellerNeedsProfile();
                return _SellerProductsTab(token: token);
              }
              if (_index == 2) {
                if (needsProfile) return _SellerNeedsProfile();
                return const _SellerOrdersTab();
              }

              // Home
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(
                      needsProfile ? 'Create your seller profile' : 'Welcome, ${profile.storeName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    if (needsProfile) _CreateSellerProfileCard(token: token),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Quick actions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: needsProfile ? null : () => setState(() => _index = 1),
                              child: const Text('Manage products'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: needsProfile ? null : () => setState(() => _index = 2),
                              child: const Text('View orders'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/seller/products/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}

class _SellerNeedsProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Create a seller profile first (Home tab).'),
      ),
    );
  }
}

class _SellerProductsTab extends ConsumerStatefulWidget {
  const _SellerProductsTab({required this.token});

  final String token;

  @override
  ConsumerState<_SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends ConsumerState<_SellerProductsTab> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() async {
    return SellerApi(ApiClient()).listMyProducts(bearerToken: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No products yet.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: ListView.separated(
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
          ),
        );
      },
    );
  }
}

class _SellerOrdersTab extends StatelessWidget {
  const _SellerOrdersTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Seller orders UI will be expanded next.'),
      ),
    );
  }
}

class _CreateSellerProfileCard extends ConsumerStatefulWidget {
  const _CreateSellerProfileCard({required this.token});

  final String token;

  @override
  ConsumerState<_CreateSellerProfileCard> createState() => _CreateSellerProfileCardState();
}

class _CreateSellerProfileCardState extends ConsumerState<_CreateSellerProfileCard> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellerApi = SellerApi(ApiClient());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Store name'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Acme Store',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await sellerApi.upsertProfile(
                          bearerToken: widget.token,
                          storeName: _controller.text.trim(),
                        );
                        if (!context.mounted) return;
                        context.go('/seller');
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Failed: $e')));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Saving...' : 'Create profile'),
            ),
          ],
        ),
      ),
    );
  }
}

