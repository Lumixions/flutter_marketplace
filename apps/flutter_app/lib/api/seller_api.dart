import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../models/product.dart';
import '../models/seller_profile.dart';

class SellerApi {
  SellerApi(this._client);

  final ApiClient _client;

  Future<SellerProfile?> getProfile({required String bearerToken}) async {
    final json = await _client.getJson('/seller/profile', bearerToken: bearerToken);
    // Backend returns `null` if none.
    final data = (json['data'] ?? json);
    if (data == null) return null;
    if (data is Map<String, dynamic>) return SellerProfile.fromJson(data);
    return null;
  }

  Future<SellerProfile> upsertProfile({
    required String bearerToken,
    required String storeName,
  }) async {
    final json = await _client.postJson(
      '/seller/profile',
      bearerToken: bearerToken,
      body: {'store_name': storeName},
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return SellerProfile.fromJson(data);
  }

  Future<List<Product>> listMyProducts({required String bearerToken}) async {
    final json = await _client.getJson('/seller/products', bearerToken: bearerToken);
    final data = json['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  Future<Product> createProduct({
    required String bearerToken,
    required String title,
    required String? description,
    required int priceCents,
    required String currency,
    required int stockQty,
    required bool isActive,
  }) async {
    final json = await _client.postJson(
      '/seller/products',
      bearerToken: bearerToken,
      body: {
        'title': title,
        'description': description,
        'price_cents': priceCents,
        'currency': currency,
        'stock_qty': stockQty,
        'is_active': isActive,
      },
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return Product.fromJson(data);
  }

  Future<PresignResult> presignProductImageUpload({
    required String bearerToken,
    required int productId,
    required String filename,
    required String contentType,
  }) async {
    final json = await _client.postJson(
      '/seller/products/$productId/images/presign',
      bearerToken: bearerToken,
      body: {'filename': filename, 'content_type': contentType},
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return PresignResult(
      s3Key: data['s3_key'] as String,
      uploadUrl: data['upload_url'] as String,
      publicUrl: data['public_url'] as String?,
    );
  }

  Future<Product> attachProductImages({
    required String bearerToken,
    required int productId,
    required List<String> s3Keys,
  }) async {
    final json = await _client.postJson(
      '/seller/products/$productId/images/attach',
      bearerToken: bearerToken,
      body: {'s3_keys': s3Keys},
    );
    final data = (json['data'] as Map<String, dynamic>? ?? json);
    return Product.fromJson(data);
  }

  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final resp = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('S3 upload failed: ${resp.statusCode} ${resp.body}');
    }
  }
}

class PresignResult {
  PresignResult({required this.s3Key, required this.uploadUrl, this.publicUrl});

  final String s3Key;
  final String uploadUrl;
  final String? publicUrl;
}

