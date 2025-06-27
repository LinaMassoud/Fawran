class PackageModel {
  final int packageId;
  final String packageName;
  final String packageType;
  final double vatAmount;
  final int contractDays;
  final double contractAmount;
  final double finalInvoice;

  PackageModel({
    required this.packageId,
    required this.packageName,
    required this.packageType,
    required this.vatAmount,
    required this.contractDays,
    required this.contractAmount,
    required this.finalInvoice,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: json['package_domestic_id'],
      packageName: json['package_name'],
      packageType: json['package_type'],
      vatAmount: json['vat_amount']?.toDouble() ?? 0.0,
      contractDays: json['contract_days'],
      contractAmount: json['final_price_before_vat']?.toDouble() ?? 0.0,
      finalInvoice: json['financial_invoice_amount']?.toDouble() ?? 0.0 
    );
  }
}
