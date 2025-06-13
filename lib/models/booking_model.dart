class BookingData {
  final List<DateTime> selectedDates;
  final double totalPrice;
  final double originalPrice; // Changed from discountPrice to originalPrice
  final String selectedAddress;
  final int workerCount;
  final String contractDuration;
  final String visitsPerWeek;
  final String selectedNationality;
  final String packageName;

  BookingData({
    required this.selectedDates,
    required this.totalPrice,
    required this.originalPrice, // Changed parameter name
    required this.selectedAddress,
    required this.workerCount,
    required this.contractDuration,
    required this.visitsPerWeek,
    required this.selectedNationality,
    required this.packageName,
  });
  
  // Helper method to get the discount amount
  double get discountAmount => originalPrice - totalPrice;
  
  // Helper method to check if there's a discount applied
  bool get hasDiscount => discountAmount > 0;
  
  // Helper method to get discount percentage (if needed)
  double get discountPercentage => originalPrice > 0 ? (discountAmount / originalPrice) * 100 : 0;
}