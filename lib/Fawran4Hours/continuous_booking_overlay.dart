import 'package:flutter/material.dart';
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
  final Function(BookingData)? onBookingCompleted; // Add callback for booking completion

  const ContinuousBookingOverlay({
    Key? key,
    required this.package,
    this.onBookingCompleted,
  }) : super(key: key);

  @override
  _ContinuousBookingOverlayState createState() => _ContinuousBookingOverlayState();

  // Static method to show as overlay
  static void showAsOverlay(
    BuildContext context, {
    required PackageModel package,
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

  BookingData({
    required this.selectedDates,
    required this.totalPrice,
    required this.selectedAddress,
    required this.workerCount,
    required this.contractDuration,
    required this.visitsPerWeek,
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
  List<AddressModel> addresses = [
    AddressModel(
      id: '1',
      name: 'Al rashidiya',
      fullAddress: 'Riyadh Province, Riyadh Principality',
      isSelected: true,
    ),
    AddressModel(
      id: '2',
      name: 'Al Abha',
      fullAddress: 'Riyadh Province, Riyadh Principality',
      isSelected: false,
    ),
  ];

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
    selectedNationality = widget.package.groupCode == '2' ? 'East Asia' : 'South Asia';
    selectedTime = _getTimeFromShift(widget.package.serviceShift);
    
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
  }

  String _getTimeFromShift(String shift) {
    switch (shift) {
      case '1': return 'Morning';
      case '2': return 'Afternoon';
      case '3': return 'Evening';
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
    setState(() {
      selectedDates = dates;
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
    );

    // Close overlay with animation
    await _animationController.reverse();
    Navigator.pop(context);

    // Call the callback to update the parent screen
    if (widget.onBookingCompleted != null) {
      widget.onBookingCompleted!(bookingData);
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
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
                              ),
                              ServiceDetailsStep(
                                selectedNationality: selectedNationality,
                                workerCount: workerCount,
                                contractDuration: contractDuration,
                                selectedTime: selectedTime,
                                visitDuration: visitDuration,
                                visitsPerWeek: visitsPerWeek,
                                onContractDurationChanged: _updateContractDuration,
                                onWorkerCountChanged: _updateWorkerCount,
                                onVisitsPerWeekChanged: _updateVisitsPerWeek,
                                onSelectDatePressed: _goToDateSelection,
                                onDonePressed: _completePurchase, // This will now close overlay and update parent
                                showBottomNavigation: isReturningFromDateSelection && selectedDates.isNotEmpty,
                                totalPrice: _calculateTotalPrice(),
                                selectedDates: selectedDates,
                              ),
                              DateSelectionStep(
                                selectedDates: selectedDates,
                                onDatesChanged: _updateSelectedDates,
                                onNextPressed: selectedDates.isNotEmpty ? _returnFromDateSelection : null,
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