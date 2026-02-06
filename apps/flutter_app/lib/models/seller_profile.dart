class SellerProfile {
  SellerProfile({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.status,
  });

  final int id;
  final int userId;
  final String storeName;
  final String status;

  static SellerProfile fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      storeName: json['store_name'] as String,
      status: json['status'] as String,
    );
  }
}

