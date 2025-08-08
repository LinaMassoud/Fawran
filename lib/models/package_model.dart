import '../services/api_service.dart';
class PackageModel {
  final String groupCode;
  final String serviceShift;
  final String duration; // Changed to String to match JSON
  final int noOfMonth;
  final double hourPrice;
  final int visitsWeekly;
  final int noOfEmployee;
  final int packageId;
  final double visitPrice;
  final String packageName;
  final int vatPercentage;
  final double originalPrice; // Added original_price field
  final double packagePrice;
  final double? discountPercentage; // Made nullable as it can be null in JSON
  final double priceAfterDiscount;
  final double vatAmount; // Changed to double to match JSON
  final double finalPrice;
  final int? noOfWeeks; // Added missing field, nullable
  final int? promotionId; // Add this field
final String? promotionCode; // Add this field

  static Map<String, List<dynamic>> _countryGroupsCache = {};
  static Map<String, String> _groupCodeToNameCache = {};

  PackageModel({
    required this.groupCode,
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
    required this.originalPrice, // Added to constructor
    required this.packagePrice,
    this.discountPercentage,
    required this.priceAfterDiscount,
    required this.vatAmount,
    required this.finalPrice,
    this.noOfWeeks,
    this.promotionId,
  this.promotionCode,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: _parseInt(json['package_id']),
      packageName: json['package_name']?.toString() ?? '',
      originalPrice: _parseDouble(json['original_price']), // Added original_price parsing
      packagePrice: _parseDouble(json['package_price']),
      visitPrice: _parseDouble(json['visit_price']),
      noOfEmployee: _parseInt(json['no_of_employee']),
      visitsWeekly: _parseInt(json['visits_weekly']),
      discountPercentage: json['discount_percentage'] != null ? _parseDouble(json['discount_percentage']) : null,
      priceAfterDiscount: _parseDouble(json['price_after_discount']),
      vatPercentage: _parseInt(json['vat_percentage']),
      vatAmount: _parseDouble(json['vat_amount']),
      finalPrice: _parseDouble(json['final_price']),
      duration: json['duration']?.toString() ?? '4',
      serviceShift: json['service_shift']?.toString() ?? '1',
      groupCode: json['group_code']?.toString() ?? '2',
      noOfWeeks: json['no_of_weeks'] != null ? _parseInt(json['no_of_weeks']) : null,
      noOfMonth: _parseInt(json['no_of_month']),
      // Get hour_price directly from JSON instead of calculating
      hourPrice: _parseDouble(json['hour_price']),
      promotionId: json['promotion_id'] != null ? _parseInt(json['promotion_id']) : null,
    promotionCode: json['promotion_code']?.toString(),
      // Default values for fields not present in JSON but required by constructor
 // Set appropriate default or get from another source  
    );
  }

