class ProductImage {
  ProductImage({
    required this.id,
    required this.s3Key,
    required this.sortOrder,
    this.url,
  });

  final int id;
  final String s3Key;
  final int sortOrder;
  final String? url;

  static ProductImage fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      s3Key: json['s3_key'] as String,
      sortOrder: json['sort_order'] as int,
      url: json['url'] as String?,
    );
  }
}

class Product {
  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.stockQty,
    required this.isActive,
    required this.images,
  });

  final int id;
  final int sellerId;
  final String title;
  final String? description;
  final int priceCents;
  final String currency;
  final int stockQty;
  final bool isActive;
  final List<ProductImage> images;

  static Product fromJson(Map<String, dynamic> json) {
    final imagesJson = (json['images'] as List<dynamic>? ?? const []);
    return Product(
      id: json['id'] as int,
      sellerId: json['seller_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: json['price_cents'] as int,
      currency: json['currency'] as String,
      stockQty: json['stock_qty'] as int,
      isActive: json['is_active'] as bool,
      images: imagesJson
          .whereType<Map<String, dynamic>>()
          .map(ProductImage.fromJson)
          .toList(),
    );
  }
}

