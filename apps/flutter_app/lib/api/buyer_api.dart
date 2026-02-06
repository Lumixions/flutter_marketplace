import '../api/api_client.dart';
import '../models/order.dart';
import '../models/product.dart';

class BuyerApi {
  BuyerApi(this._client);

  final ApiClient _client;

  Future<List<Product>> listProducts() async {
    final json = await _client.getJson('/products', bearerToken: null);
    final data = json['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<Order> createOrder({
    required String bearerToken,
    required List<CartLineItem> items,
    required ShippingAddress address,
  }) async {
    final json = await _client.postJson(
      '/orders',
      bearerToken: bearerToken,
      body: {
        'items': items
            .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
            .toList(),
        'shipping_address': address.toJson(),
      },
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return Order.fromJson(data);
  }

  Future<List<Order>> listOrders({required String bearerToken}) async {
    final json = await _client.getJson('/orders', bearerToken: bearerToken);
    final data = json['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<CheckoutInfo> checkoutOrder({
    required String bearerToken,
    required int orderId,
  }) async {
    final json = await _client.postJson(
      '/orders/$orderId/checkout',
      bearerToken: bearerToken,
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return CheckoutInfo(
      checkoutUrl: data['checkout_url'] as String,
      stripeSessionId: data['stripe_session_id'] as String,
    );
  }
}

class CartLineItem {
  CartLineItem({required this.productId, required this.quantity});

  final int productId;
  final int quantity;
}

class ShippingAddress {
  ShippingAddress({
    required this.fullName,
    required this.line1,
    this.line2,
    required this.city,
    this.state,
    required this.postalCode,
    this.country = 'US',
    this.phone,
  });

  final String fullName;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String postalCode;
  final String country;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
      };
}

class CheckoutInfo {
  CheckoutInfo({required this.checkoutUrl, required this.stripeSessionId});

  final String checkoutUrl;
  final String stripeSessionId;
}

