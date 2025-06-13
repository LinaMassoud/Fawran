class PackageModel {
  final int packageId;
  final String packageName;
  final String packageType;
  final double packagePriceWithVat;
  final int contractDays;
  final double contractAmount;

  PackageModel({
    required this.packageId,
    required this.packageName,
    required this.packageType,
    required this.packagePriceWithVat,
    required this.contractDays,
    required this.contractAmount,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: json['package_domestic_id'],
      packageName: json['package_name'],
      packageType: json['package_type'],
      packagePriceWithVat: json['package_price_with_vat']?.toDouble() ?? 0.0,
      contractDays: json['contract_days'],
      contractAmount: json['contract_amount']?.toDouble() ?? 0.0,
    );
  }
}
