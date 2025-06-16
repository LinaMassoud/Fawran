class BookingData {
  final List<DateTime> selectedDates;
  final double totalPrice;
  final String selectedAddress;
  final int workerCount;
  final String contractDuration;
  final String visitsPerWeek;
  final String selectedNationality; // Add this field
  final String packageName; // Add this field

  BookingData({
    required this.selectedDates,
    required this.totalPrice,
    required this.selectedAddress,
    required this.workerCount,
    required this.contractDuration,
    required this.visitsPerWeek,
    required this.selectedNationality, // Add this parameter
    required this.packageName, // Add this parameter
  });
}