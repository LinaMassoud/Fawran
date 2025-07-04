// models/slider_item.dart
class SliderItem {
  final int sliderId;
  final String sliderType;
  final String description;
  final String? externalUrl;
  final String imageUrl;
  final String fileFormat;

  SliderItem({
    required this.sliderId,
    required this.sliderType,
    required this.description,
    required this.externalUrl,
    required this.imageUrl,
    required this.fileFormat,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      sliderId: json['sliderId'],
      sliderType: json['sliderType'],
      description: json['description'],
      externalUrl: json['externalUrl'],
      imageUrl: json['imageUrl'],
      fileFormat: json['fileFormat'],
    );
  }
}
