class AddressModel {
  final String id;
  final String name;
  final String fullAddress;
  final bool isSelected;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.isSelected,
  });

  AddressModel copyWith({
    String? id,
    String? name,
    String? fullAddress,
    bool? isSelected,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}


class Address {
  final String cardText;
  final int addressId;
  final String cityCode;
  final String districtCode;

  Address({
    required this.cardText,
    required this.addressId,
    required this.cityCode,
    required this.districtCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      cardText: json['card_text'] as String,
      addressId: json['address_id'] as int,
      cityCode: json['city_code'] as String,
      districtCode: json['district_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_text': cardText,
      'address_id': addressId,
      'city_code': cityCode,
      'district_code': districtCode,
    };
  }
}
