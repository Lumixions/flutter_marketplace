import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class CartState {
  const CartState({required this.items});

  final List<CartItem> items;

  int get subtotalCents =>
      items.fold(0, (sum, i) => sum + i.product.priceCents * i.quantity);
}

class CartController extends StateNotifier<CartState> {
  CartController() : super(const CartState(items: []));

  void add(Product product) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = [...state.items];
      final existing = updated[existingIndex];
      updated[existingIndex] = CartItem(product: existing.product, quantity: existing.quantity + 1);
      state = CartState(items: updated);
      return;
    }
    state = CartState(items: [...state.items, CartItem(product: product, quantity: 1)]);
  }

  void remove(Product product) {
    state = CartState(items: state.items.where((i) => i.product.id != product.id).toList());
  }

  void setQty(Product product, int qty) {
    if (qty <= 0) {
      remove(product);
      return;
    }
    final updated = [...state.items];
    final idx = updated.indexWhere((i) => i.product.id == product.id);
    if (idx < 0) return;
    updated[idx] = CartItem(product: product, quantity: qty);
    state = CartState(items: updated);
  }

  void clear() {
    state = const CartState(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController();
});

