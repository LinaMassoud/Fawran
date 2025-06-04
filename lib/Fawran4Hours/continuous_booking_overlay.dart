import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your existing screens
import 'cleaning_service_screen.dart'; // PackageModel
import 'add_new_address.dart';

// Import modularized components
import '../models/address_model.dart';
import '../steps/address_selection_step.dart';
import '../steps/service_details_step.dart';
import '../steps/date_selection_step.dart';
import '../widgets/booking_step_header.dart';

class ContinuousBookingOverlay extends StatefulWidget {
  final PackageModel package;
  final int selectedShift;
  final Function(BookingData)? onBookingCompleted; // Add callback for booking completion

  const ContinuousBookingOverlay({
  Key? key,
  required this.package,
  required this.selectedShift, // Add this parameter
  this.onBookingCompleted,
}) : super(key: key);

  @override
  _ContinuousBookingOverlayState createState() => _ContinuousBookingOverlayState();

  // Static method to show as overlay
  static void showAsOverlay(
  BuildContext context, {
  required PackageModel package,
  required int selectedShift, // Add this parameter
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
      selectedShift: selectedShift, // Pass the shift
      onBookingCompleted: onBookingCompleted,
    ),
  );
}
}

// Data class to hold booking information
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

class _ContinuousBookingOverlayState extends State<ContinuousBookingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late PageController _pageController;

  int currentStep = 0;
  final int totalSteps = 3; // Address, Service Details, Date Selection
  
  // Track if we're returning from date selection
  bool isReturningFromDateSelection = false;

  // Address Selection Data
  List<AddressModel> addresses = [];
  bool isLoadingAddresses = true;
  String? addressError;
  List<String> selectedDays = [];

  // Service Details Data
  String selectedNationality = 'East Asia';
  late int workerCount;
  late String contractDuration;
  String selectedTime = 'Morning';
  late String visitDuration;
  late String visitsPerWeek;

  // Date Selection Data
  List<DateTime> selectedDates = [];

  @override
