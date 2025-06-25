import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your existing screens
import 'cleaning_service_screen.dart'; // PackageModel
import 'add_new_address.dart';

import '../services/api_service.dart';
// Import modularized components
import '../models/address_model.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../steps/address_selection_step.dart';
import '../steps/service_details_step.dart';
import '../steps/date_selection_step.dart';
import '../widgets/booking_step_header.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';

class ContinuousBookingOverlay extends ConsumerStatefulWidget {
  final PackageModel? package; // Made optional
  final int? selectedShift; // Made optional
  final int serviceId;
  final int professionId;
  final Function(BookingData)? onBookingCompleted;
  final bool isCustomBooking; // New parameter to indicate custom booking

  const ContinuousBookingOverlay({
    Key? key,
    this.package, // Optional
    this.selectedShift, // Optional
    required this.serviceId,
    required this.professionId,
    this.onBookingCompleted,
    this.isCustomBooking = false, // Default to false for backward compatibility
  }) : super(key: key);

  @override
  ConsumerState<ContinuousBookingOverlay> createState() =>
      _ContinuousBookingOverlayState();

  // Static method to show as overlay with package (existing functionality)
  static void showAsOverlay(
    BuildContext context, {
    required PackageModel package,
    required int selectedShift,
    required int serviceId,
    required int professionId,
    Function(BookingData)? onBookingCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => ContinuousBookingOverlay(
        package: package,
        selectedShift: selectedShift,
        professionId: professionId,
        serviceId: serviceId,
        onBookingCompleted: onBookingCompleted,
        isCustomBooking: false,
      ),
    );
  }

  // New static method for custom booking without package
  static void showAsCustomOverlay(
    BuildContext context, {
    required int serviceId,
    required int professionId,
    Function(BookingData)? onBookingCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => ContinuousBookingOverlay(
        serviceId: serviceId,
        professionId: professionId,
        onBookingCompleted: onBookingCompleted,
        isCustomBooking: true,
      ),
    );
  }
}

