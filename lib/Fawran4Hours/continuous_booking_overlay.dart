import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your existing screens
import 'cleaning_service_screen.dart'; // PackageModel
import 'add_new_address.dart';

// Import modularized components
import '../models/address_model.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../steps/address_selection_step.dart';
import '../steps/service_details_step.dart';
import '../steps/date_selection_step.dart';
import '../widgets/booking_step_header.dart';
import '../providers/address_provider.dart';

class ContinuousBookingOverlay extends ConsumerStatefulWidget {
  final PackageModel? package; // Made optional
  final int? selectedShift; // Made optional
  final int serviceId;
  final Function(BookingData)? onBookingCompleted;
  final bool isCustomBooking; // New parameter to indicate custom booking

  const ContinuousBookingOverlay({
    Key? key,
    this.package, // Optional
    this.selectedShift, // Optional
    required this.serviceId,
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
  final int totalSteps = 3; // Address, Service Details, Date Selection

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

  // Date Selection Data
  List<DateTime> selectedDates = [];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Initialize service details values based on whether it's custom or package booking
    if (widget.isCustomBooking) {
      // Default values for custom booking
      workerCount = 1;
      contractDuration = '1 month';
      visitDuration = '4 hours';
      visitsPerWeek = '1 visit weekly';
      selectedNationality = 'East Asia';
      selectedTime = 'Morning';
      hourPrice = 25.0; // Default hourly rate
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

      final response = await http.get(
        Uri.parse(
            'http://10.20.10.114:8080/ords/emdad/fawran/customer_addresses/23'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          addresses = data.map((addressData) {
            return Address(
              cardText: addressData['card_text']?.toString() ?? 'Address',
              addressId: addressData['address_id'] ?? 0,
              cityCode: addressData['city_code'],
              districtCode: addressData['district_code']?.toString() ?? '',
            );
          }).toList();

          if (addresses.isNotEmpty &&
              ref.read(selectedAddressProvider) == null) {
            ref.read(selectedAddressProvider.notifier).state = addresses.first;
          }

          isLoadingAddresses = false;
        });
      } else {
        setState(() {
          addressError =
              'Failed to load addresses. Status: ${response.statusCode}';
          isLoadingAddresses = false;
        });
      }
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

  void _nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
        if (currentStep == 2) {
          isReturningFromDateSelection = false;
        }
      });
      _pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        if (currentStep == 1 && selectedDates.isNotEmpty) {
          isReturningFromDateSelection = true;
        }
      });
      _pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectAddress(int addressId) {
    final selectedAddress = addresses.firstWhere(
      (address) => address.addressId == addressId,
      orElse: () => addresses.first,
    );
    ref.read(selectedAddressProvider.notifier).state = selectedAddress;
  }

  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewAddressScreen(
          package: widget.package,
          serviceId: widget.serviceId,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final newAddress = Address(
        cardText: result['fullAddress'] ??
            '${result['province'] ?? ''}, ${result['city'] ?? ''}, ${result['district'] ?? ''}',
        addressId: DateTime.now().millisecondsSinceEpoch,
        cityCode: result['cityCode'] ?? '',
        districtCode: result['districtCode'] ?? '',
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
  }

  void _updateTime(String newTime) {
    setState(() {
      selectedTime = newTime;
    });
  }

  void _updateVisitDuration(String newVisitDuration) {
    setState(() {
      visitDuration = newVisitDuration;
    });
  }

  void _updateWorkerCount(int newCount) {
    setState(() {
      workerCount = newCount;
    });
  }

  void _updateContractDuration(String newDuration) {
    setState(() {
      contractDuration = newDuration;
    });
  }

  void _updateVisitsPerWeek(String newVisitsPerWeek) {
    setState(() {
      visitsPerWeek = newVisitsPerWeek;
    });
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

  void _goToDateSelection() {
    setState(() {
      currentStep = 2;
      isReturningFromDateSelection = false;
    });
    _pageController.animateToPage(
      currentStep,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _returnFromDateSelection() {
    setState(() {
      currentStep = 1;
      isReturningFromDateSelection = true;
    });
    _pageController.animateToPage(
      currentStep,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completePurchase() async {
    final selectedAddress = ref.read(selectedAddressProvider);

    final totalPrice = _calculateTotalPrice();
    final originalPrice = _calculateOriginalPrice();

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

    await _animationController.reverse();
    Navigator.pop(context);

    if (widget.onBookingCompleted != null) {
      widget.onBookingCompleted!(bookingData);
    }
  }

  double _calculateTotalPrice() {
    print('=== PRICE CALCULATION DEBUG ===');

    double durationOfVisit =
        double.tryParse(visitDuration.split(' ')[0]) ?? 4.0;
    print(
        'Duration of Visit: $durationOfVisit hours (from string: "$visitDuration")');

    int contractMonths = int.tryParse(contractDuration.split(' ')[0]) ?? 1;
    double contractDurationInWeeks = contractMonths * 4.0;
    print(
        'Contract Duration: $contractMonths months = $contractDurationInWeeks weeks (from string: "$contractDuration")');

    int visitsPerWeekCount = int.tryParse(visitsPerWeek.split(' ')[0]) ?? 1;
    print(
        'Visits Per Week: $visitsPerWeekCount (from string: "$visitsPerWeek")');
    print('Worker Count: $workerCount');
    print('Hour Price: $hourPrice');

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
      // Apply default VAT for custom booking (15% is common in Saudi Arabia)
      double vatAmount = (15.0 / 100) * priceAfterDiscount;
      finalPrice = priceAfterDiscount + vatAmount;
      print('Default VAT Applied: 15% = $vatAmount');
    }

    print('Final Price: $finalPrice');
    print('=== END PRICE CALCULATION ===');
    return finalPrice;
  }

  double _calculateOriginalPrice() {
    print('=== ORIGINAL PRICE CALCULATION ===');

    double durationOfVisit =
        double.tryParse(visitDuration.split(' ')[0]) ?? 4.0;
    int contractMonths = int.tryParse(contractDuration.split(' ')[0]) ?? 1;
    double contractDurationInWeeks = contractMonths * 4.0;
    int visitsPerWeekCount = int.tryParse(visitsPerWeek.split(' ')[0]) ?? 1;

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
      // Apply default VAT for custom booking
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
                          showBackButton: (currentStep > 0 &&
                                  !isReturningFromDateSelection) ||
                              currentStep == 2,
                          onBackPressed: () {
                            if (currentStep == 2) {
                              _returnFromDateSelection();
                            } else {
                              _previousStep();
                            }
                          },
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
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
                                isCustomBooking:
                                    widget.isCustomBooking, // Add this line
                              ),
                              ServiceDetailsStep(
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
                                onVisitsPerWeekChanged: (newVisitsPerWeek) {
                                  _updateVisitsPerWeek(newVisitsPerWeek);
                                  _updateSelectedDays([]);
                                },
                                onSelectedDaysChanged: _updateSelectedDays,
                                onSelectDatePressed: _goToDateSelection,
                                onDonePressed: _completePurchase,
                                showBottomNavigation:
                                    isReturningFromDateSelection &&
                                        selectedDates.isNotEmpty,
                                totalPrice: _calculateTotalPrice(),
                                selectedDates: selectedDates,
                                isCustomBooking: widget.isCustomBooking,
                                onNationalityChanged: widget.isCustomBooking
                                    ? _updateNationality
                                    : null,
                                onTimeChanged:
                                    widget.isCustomBooking ? _updateTime : null,
                                onVisitDurationChanged: widget.isCustomBooking
                                    ? _updateVisitDuration
                                    : null,
                                discountPercentage: widget.isCustomBooking
                                    ? null
                                    : widget.package
                                        ?.discountPercentage, // Add this line
                              ),
                              DateSelectionStep(
                                selectedDates: selectedDates,
                                onDatesChanged: _updateSelectedDates,
                                onNextPressed: selectedDates.isNotEmpty
                                    ? _returnFromDateSelection
                                    : null,
                                maxSelectableDates: workerCount,
                                selectedDays: selectedDays,
                                contractDuration: contractDuration,
                                totalPrice: _calculateTotalPrice(),
                              ),
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