void initState() {
  super.initState();
  
  _pageController = PageController();
  
  // Initialize service details values
  workerCount = widget.package.noOfEmployee;
  contractDuration = '${widget.package.noOfMonth} month${widget.package.noOfMonth > 1 ? 's' : ''}';
  visitDuration = '${widget.package.duration} hours';
  visitsPerWeek = '${widget.package.visitsWeekly} visit${widget.package.visitsWeekly > 1 ? 's' : ''} weekly';
  
  // Fix: Use the actual selected nationality and time from user selection
  selectedNationality = widget.package.nationalityDisplay; // This will correctly show "East Asia" or "African"
  selectedTime = _getTimeFromShift(widget.selectedShift.toString()); // Use the passed shift instead of package shift
  
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
        Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/address?customer_id=428'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          addresses = data.asMap().entries.map((entry) {
            int index = entry.key;
            var addressData = entry.value;
            
            return AddressModel(
              id: index.toString(),
              name: _extractLocationName(addressData['CARD_TEXT']),
              fullAddress: addressData['CARD_TEXT'],
              isSelected: index == 0, // Select the first address by default
            );
          }).toList();
          
          isLoadingAddresses = false;
        });
      } else {
        setState(() {
          addressError = 'Failed to load addresses. Status: ${response.statusCode}';
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

  // Extract a readable location name from the CARD_TEXT
  String _extractLocationName(String cardText) {
    // Parse the card text to extract meaningful location name
    // Example: "Riyadh-Roshan--Villa-Number456-Floor No: Ground-Floor No:0"
    List<String> parts = cardText.split('-');
    
    if (parts.length >= 2) {
      // Take the first two parts as the location name
      String city = parts[0].trim();
      String area = parts[1].trim();
      return '$area, $city';
    } else if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    
    return 'Address';
  }

  String _getTimeFromShift(String shift) {
    switch (shift) {
      case '1': return 'Morning';
      case '2': return 'Evening';
      default: return 'Morning';
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

  void _selectAddress(String addressId) {
    setState(() {
      addresses = addresses.map((address) {
        return address.copyWith(isSelected: address.id == addressId);
      }).toList();
    });
  }

  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewAddressScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        addresses = addresses.map((address) {
          return address.copyWith(isSelected: false);
        }).toList();

        final newAddress = AddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['title'] ?? 'New Address',
          fullAddress: result['fullAddress'] ?? 
                      '${result['province'] ?? ''}, ${result['city'] ?? ''}, ${result['district'] ?? ''}',
          isSelected: true,
        );
        
        addresses.add(newAddress);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
  // Use WidgetsBinding.instance.addPostFrameCallback to defer setState
  // until after the current build phase is complete
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
  // Create booking data
  final selectedAddress = addresses.firstWhere((addr) => addr.isSelected);
  final bookingData = BookingData(
    selectedDates: selectedDates,
    totalPrice: _calculateTotalPrice(),
    selectedAddress: selectedAddress.name,
    workerCount: workerCount,
    contractDuration: contractDuration,
    visitsPerWeek: visitsPerWeek,
    selectedNationality: selectedNationality, // Pass the actual nationality
    packageName: widget.package.packageName, // Pass the actual package name
  );

  // Close overlay with animation
  await _animationController.reverse();
  Navigator.pop(context);

  // Call the callback to update the parent screen
  if (widget.onBookingCompleted != null) {
    widget.onBookingCompleted!(bookingData);
  }
}

  // Calculate total price from selected dates
  double _calculateTotalPrice() {
    double total = 0;
    for (DateTime date in selectedDates) {
      // Use the same pricing logic as in DateSelectionStep
      final day = date.day;
      if (day % 7 == 0 || day % 7 == 1) {
        total += 125.0; // Weekend-like pricing
      } else if (day % 5 == 0) {
        total += 119.0; // Special pricing
      } else {
        total += 115.0; // Standard pricing
      }
    }
    return total;
  }

  // Calculate price based on package
  double get _currentPrice {
    return widget.package.finalPrice?.toDouble() ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Semi-transparent background
              GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              
              // Close button
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

              // Main content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
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
                        // Header with back arrow only when needed
                        BookingStepHeader(
                          showBackButton: (currentStep > 0 && !isReturningFromDateSelection) || currentStep == 2,
                          onBackPressed: () {
                            if (currentStep == 2) {
                              _returnFromDateSelection();
                            } else {
                              _previousStep();
                            }
                          },
                        ),
                        
                        // Content pages
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              AddressSelectionStep(
                                addresses: addresses,
                                onAddressSelected: _selectAddress,
                                onAddNewAddress: _addNewAddress,
                                onNextPressed: _nextStep,
                                price: _currentPrice,
                                isLoading: isLoadingAddresses,
                                error: addressError,
                                onRetryPressed: _fetchAddresses,
                              ),
                              ServiceDetailsStep(
                                selectedNationality: selectedNationality,
                                workerCount: workerCount,
                                contractDuration: contractDuration,
                                selectedTime: selectedTime,
                                visitDuration: visitDuration,
                                visitsPerWeek: visitsPerWeek,
                                selectedDays: selectedDays, // Add this
                                onContractDurationChanged: _updateContractDuration,
                                onWorkerCountChanged: _updateWorkerCount,
                                onVisitsPerWeekChanged: (newVisitsPerWeek) {
                                  _updateVisitsPerWeek(newVisitsPerWeek);
                                  // Reset selected days when visits per week changes
                                  _updateSelectedDays([]);
                                },
                                onSelectedDaysChanged: _updateSelectedDays, // Add this
                                onSelectDatePressed: _goToDateSelection,
                                onDonePressed: _completePurchase,
                                showBottomNavigation: isReturningFromDateSelection && selectedDates.isNotEmpty,
                                totalPrice: _calculateTotalPrice(),
                                selectedDates: selectedDates,
                              ),
                              DateSelectionStep(
                                selectedDates: selectedDates,
                                onDatesChanged: _updateSelectedDates,
                                onNextPressed: selectedDates.isNotEmpty ? _returnFromDateSelection : null,
                                maxSelectableDates: workerCount,
                                selectedDays: selectedDays, // Pass the selected days
                                contractDuration: contractDuration, // Pass the contract duration
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