class _ContinuousBookingOverlayState
    extends ConsumerState<ContinuousBookingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late PageController _pageController;

  int currentStep = 0;
  // Modified: Dynamic total steps based on booking type
  int get totalSteps =>
      2; // Custom: Address, Service Details, Date Selection | Package: Address, Date Selection

  // Track if we're returning from date selection
  bool isReturningFromDateSelection = false;

  // Address Selection Data
  List<Address> addresses = [];
  bool isLoadingAddresses = true;
  String? addressError;
  List<String> selectedDays = [];

  // Service Details Data (with defaults for custom booking)
  String selectedNationality = 'East Asia';
  late int workerCount;
  late String contractDuration;
  String selectedTime = 'Morning';
  late String visitDuration;
  late String visitsPerWeek;
  late double hourPrice; // New field for custom booking

  double? _totalPriceFromServiceDetails;
  // Date Selection Data
  List<DateTime> selectedDates = [];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Initialize service details values based on whether it's custom or package booking
    if (widget.isCustomBooking) {
      // Default values for custom booking - set to null/empty for placeholders
      workerCount = 1; // Keep this as it's handled by number selection
      contractDuration = ''; // Empty string for placeholder
      visitDuration = ''; // Empty string for placeholder
      visitsPerWeek = ''; // Empty string for placeholder
      selectedNationality = ''; // Empty string for placeholder
      selectedTime = ''; // Empty string for placeholder
      hourPrice = 32.0; // Default hourly rate
    } else {
      // Initialize from package (existing functionality)
      workerCount = widget.package!.noOfEmployee;
      contractDuration =
          '${widget.package!.noOfMonth} month${widget.package!.noOfMonth > 1 ? 's' : ''}';
      visitDuration = '${widget.package!.duration} hours';
      visitsPerWeek =
          '${widget.package!.visitsWeekly} visit${widget.package!.visitsWeekly > 1 ? 's' : ''} weekly';
      selectedNationality = widget.package!.nationalityDisplay;
      selectedTime = _getTimeFromShift(widget.selectedShift.toString());
      hourPrice = widget.package!.hourPrice;
    }

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Fetch addresses from API
    _fetchAddresses();
  }

  // Fetch addresses from API
  Future<void> _fetchAddresses() async {
    try {
      setState(() {
        isLoadingAddresses = true;
        addressError = null;
      });

      // Get userId from the provider
      final userId = ref.read(userIdProvider);

      print('userId in _fetchAddresses =');

      // Check if userId is available
      if (userId == null) {
        setState(() {
          addressError = 'User not authenticated. Please log in again.';
          isLoadingAddresses = false;
        });
        return;
      }

      // Use the API service method
      final data = await ApiService.fetchCustomerAddresses(userId: userId);

      setState(() {
        addresses = data.map((addressData) {
          return Address(
            cardText: addressData['card_text']?.toString() ?? 'Address',
            addressId: addressData['address_id'] ?? 0,
            cityCode: int.parse(addressData['city_code']),
            districtCode: addressData['district_code']?.toString() ?? '',
          );
        }).toList();

        if (addresses.isNotEmpty && ref.read(selectedAddressProvider) == null) {
          ref.read(selectedAddressProvider.notifier).state = addresses.first;
        }

        isLoadingAddresses = false;
      });
    } catch (e) {
      setState(() {
        addressError = 'Error loading addresses: $e';
        isLoadingAddresses = false;
      });
    }
  }

  String _extractLocationName(String? cardText) {
    if (cardText == null || cardText.isEmpty) {
      return 'Address';
    }

    try {
      List<String> parts = cardText.split('-');

      if (parts.length >= 2) {
        String city = parts[0].trim();
        String area = parts[1].trim();

        if (area.isEmpty) {
          return city.isNotEmpty ? city : 'Address';
        }

        return '$area, $city';
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].trim();
      }
    } catch (e) {
      print('Error parsing address: $e');
    }

    return 'Address';
  }

  String _getTimeFromShift(String shift) {
    switch (shift) {
      case '1':
        return 'Morning';
      case '2':
        return 'Evening';
      default:
        return 'Morning';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _closeOverlay() async {
    await _animationController.reverse();
    Navigator.pop(context);
  }

  void _updateSelectedDays(List<String> newSelectedDays) {
    setState(() {
      selectedDays = newSelectedDays;
    });
  }

  // Modified: Handle step navigation based on booking type
  void _nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
      });

      // Use the correct page index for navigation
      int targetPageIndex = _getPageIndex();

      _pageController.animateToPage(
        targetPageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        if (widget.isCustomBooking &&
            currentStep == 1 &&
            selectedDates.isNotEmpty) {
          isReturningFromDateSelection = true;
        }
      });

      // Use the correct page index for navigation
      int targetPageIndex = _getPageIndex();

      _pageController.animateToPage(
        targetPageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper method to get the correct page index for PageView
  int _getPageIndex() {
    // Both custom and package booking now have same structure: [Address(0), ServiceDetails/DateSelection(1)]
    return currentStep;
  }

  void _selectAddress(int addressId) {
    final selectedAddress = addresses.firstWhere(
      (address) => address.addressId == addressId,
      orElse: () => addresses.first,
    );
    ref.read(selectedAddressProvider.notifier).state = selectedAddress;
  }

  void _addNewAddress() async {
    final userId = ref.read(userIdProvider);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewAddressScreen(
          package: widget.package,
          serviceId: widget.serviceId,
          user_id: userId,
        ),
      ),
    );
    final add = result["newAddress"];
    final displayAdd = result["displayAddress"];

    if (add != null && add is Map<String, dynamic>) {
      final newAddress = Address(
        cardText:
            '${displayAdd['city'] ?? ''}- ${displayAdd['district'].districtName ?? ''}-${add['fullAddress']} ',
        addressId: DateTime.now().millisecondsSinceEpoch,
        cityCode: add['city'],
        districtCode: add['districtCode'] ?? '',
      );

      setState(() {
        addresses.add(newAddress);
      });

      ref.read(selectedAddressProvider.notifier).state = newAddress;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // New methods for updating service details in custom booking
  void _updateNationality(String newNationality) {
    setState(() {
      selectedNationality = newNationality;
    });
    // Price doesn't directly depend on nationality, but trigger update for consistency
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateTime(String newTime) {
    setState(() {
      selectedTime = newTime;
    });
    // Price doesn't directly depend on time slot, but trigger update for consistency
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateVisitDuration(String newVisitDuration) {
    setState(() {
      visitDuration = newVisitDuration;
    });
    // Price depends on visit duration, recalculate
    if (widget.isCustomBooking) {
      print("calculatePricePerVisit recalculated in _updateVisitDuration");
      _calculatePricePerVisit();
    }
  }

  void _updateWorkerCount(int newCount) {
    setState(() {
      workerCount = newCount;
    });
    // Price depends on worker count, recalculate
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateContractDuration(String newDuration) {
    setState(() {
      contractDuration = newDuration;
    });
    // Price depends on contract duration, recalculate
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateVisitsPerWeek(String newVisitsPerWeek) {
    setState(() {
      visitsPerWeek = newVisitsPerWeek;
    });
    // Price depends on visits per week, recalculate
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateSelectedDates(List<DateTime> dates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          selectedDates = dates;
        });
      }
    });
  }

  void _returnFromDateSelection() {
    setState(() {
      if (widget.isCustomBooking) {
        currentStep = 1;
        isReturningFromDateSelection = true;
      } else {
        currentStep = 0; // Return to address selection for package bookings
      }
    });
    _pageController.animateToPage(
      _getPageIndex(),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completePurchase() async {
    final selectedAddress = ref.read(selectedAddressProvider);

    // Use the total price from ServiceDetailsStep for custom booking
    final totalPrice = widget.isCustomBooking
        ? (_totalPriceFromServiceDetails ?? _calculateTotalPrice())
        : widget.package!.finalPrice;

    final originalPrice = widget.isCustomBooking
        ? _calculateOriginalPrice()
        : widget.package!.packagePrice ?? widget.package!.finalPrice;

    final bookingData = BookingData(
      selectedDates: selectedDates,
      totalPrice: totalPrice,
      originalPrice: originalPrice,
      selectedAddress: selectedAddress != null
          ? _extractLocationName(selectedAddress.cardText)
          : 'No Address',
      workerCount: workerCount,
      contractDuration: contractDuration,
      visitsPerWeek: visitsPerWeek,
      selectedNationality: selectedNationality,
      packageName: widget.isCustomBooking
          ? 'Custom Service Package'
          : widget.package!.packageName,
    );

    print(
        "bookingData total price after _completePurchase = ${bookingData.totalPrice}");
    await _animationController.reverse();
    Navigator.pop(context);

    if (widget.onBookingCompleted != null) {
      widget.onBookingCompleted!(bookingData);
    }
  }

  void _updateTotalPriceFromServiceDetails(double totalPrice) {
    setState(() {
      _totalPriceFromServiceDetails = totalPrice;
    });
  }

  double _calculateTotalPrice() {
    print('=== PRICE CALCULATION DEBUG ===');

    // Handle empty strings by using defaults for calculation
    double durationOfVisit = visitDuration.isEmpty
        ? 4.0
        : (double.tryParse(visitDuration.split(' ')[0]) ?? 4.0);
    print(
        'Duration of Visit: $durationOfVisit hours (from string: "$visitDuration")');

    int contractMonths = contractDuration.isEmpty
        ? 1
        : (int.tryParse(contractDuration.split(' ')[0]) ?? 1);
    double contractDurationInWeeks = contractMonths * 4.0;
    print(
        'Contract Duration: $contractMonths months = $contractDurationInWeeks weeks (from string: "$contractDuration")');

    int visitsPerWeekCount = visitsPerWeek.isEmpty
        ? 1
        : (int.tryParse(visitsPerWeek.split(' ')[0]) ?? 1);
    print(
        'Visits Per Week: $visitsPerWeekCount (from string: "$visitsPerWeek")');
    print('Worker Count: $workerCount');
    print('Hour Price: $hourPrice');

    // Rest of the calculation remains the same...
    double basePrice = hourPrice *
        durationOfVisit *
        contractDurationInWeeks *
        visitsPerWeekCount *
        workerCount;
    print(
        'Base Total Price: $basePrice ($hourPrice * $durationOfVisit * $contractDurationInWeeks * $visitsPerWeekCount * $workerCount)');

    double priceAfterDiscount;
    if (!widget.isCustomBooking &&
        widget.package!.discountPercentage != null &&
        widget.package!.discountPercentage! > 0) {
      double discountAmount =
          (widget.package!.discountPercentage! / 100) * basePrice;
      priceAfterDiscount = basePrice - discountAmount;
      print(
          'Discount Applied: ${widget.package!.discountPercentage}% = $discountAmount');
    } else {
      priceAfterDiscount = basePrice;
      print('No Discount Applied');
    }

    double finalPrice;
    if (!widget.isCustomBooking &&
        widget.package!.vatPercentage != null &&
        widget.package!.vatPercentage! > 0) {
      double vatAmount =
          (widget.package!.vatPercentage! / 100) * priceAfterDiscount;
      finalPrice = priceAfterDiscount + vatAmount;
      print('VAT Applied: ${widget.package!.vatPercentage}% = $vatAmount');
    } else {
      double vatAmount = (15.0 / 100) * priceAfterDiscount;
      finalPrice = priceAfterDiscount + vatAmount;
      print('Default VAT Applied: 15% = $vatAmount');
    }

    print('Final Price: $finalPrice');
    print('=== END PRICE CALCULATION ===');
    return finalPrice;
  }

  double _calculatePricePerVisit() {
    if (!widget.isCustomBooking) {
      return 0.0;
    }

    print('=== PRICE PER VISIT CALCULATION (ContinuousBookingOverlay) ===');

    // Handle empty strings by using defaults for calculation
    double durationOfVisit = visitDuration.isEmpty
        ? 4.0
        : (double.tryParse(visitDuration.split(' ')[0]) ?? 4.0);
    print(
        'Duration of Visit: $durationOfVisit hours (from string: "$visitDuration")');

    int contractMonths = contractDuration.isEmpty
        ? 1
        : (int.tryParse(contractDuration.split(' ')[0]) ?? 1);
    double contractDurationInWeeks;

    if (contractDuration.contains('week')) {
      contractDurationInWeeks = contractMonths.toDouble();
    } else if (contractDuration.contains('year')) {
      contractDurationInWeeks = contractMonths * 52.0;
    } else {
      contractDurationInWeeks = contractMonths * 4.0;
    }

    print(
        'Contract Duration: $contractMonths ${contractDuration.contains('week') ? 'weeks' : contractDuration.contains('year') ? 'years' : 'months'} = $contractDurationInWeeks weeks');

    int visitsPerWeekCount = visitsPerWeek.isEmpty
        ? 1
        : (int.tryParse(visitsPerWeek.split(' ')[0]) ?? 1);
    print(
        'Visits Per Week: $visitsPerWeekCount (from string: "$visitsPerWeek")');
    print('Worker Count: $workerCount');
    print('Hour Price: $hourPrice');

    // Rest of the calculation remains the same...
    double totalContractPrice = hourPrice *
        durationOfVisit *
        contractDurationInWeeks *
        visitsPerWeekCount *
        workerCount;
    print(
        'Total Contract Price: $totalContractPrice ($hourPrice * $durationOfVisit * $contractDurationInWeeks * $visitsPerWeekCount * $workerCount)');

    double totalVisits = contractDurationInWeeks * visitsPerWeekCount;
    print(
        'Total Visits in Contract: $totalVisits ($contractDurationInWeeks * $visitsPerWeekCount)');

    double basePricePerVisit = totalContractPrice / totalVisits;
    print(
        'Base Price Per Visit: $basePricePerVisit ($totalContractPrice / $totalVisits)');

    double discountPercentage = 4.8913;
    double discountAmount = (discountPercentage / 100) * basePricePerVisit;
    double finalPricePerVisit = basePricePerVisit - discountAmount;
    print('Discount Applied: $discountPercentage% = $discountAmount');
    print('finalPricePerVisit: $finalPricePerVisit');

    print('=== END PRICE PER VISIT CALCULATION (ContinuousBookingOverlay) ===');

    return finalPricePerVisit;
  }

  double _calculateOriginalPrice() {
    print('=== ORIGINAL PRICE CALCULATION ===');

    // Handle empty strings by using defaults for calculation
    double durationOfVisit = visitDuration.isEmpty
        ? 4.0
        : (double.tryParse(visitDuration.split(' ')[0]) ?? 4.0);
    int contractMonths = contractDuration.isEmpty
        ? 1
        : (int.tryParse(contractDuration.split(' ')[0]) ?? 1);
    double contractDurationInWeeks = contractMonths * 4.0;
    int visitsPerWeekCount = visitsPerWeek.isEmpty
        ? 1
        : (int.tryParse(visitsPerWeek.split(' ')[0]) ?? 1);

    double basePrice = hourPrice *
        durationOfVisit *
        contractDurationInWeeks *
        visitsPerWeekCount *
        workerCount;

    print('Base Price: $basePrice');

    double originalPrice;
    if (!widget.isCustomBooking &&
        widget.package!.vatPercentage != null &&
        widget.package!.vatPercentage! > 0) {
      double vatAmount = (widget.package!.vatPercentage! / 100) * basePrice;
      originalPrice = basePrice + vatAmount;
      print('VAT Applied: ${widget.package!.vatPercentage}% = $vatAmount');
    } else {
      double vatAmount = (15.0 / 100) * basePrice;
      originalPrice = basePrice + vatAmount;
      print('Default VAT Applied: 15% = $vatAmount');
    }

    print('Original Price: $originalPrice');
    print('=== END ORIGINAL PRICE CALCULATION ===');
    return originalPrice;
  }

  double get _currentPrice {
    if (widget.isCustomBooking) {
      return _calculateTotalPrice();
    }
    return widget.package!.finalPrice?.toDouble() ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedAddress = ref.watch(selectedAddressProvider);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: _closeOverlay,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(
                      0,
                      _slideAnimation.value *
                          MediaQuery.of(context).size.height),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        BookingStepHeader(
                          currentStep: currentStep + 1,
                          totalSteps: totalSteps,
                          showBackButton: currentStep > 0,
                          onBackPressed: _previousStep,
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              // Page 0: Address Selection (both custom and package)
                              AddressSelectionStep(
                                addresses: addresses,
                                selectedAddress: selectedAddress,
                                onAddressSelected: _selectAddress,
                                onAddNewAddress: _addNewAddress,
                                onNextPressed: _nextStep,
                                price: _currentPrice,
                                isLoading: isLoadingAddresses,
                                error: addressError,
                                onRetryPressed: _fetchAddresses,
                                isCustomBooking: widget.isCustomBooking,
                              ),
                              // Page 1: Service Details (custom booking) OR Date Selection (package booking)
                              widget.isCustomBooking
                                  ? ServiceDetailsStep(
                                      selectedNationality: selectedNationality,
                                      workerCount: workerCount,
                                      contractDuration: contractDuration,
                                      selectedTime: selectedTime,
                                      visitDuration: visitDuration,
                                      visitsPerWeek: visitsPerWeek,
                                      selectedDays: selectedDays,
                                      onContractDurationChanged:
                                          _updateContractDuration,
                                      onWorkerCountChanged: _updateWorkerCount,
                                      onVisitsPerWeekChanged:
                                          (newVisitsPerWeek) {
                                        _updateVisitsPerWeek(newVisitsPerWeek);
                                        _updateSelectedDays([]);
                                      },
                                      onSelectedDaysChanged:
                                          _updateSelectedDays,
                                      onSelectedDatesChanged:
                                          _updateSelectedDates,
                                      onDonePressed: _completePurchase,
                                      onNextPressed: null,
                                      showBottomNavigation: true,
                                      totalPrice:
                                          _totalPriceFromServiceDetails ??
                                              _calculateTotalPrice(),
                                      selectedDates: selectedDates,
                                      isCustomBooking: widget.isCustomBooking,
                                      onNationalityChanged: _updateNationality,
                                      onTimeChanged: _updateTime,
                                      onVisitDurationChanged:
                                          _updateVisitDuration,
                                      discountPercentage: null,
                                      serviceId: widget.serviceId,
                                      professionId:
                                          widget.professionId, // Add this line
                                      pricePerVisit: _calculatePricePerVisit(),
                                      onTotalPriceChanged:
                                          _updateTotalPriceFromServiceDetails,
                                    )
                                  : DateSelectionStep(
                                      selectedDates: selectedDates,
                                      onDatesChanged: _updateSelectedDates,
                                      onNextPressed: selectedDates.isNotEmpty
                                          ? _completePurchase
                                          : null,
                                      maxSelectableDates: workerCount,
                                      selectedDays: selectedDays,
                                      workerCount: workerCount,
                                      contractDuration: contractDuration,
                                      totalPrice: widget.isCustomBooking
                                          ? _calculateTotalPrice()
                                          : widget.package!.finalPrice!
                                              .toDouble(),
                                      isCustomBooking: widget.isCustomBooking,
                                      pricePerVisit: widget.isCustomBooking
                                          ? _calculatePricePerVisit()
                                          : 0.0,
                                      package: widget.package,
                                      professionId: widget.professionId,
                                    ),
                              // Page 2: Date Selection (custom booking only)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
