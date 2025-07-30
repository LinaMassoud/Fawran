class PromotionModel {
  final String promotionCode;
  final int discount;
  final String? imageUrl;

  PromotionModel({
    required this.promotionCode,
    required this.discount,
    this.imageUrl,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      promotionCode: json['promotion_code'] ?? '',
      discount: json['discount'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}