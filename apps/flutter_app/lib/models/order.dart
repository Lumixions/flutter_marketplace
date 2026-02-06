class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.unitPriceCents,
    required this.quantity,
    required this.lineTotalCents,
  });

  final int id;
  final int productId;
  final String title;
  final int unitPriceCents;
  final int quantity;
  final int lineTotalCents;

  static OrderItem fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      title: json['title'] as String,
      unitPriceCents: json['unit_price_cents'] as int,
      quantity: json['quantity'] as int,
      lineTotalCents: json['line_total_cents'] as int,
    );
  }
}

class Order {
  Order({
    required this.id,
    required this.status,
    required this.currency,
    required this.subtotalCents,
    required this.totalCents,
    required this.items,
  });

  final int id;
  final String status;
  final String currency;
  final int subtotalCents;
  final int totalCents;
  final List<OrderItem> items;

  static Order fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? const []);
    return Order(
      id: json['id'] as int,
      status: json['status'] as String,
      currency: json['currency'] as String,
      subtotalCents: json['subtotal_cents'] as int,
      totalCents: json['total_cents'] as int,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(growable: false),
    );
  }
}

