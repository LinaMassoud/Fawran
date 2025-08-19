import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
// Import your existing screens
import 'hourly_service_screen.dart'; // PackageModel
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
import 'package:flashy_flushbar/flashy_flushbar.dart';
import 'package:fawran/generated/app_localizations.dart';

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
    final _storage = FlutterSecureStorage();
bool _isCompletingPurchase = false;

double? _finalPriceFromDateSelection;


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

  List<int>? _validatedWorkerIds;

  // Service Details Data (with defaults for custom booking)
  String selectedNationality = 'East Asia';
  late int workerCount;
  late int contractDuration;
  String selectedTime = 'Morning';
  late String visitDuration;
  late int visitsPerWeek;
  late double hourPrice; // New field for custom booking

double? _hourPrice;
  double? _totalPriceFromServiceDetails;
  double? _pricePerVisitFromServiceDetails;
  double? _priceVatFromServiceDetails;
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
      contractDuration = 0; // Empty string for placeholder
      visitDuration = ''; // Empty string for placeholder
      visitsPerWeek = 0; // Empty string for placeholder
      selectedNationality = ''; // Empty string for placeholder
      selectedTime = ''; // Empty string for placeholder
      hourPrice = 32.0; // Default hourly rate
    } else {
      // Initialize from package (existing functionality)
      workerCount = widget.package!.noOfEmployee;
       contractDuration = widget.package!.noOfWeeks ?? (widget.package!.noOfMonth * 4);
      visitDuration = '${widget.package!.duration} hours';
      visitsPerWeek = widget.package!.visitsWeekly; 
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

    _initializeNationality();
  }
void _initializeNationality() async {
  if (!widget.isCustomBooking && widget.package != null) {
    // Wait for country groups to be fully loaded
    await PackageModel.preloadCountryGroups(serviceId: widget.serviceId);
    
    // Get the updated nationality display from API
    final apiNationality = await widget.package!.getNationalityDisplay(serviceId: widget.serviceId);
    
    // Update the state if different from fallback
    if (mounted && apiNationality != selectedNationality) {
      setState(() {
        selectedNationality = apiNationality;
      });
    }
  }
}
  // Fetch addresses from API
