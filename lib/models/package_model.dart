class PackageModel {
  final int pricingId;
  final String groupCode;
  final int serviceId;
  final String serviceShift;
  final int duration;
  final int noOfMonth;
  final double hourPrice;
  final int visitsWeekly;
  final int noOfEmployee;
  final int packageId;
  final double visitPrice;
  final String packageName;
  final int vatPercentage;
  final double packagePrice;
  final double discountPercentage;
  final double priceAfterDiscount;
  final int vatAmount;
  final double finalPrice;

  PackageModel({
    required this.pricingId,
    required this.groupCode,
    required this.serviceId,
    required this.serviceShift,
    required this.duration,
    required this.noOfMonth,
    required this.hourPrice,
    required this.visitsWeekly,
    required this.noOfEmployee,
    required this.packageId,
    required this.visitPrice,
    required this.packageName,
    required this.vatPercentage,
    required this.packagePrice,
    required this.discountPercentage,
    required this.priceAfterDiscount,
    required this.vatAmount,
    required this.finalPrice,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      pricingId: json['pricing_id'] ?? 0,
      groupCode: json['group_code'] ?? '',
      serviceId: json['service_id'] ?? 0,
      serviceShift: json['service_shift']?.toString() ?? '1',
      duration: json['duration'] ?? 0,
      noOfMonth: json['no_of_month'] ?? 0,
      hourPrice: (json['hour_price'] ?? 0).toDouble(),
      visitsWeekly: json['visits_weekly'] ?? 0,
      noOfEmployee: json['no_of_employee'] ?? 0,
      packageId: json['package_id'] ?? 0,
      visitPrice: (json['visit_price'] ?? 0).toDouble(),
      packageName: json['package_name'] ?? '',
      vatPercentage: json['vat_percentage'] ?? 0,
      packagePrice: (json['package_price'] ?? 0).toDouble(),
      // Fixed: Handle null, empty, or invalid discount_percentage values
      discountPercentage: _parseDouble(json['discount_percentage']),
      priceAfterDiscount: (json['price_after_discount'] ?? 0).toDouble(),
      vatAmount: json['vat_amount'] ?? 0,
      finalPrice: (json['final_price'] ?? 0).toDouble(),
    );
  }

  // Helper method to safely parse double values that might be null or empty
  static double _parseDouble(dynamic value) {
    if (value == null || value == '') return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper methods to get display values
  String get nationalityDisplay {
    if (groupCode == '2') return 'East Asia';      // Fixed: group code 2 is East Asia
    if (groupCode == '3') return 'African';        // Fixed: group code 3 is African  
    if (groupCode == '1') return 'South Asia';     // group code 1 is South Asia
    return 'East Asia'; // default
  }

  String get timeDisplay {
    if (serviceShift == '1') return 'Morning';
    if (serviceShift == '2') return 'Evening';
    return 'Morning'; // default
  }

  String get durationDisplay {
    return '$duration hours';
  }
}