  // Helper method to safely parse integer values that might be null, empty, or strings
  static int _parseInt(dynamic value) {
    if (value == null || value == '') return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        // If it's a decimal string, parse as double then convert to int
        try {
          return double.parse(value).toInt();
        } catch (e) {
          return 0;
        }
      }
    }
    return 0;
  }

  // Helper method to safely parse double values that might be null, empty, or strings
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

  static Future<void> preloadCountryGroups({required int serviceId}) async {
    try {
      final cacheKey = serviceId.toString();
      if (_countryGroupsCache.containsKey(cacheKey)) {
        return; // Already cached
      }

      final countryGroups = await ApiService.fetchCountryGroups(serviceId: serviceId);
      _countryGroupsCache[cacheKey] = countryGroups;

      // Build the group code to name mapping
      for (var group in countryGroups) {
        final groupCode = group['group_code']?.toString();
        final groupName = group['group_name']?.toString() ?? group['name']?.toString();
        
        if (groupCode != null && groupName != null) {
          _groupCodeToNameCache[groupCode] = groupName;
        }
      }
    } catch (e) {
      print('Error preloading country groups: $e');
      // Continue with fallback values if API fails
    }
  }

  // Async method to get nationality display from API
  Future<String> getNationalityDisplay({required int serviceId}) async {
    try {
      // Check if we have cached data for this service
      final cacheKey = serviceId.toString();
      if (!_countryGroupsCache.containsKey(cacheKey)) {
        await preloadCountryGroups(serviceId: serviceId);
      }

      // Try to get from cache first
      final cachedName = _groupCodeToNameCache[groupCode];
      if (cachedName != null) {
        return cachedName;
      }

      // If not in cache, fetch fresh data
      final countryGroups = await ApiService.fetchCountryGroups(serviceId: serviceId);
      
      for (var group in countryGroups) {
        final code = group['group_code']?.toString();
        if (code == groupCode) {
          final name = group['group_name']?.toString() ?? 
                      group['name']?.toString() ?? 
                      'Unknown';
          
          // Cache for future use
          _groupCodeToNameCache[groupCode] = name;
          return name;
        }
      }

      // Fallback if not found
      return _getFallbackNationalityDisplay();
    } catch (e) {
      print('Error fetching nationality display: $e');
      return _getFallbackNationalityDisplay();
    }
  }

  // Synchronous fallback method (original hardcoded logic)
  String _getFallbackNationalityDisplay() {
    if (groupCode == '2') return 'East Asia';      
    if (groupCode == '3') return 'African';        
    if (groupCode == '9') return 'South Asia';     
    return 'East Asia'; // default
  }

  // Synchronous getter for backward compatibility (uses cached data)
  String get nationalityDisplay {
    return _groupCodeToNameCache[groupCode] ?? _getFallbackNationalityDisplay();
  }

  String get timeDisplay {
    if (serviceShift == '1') return 'Morning';
    if (serviceShift == '2') return 'Evening';
    return 'Morning'; // default
  }

  String get durationDisplay {
    return '$duration hours';
  }

  // Additional helper method to get discount display
  String get discountDisplay {
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    return '';
  }

  // Helper method to check if package has discount
  bool get hasDiscount {
    return discountPercentage != null && discountPercentage! > 0;
  }

  // Helper method to get formatted price strings
  String get formattedFinalPrice {
    return 'SAR ${finalPrice.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice { // Added formatted original price
    return 'SAR ${originalPrice.toStringAsFixed(2)}';
  }

  String get formattedPackagePrice {
    return 'SAR ${packagePrice.toStringAsFixed(2)}';
  }

  String get formattedVisitPrice {
    return 'SAR ${visitPrice.toStringAsFixed(2)}';
  }

  // Helper method to get formatted hour price
  String get formattedHourPrice {
    return 'SAR ${hourPrice.toStringAsFixed(2)}';
  }

  // Convert back to JSON (useful for API calls)
  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'package_name': packageName,
      'original_price': originalPrice, // Added to JSON serialization
      'package_price': packagePrice,
      'visit_price': visitPrice,
      'no_of_employee': noOfEmployee,
      'visits_weekly': visitsWeekly,
      'discount_percentage': discountPercentage,
      'price_after_discount': priceAfterDiscount,
      'vat_percentage': vatPercentage,
      'vat_amount': vatAmount,
      'final_price': finalPrice,
      'duration': duration,
      'service_shift': serviceShift,
      'group_code': groupCode,
      'no_of_weeks': noOfWeeks,
      'no_of_month': noOfMonth,
      'hour_price': hourPrice,
      'promotion_id': promotionId,
    'promotion_code': promotionCode,
    };
  }

  // Create a copy with modified values
  PackageModel copyWith({
    int? pricingId,
    String? groupCode,
    int? serviceId,
    String? serviceShift,
    String? duration,
    int? noOfMonth,
    double? hourPrice,
    int? visitsWeekly,
    int? noOfEmployee,
    int? packageId,
    double? visitPrice,
    String? packageName,
    int? vatPercentage,
    double? originalPrice, // Added to copyWith method
    double? packagePrice,
    double? discountPercentage,
    double? priceAfterDiscount,
    double? vatAmount,
    double? finalPrice,
    int? noOfWeeks,
    int? promotionId,
  String? promotionCode,
  }) {
    return PackageModel(
      groupCode: groupCode ?? this.groupCode,
      serviceShift: serviceShift ?? this.serviceShift,
      duration: duration ?? this.duration,
      noOfMonth: noOfMonth ?? this.noOfMonth,
      hourPrice: hourPrice ?? this.hourPrice,
      visitsWeekly: visitsWeekly ?? this.visitsWeekly,
      noOfEmployee: noOfEmployee ?? this.noOfEmployee,
      packageId: packageId ?? this.packageId,
      visitPrice: visitPrice ?? this.visitPrice,
      packageName: packageName ?? this.packageName,
      vatPercentage: vatPercentage ?? this.vatPercentage,
      originalPrice: originalPrice ?? this.originalPrice, // Added to copyWith implementation
      packagePrice: packagePrice ?? this.packagePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      priceAfterDiscount: priceAfterDiscount ?? this.priceAfterDiscount,
      vatAmount: vatAmount ?? this.vatAmount,
      finalPrice: finalPrice ?? this.finalPrice,
      noOfWeeks: noOfWeeks ?? this.noOfWeeks,
      promotionId: promotionId ?? this.promotionId,
    promotionCode: promotionCode ?? this.promotionCode,
    );
  }

  @override
  String toString() {
    return 'PackageModel(packageId: $packageId, packageName: $packageName, originalPrice: $originalPrice, finalPrice: $finalPrice, hourPrice: $hourPrice, duration: $duration, visitsWeekly: $visitsWeekly)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PackageModel && other.packageId == packageId;
  }

  @override
  int get hashCode => packageId.hashCode;
}