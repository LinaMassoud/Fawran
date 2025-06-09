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