Future<void> _fetchAddresses() async {
  try {
    // Store the currently selected address info before refreshing
    final currentSelectedAddress = ref.read(selectedAddressProvider);
    String? currentSelectedCardText = currentSelectedAddress?.cardText;
    int? currentSelectedAddressId = currentSelectedAddress?.addressId;
    
    setState(() {
      isLoadingAddresses = true;
      addressError = null;
    });
 
    // Get userId from the provider
    final userId = await _storage.read(key: 'user_id') ?? '';
 
    print('userId in _fetchAddresses = $userId');
 
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
 
      // Try to restore the previously selected address
      Address? addressToSelect;
      
      if (currentSelectedAddress != null && addresses.isNotEmpty) {
        // First try to match by address ID
        try {
          addressToSelect = addresses.firstWhere(
            (address) => address.addressId == currentSelectedAddressId,
          );
        } catch (e) {
          // If not found by ID, try to match by card text
          if (currentSelectedCardText != null) {
            try {
              addressToSelect = addresses.firstWhere(
                (address) => address.cardText.toLowerCase() == currentSelectedCardText!.toLowerCase(),
              );
            } catch (e) {
              // If still not found, addressToSelect remains null
              print('Previous address not found in new user\'s addresses');
            }
          }
        }
      }
      
      // If we couldn't restore the previous selection, select the first address
      if (addressToSelect == null && addresses.isNotEmpty) {
        addressToSelect = addresses.first;
      }
      
      // Update the provider with the selected address
      if (addressToSelect != null) {
        ref.read(selectedAddressProvider.notifier).state = addressToSelect;
      } else {
        // Clear the selected address if no addresses are available
        ref.read(selectedAddressProvider.notifier).state = null;
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
    case '3':
      return 'Full Day';
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
  void _updateFinalPrice(double price) {
  setState(() {
    _finalPriceFromDateSelection = price;
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


void _updatePricePerVisit(double pricePerVisit) {
  setState(() {
    _pricePerVisitFromServiceDetails = pricePerVisit;
  });
  print("Price per visit updated: $pricePerVisit");
}

void _updateHourPrice(double hourPrice) {
  setState(() {
    // Store the hour price in a state variable in the parent
    hourPrice = hourPrice; // You'll need to add this variable to parent state
  });
  print('Updated hour price: $hourPrice');
}

void _updatePriceVat(double priceVat) {
  setState(() {
    _priceVatFromServiceDetails = priceVat;
  });
  print('Updated price VAT: $priceVat');
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
  try {
    final selectedAddress = addresses.firstWhere(
      (address) => address.addressId == addressId,
    );
    ref.read(selectedAddressProvider.notifier).state = selectedAddress;
    print('Selected address: ${selectedAddress.cardText} with ID: ${selectedAddress.addressId}');
  } catch (e) {
    print('Error selecting address with ID $addressId: $e');
    // Fallback to first address if the specific one isn't found
    if (addresses.isNotEmpty) {
      ref.read(selectedAddressProvider.notifier).state = addresses.first;
    }
  }
}

  void _addNewAddress() async {
  final userId = await _storage.read(key: 'user_id') ?? '';
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

  // Check if address was successfully created
  if (result != null && result['success'] == true && result['refresh_addresses'] == true) {
    // First refresh the addresses list to get the actual address with proper ID
    await _fetchAddresses();
    
    // Select the newly created address by finding the one with the highest addressId
    if (addresses.isNotEmpty) {
      // Find the address with the highest addressId (most recently created)
      final latestAddress = addresses.reduce((current, next) => 
        current.addressId > next.addressId ? current : next);
      
      // Set the selected address to the latest one
      ref.read(selectedAddressProvider.notifier).state = latestAddress;
    }
    
    // Show success message with blurred background if needed
    if (result['message'] != null) {
      _showSuccessDialog(result['message']);
    }
  }
}

void _showSuccessDialog(String message) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5), // Semi-transparent overlay
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success checkmark icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Success message
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Optional: Auto-dismiss after 2 seconds
                  // You can remove this if you want manual dismissal only
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  // Auto-dismiss after 2 seconds (optional)
  Timer(const Duration(seconds: 2), () {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
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

  void _onWorkerValidationSuccess(List<int> workerIds) {
  setState(() {
    _validatedWorkerIds = workerIds;
  });
  print('✅ Worker IDs received in overlay: $workerIds');
}

  void _updateContractDuration(int newDuration) {
    setState(() {
      contractDuration = newDuration;
    });
    // Price depends on contract duration, recalculate
    if (widget.isCustomBooking) {
      _calculatePricePerVisit();
    }
  }

  void _updateVisitsPerWeek(int newVisitsPerWeek) {
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


Future<Map<String, dynamic>> _createContract(BookingData bookingData) async {
  try {
    // Get required data from secure storage and state
    final userIdString = await _storage.read(key: 'user_id');
    final selectedAddress = ref.read(selectedAddressProvider);
    
    if (userIdString == null || userIdString.isEmpty) {
      throw Exception('User not authenticated');
    }
    
    final userId = int.tryParse(userIdString);
    if (userId == null) {
      throw Exception('Invalid user ID format');
    }
    
    if (selectedAddress == null) {
      throw Exception('No address selected');
    }

    // Extract numeric values from strings
    int hoursNumber = widget.isCustomBooking 
        ? (visitDuration.isEmpty ? 4 : int.tryParse(visitDuration.split(' ')[0]) ?? 4)
        : int.tryParse(widget.package!.duration) ?? 4;
    
    int weeklyVisit = widget.isCustomBooking
        ? (visitsPerWeek == 0 ? 1 : visitsPerWeek)
        : widget.package!.visitsWeekly;
    
    int contractPeriod = widget.isCustomBooking
        ? (contractDuration == 0 ? 4 : contractDuration)
        : widget.package!.noOfWeeks ?? (widget.package!.noOfMonth * 4);
    
    // Use package data for non-custom bookings, calculate for custom bookings
    int visitShift;
    String groupCode;
    
    if (widget.isCustomBooking) {
      // Convert selected time to shift number for custom booking
          if (selectedTime == 'Morning') {
        visitShift = 1;
      } else if (selectedTime == 'Evening') {
        visitShift = 2;
      } else if (selectedTime == 'Full Day') {
        visitShift = 3;
      } else {
        visitShift = 1; // Default to Morning
      }
      
      // Convert nationality to group code for custom booking
      groupCode = '2'; // Default East Asia
      if (selectedNationality == 'South Asia') {
        groupCode = '1';
      } else if (selectedNationality == 'AFRICAN COUNTRIES') {
        groupCode = '3';
      }
    } else {
      // Use package data directly for non-custom bookings
      visitShift = int.tryParse(widget.package!.serviceShift) ?? 1;
      groupCode = widget.package!.groupCode;
    }
    
    // Calculate prices - use package originalPrice for non-custom bookings
    double totalPrice = bookingData.totalPrice;
    double originalPrice = widget.isCustomBooking 
        ? bookingData.totalPrice 
        : widget.package!.originalPrice;
    double priceAfterDiscount = widget.isCustomBooking 
        ? bookingData.totalPrice 
        : widget.package!.priceAfterDiscount;
    
    int vatRate = widget.isCustomBooking ? 15 : widget.package!.vatPercentage;
    double priceVat = widget.isCustomBooking 
    ? (_priceVatFromServiceDetails ?? (totalPrice - (totalPrice / 1.15)))
    : widget.package!.vatAmount;

    // Format visit calendar from selected days
    String visitCalendar = selectedDays.isNotEmpty 
        ? selectedDays.join('-')
        : '';
    
    // Format appointments from selected dates
    List<String> appointments = selectedDates.map((date) => 
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
    ).toList();
    
    String contractStartDate = appointments.isNotEmpty 
        ? appointments.first 
        : DateTime.now().toIso8601String().split('T')[0];

print("serviceId before passing ApiService.createContract = ${widget.serviceId}");
    // Call the ApiService method
    final result = await ApiService.createContract(
      customerId: userId,
      serviceId: widget.serviceId,
      groupCode: groupCode,
      cityId: selectedAddress.cityCode.toString(),
      district: selectedAddress.districtCode,
      employeeCount: workerCount,
      hoursNumber: hoursNumber,
      weeklyVisit: weeklyVisit,
      contractPeriod: contractPeriod,
      visitShift: visitShift,
      hourlyPrice: widget.isCustomBooking ? (_hourPrice?.toInt() ?? hourPrice.toInt()) : widget.package!.hourPrice.toInt(),
      contractStartDate: contractStartDate,
      totalPrice: totalPrice,
      priceVat: priceVat,
      vatRat: vatRate,
      customerLocation: selectedAddress.cardText,
      priceAfterDiscount: priceAfterDiscount,
      originalPrice: originalPrice,
      visitPrice: widget.isCustomBooking 
        ? (_pricePerVisitFromServiceDetails ?? _calculatePricePerVisit())
        : widget.package!.visitPrice,
      visitCalendar: visitCalendar.isNotEmpty ? visitCalendar : null,
      packageId: !widget.isCustomBooking && widget.package != null ? widget.package!.packageId : null,
      appointments: appointments.isNotEmpty ? appointments : null,
      workerIds: _validatedWorkerIds,
    );

    if (mounted) {
      if (result['success'] == true) {
        FlashyFlushbar(
          leadingWidget: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 24,
          ),
          message: result['message'] ?? 'Contract created successfully',
          duration: const Duration(seconds: 3),
          trailingWidget: IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              FlashyFlushbar.cancel();
            },
          ),
          isDismissible: true,
          backgroundColor: Colors.green,
          messageStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ).show();
      } else {
        if (result['statusCode'] == 409) {
          FlashyFlushbar(
            leadingWidget: const Icon(
              Icons.warning_outlined,
              color: Colors.white,
              size: 24,
            ),
            message: result['message'] ?? 'A service contract is already in pending status',
            duration: const Duration(seconds: 5),
            trailingWidget: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                FlashyFlushbar.cancel();
              },
            ),
            isDismissible: true,
            backgroundColor: Colors.orange,
            messageStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ).show();
        } else {
          FlashyFlushbar(
            leadingWidget: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
            message: result['message'] ?? 'Failed to create contract',
            duration: const Duration(seconds: 5),
            trailingWidget: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                FlashyFlushbar.cancel();
              },
            ),
            isDismissible: true,
            backgroundColor: Colors.red,
            messageStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ).show();
        }
      }
    }
    
    return result;
    
  } catch (e) {
    print('Error creating contract: $e');
    
    if (mounted) {
      FlashyFlushbar(
      leadingWidget: const Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 24,
      ),
      message: 'Failed to create contract: ${e.toString()}',
      duration: const Duration(seconds: 5),
      trailingWidget: IconButton(
        icon: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          FlashyFlushbar.cancel();
        },
      ),
      isDismissible: true,
      backgroundColor: Colors.red,
      messageStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ).show();
    }
    
    return {
      'success': false,
      'message': 'Failed to create contract: ${e.toString()}',
      'error': e.toString(),
    };
  }
}



  void _completePurchase() async {
  if (_isCompletingPurchase) return; // Prevent duplicate calls
  _isCompletingPurchase = true;
  final selectedAddress = ref.read(selectedAddressProvider);

  // Use the total price from ServiceDetailsStep for custom booking
  final totalPrice = widget.isCustomBooking
      ? (_totalPriceFromServiceDetails ?? _calculateTotalPrice())
      : (_finalPriceFromDateSelection ?? widget.package!.finalPrice); 

  final originalPrice = widget.isCustomBooking
      ? _calculateOriginalPrice()
      : widget.package!.packagePrice ?? widget.package!.finalPrice;

  // Create initial BookingData without contract_id for contract creation
  final initialBookingData = BookingData(
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
        ? AppLocalizations.of(context)!.customServicePackage
        : widget.package!.packageName,
  );

  // Create contract and get the result with contract_id
  final contractResult = await _createContract(initialBookingData);

  // Create final BookingData with contract_id
  final finalBookingData = BookingData(
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
        ? AppLocalizations.of(context)!.customServicePackage
        : widget.package!.packageName,
    contractId: contractResult['success'] == true ? contractResult['contract_id'] : null,
  );

  print("bookingData total price after _completePurchase = ${finalBookingData.totalPrice}");
  print("bookingData contract_id = ${finalBookingData.contractId}");
  
  await _animationController.reverse();
  Navigator.pop(context);

  if (contractResult['success'] == true && widget.onBookingCompleted != null) {
    widget.onBookingCompleted!(finalBookingData);
  }

  _isCompletingPurchase = false; // Reset the flag
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

    double contractDurationInWeeks = contractDuration == 0 ? 4.0 : contractDuration.toDouble();
  print('Contract Duration: $contractDurationInWeeks weeks');

    int visitsPerWeekCount = visitsPerWeek == 0 ? 1 : visitsPerWeek;
  print('Visits Per Week: $visitsPerWeekCount');
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

    // Handle empty strings by using defaults for calculation
    double durationOfVisit = visitDuration.isEmpty
        ? 4.0
        : (double.tryParse(visitDuration.split(' ')[0]) ?? 4.0);

    double contractDurationInWeeks = contractDuration == 0 ? 4.0 : contractDuration.toDouble();

    int visitsPerWeekCount = visitsPerWeek == 0 ? 1 : visitsPerWeek;
    // Rest of the calculation remains the same...
    double totalContractPrice = hourPrice *
        durationOfVisit *
        contractDurationInWeeks *
        visitsPerWeekCount *
        workerCount;
    
    double totalVisits = contractDurationInWeeks * visitsPerWeekCount;
    
    double basePricePerVisit = totalContractPrice / totalVisits;
    
    double discountPercentage = 4.8913;
    double discountAmount = (discountPercentage / 100) * basePricePerVisit;
    double finalPricePerVisit = basePricePerVisit - discountAmount;
    
    return finalPricePerVisit;
  }

  double _calculateOriginalPrice() {
    print('=== ORIGINAL PRICE CALCULATION ===');

    // Handle empty strings by using defaults for calculation
    double durationOfVisit = visitDuration.isEmpty
        ? 4.0
        : (double.tryParse(visitDuration.split(' ')[0]) ?? 4.0);
    double contractDurationInWeeks = contractDuration == 0 ? 4.0 : contractDuration.toDouble();
    int visitsPerWeekCount = visitsPerWeek == 0 ? 1 : visitsPerWeek;

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
                                      selectedAddress: selectedAddress,
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
                                      onPricePerVisitChanged: _updatePricePerVisit,
                                      onHourPriceChanged: _updateHourPrice,
                                      onPriceVatChanged: _updatePriceVat,
                                      onWorkerIdsChanged: _onWorkerValidationSuccess, 
                                    )
                                  : DateSelectionStep(
                                      selectedDates: selectedDates,
                                      selectedAddress: selectedAddress,
                                      onDatesChanged: _updateSelectedDates,
                                      onNextPressed: selectedDates.isNotEmpty
                                          ? _completePurchase
                                          : null,
                                      maxSelectableDates: workerCount,
                                      selectedDays: selectedDays,
                                      workerCount: workerCount,
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
                                      onWorkerValidationSuccess: _onWorkerValidationSuccess,
                                      onPriceChanged: _updateFinalPrice,
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

