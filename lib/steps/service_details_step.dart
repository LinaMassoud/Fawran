import 'package:flutter/material.dart';
import '../widgets/booking_bottom_navigation.dart';
import '../services/api_service.dart';
import '../models/profession_model.dart';
import 'package:intl/intl.dart';
import 'custom_date_selection.dart';
import 'package:fawran/generated/app_localizations.dart';
import '../models/address_model.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:ui' as ui;


class ServiceDetailsStep extends ConsumerStatefulWidget {
  final String selectedNationality;
  final int workerCount;
  final int contractDuration; // Changed from String to int (weeks)
  final String selectedTime;
  final String visitDuration;
  final int visitsPerWeek; // Changed from String to int (visits number)
  final List<String> selectedDays;
  final Function(int) onContractDurationChanged; // Changed from String to int
  final Function(int) onWorkerCountChanged;
  final Function(int) onVisitsPerWeekChanged; // Changed from String to int
  final Function(List<String>) onSelectedDaysChanged;
  final Function(List<int>)? onWorkerIdsChanged;
  final Function(int?)? onPromotionIdChanged;
  final VoidCallback? onSelectDatePressed;
  final VoidCallback? onDonePressed;
  final VoidCallback? onNextPressed;
  final bool showBottomNavigation;
  final double totalPrice;
  final List<DateTime> selectedDates;
  final double? discountPercentage;
  final int serviceId;
  final int professionId;
  final double pricePerVisit;
  final Address? selectedAddress;

  // New parameters for custom booking support
  final bool isCustomBooking;
  final Function(String)? onNationalityChanged;
  final Function(String)? onTimeChanged;
  final Function(String)? onVisitDurationChanged;
  final Function(List<DateTime>)? onSelectedDatesChanged;
  final Function(double)? onTotalPriceChanged;
  final Function(double)? onPricePerVisitChanged;
  final Function(double)? onHourPriceChanged;
  final Function(double)? onPriceVatChanged;

  const ServiceDetailsStep({
    Key? key,
    this.selectedNationality = '',
    required this.workerCount,
    this.contractDuration = 0, // Changed default from '' to 0
    this.selectedTime = '',
    this.visitDuration = '',
    this.visitsPerWeek = 0, // Changed default from '' to 0
    this.selectedDays = const [],
    this.selectedAddress,
    required this.onContractDurationChanged,
    required this.onWorkerCountChanged,
    required this.onVisitsPerWeekChanged,
    required this.onSelectedDaysChanged,
    this.onWorkerIdsChanged,
    this.onSelectDatePressed,
    this.onDonePressed,
    this.onNextPressed,
    this.onSelectedDatesChanged,
    this.showBottomNavigation = false,
    this.totalPrice = 0.0,
    this.selectedDates = const [],
    this.isCustomBooking = false,
    this.onNationalityChanged,
    this.onTimeChanged,
    this.onVisitDurationChanged,
    this.discountPercentage,
    required this.serviceId,
    required this.professionId,
    this.pricePerVisit = 0.0,
    this.onTotalPriceChanged,
    this.onPricePerVisitChanged,
    this.onHourPriceChanged,
    this.onPriceVatChanged,
    this.onPromotionIdChanged,
  }) : super(key: key);

  @override
  _ServiceDetailsStepState createState() => _ServiceDetailsStepState();
}
class _ServiceDetailsStepState extends ConsumerState<ServiceDetailsStep> {
  final List<String> weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Saturday'
  ];

  // Add these new state variables
  List<String> nationalities = []; // Remove default values
  List<String> timeSlots = []; // Remove default values
  List<String> visitDurations = []; // Add new variable for visit durations
  bool isLoadingNationalities = false;
  bool isLoadingTimeSlots = false;
  bool isLoadingVisitDurations = false;

  List<Map<String, dynamic>> contractDurations = [];
  List<Map<String, dynamic>> hourlyVisits = [];
  bool isLoadingContractDurations = false;
  bool isLoadingHourlyVisits = false;

  double _apiHourPrice = 0.0;

  bool _showCalendar = false;
  List<DateTime> _internalSelectedDates = [];
  double _calculatedTotalPrice = 0.0;

  double _apiPricePerVisit = 0.0;
double _apiTotalPrice = 0.0;
bool _isCalculatingPrice = false;
bool _isValidatingWorkers = false;
List<int> _validatedWorkerIds = [];

double _apiFinalPricePerVisit = 0.0; // Price per visit with VAT
double _vatAmount = 0.0;
double _apiPriceVat = 0.0;
int _apiTotalVisits = 1;

bool _isSnackBarShowing = false;

String _couponCode = '';
bool _isValidatingCoupon = false;
bool _isCouponApplied = false;
String _couponMessage = '';
bool _isCouponValid = false;
double _originalFinalPrice = 0.0; // Store original price before coupon
double _originalPricePerVisit = 0.0; // Store original price per visit before coupon
TextEditingController _couponController = TextEditingController();
Address? _previousAddress;

int? _appliedPromotionId;

  @override
  void initState() {
    super.initState();
    _previousAddress = widget.selectedAddress;
    if (widget.isCustomBooking) {
      _loadCountryGroups();
      _loadServiceShifts();
      _loadVisitDurations(); // Add this call
      _loadContractDurations(); // Add this
      _loadHourlyVisits();
    }
  }

  @override
void dispose() {
  _couponController.dispose();
  super.dispose();
}


@override
void didUpdateWidget(ServiceDetailsStep oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // Check if the selected address has changed
  if (widget.selectedAddress != _previousAddress) {
    print('🔄 [ADDRESS CHANGE DETECTED] Old: ${_previousAddress?.toString()} -> New: ${widget.selectedAddress?.toString()}');
    
    // Schedule the coupon reset for after the current build cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetCouponOnAddressChange();
      }
    });
    
    // Update the previous address reference
    _previousAddress = widget.selectedAddress;
  }
}

// 3. Add this method to reset coupon when address changes
void _resetCouponOnAddressChange() {
  print('🔄 [ADDRESS CHANGE] Resetting coupon and all fields due to address change');
  
  // First reset coupon if applied
  if (_isCouponApplied || _couponCode.isNotEmpty) {
    print('💳 [COUPON] Resetting coupon due to address change');
    
    setState(() {
      _isCouponApplied = false;
      _isCouponValid = false;
      _couponMessage = '';
      _couponCode = '';
      _couponController.clear();
      _appliedPromotionId = null;
      
      
    });

    // Clear promotion in parent
    if (widget.onPromotionIdChanged != null) {
      widget.onPromotionIdChanged!(null);
    }
  }

}


Future<void> _loadContractDurations() async {
    setState(() {
      isLoadingContractDurations = true;
    });

    try {
      final response = await ApiService.fetchContractDurations();
      if (response is List && response.isNotEmpty) {
        setState(() {
          contractDurations = response.cast<Map<String, dynamic>>();
          isLoadingContractDurations = false;
        });
      }
    } catch (e) {
      print('Error loading contract durations: $e');
      setState(() {
        isLoadingContractDurations = false;
      });
    }
  }

  Future<void> _loadHourlyVisits() async {
    setState(() {
      isLoadingHourlyVisits = true;
    });

    try {
      final response = await ApiService.fetchHourlyVisits();
      if (response is List && response.isNotEmpty) {
        setState(() {
          hourlyVisits = response.cast<Map<String, dynamic>>();
          isLoadingHourlyVisits = false;
        });
      }
    } catch (e) {
      print('Error loading hourly visits: $e');
      setState(() {
        isLoadingHourlyVisits = false;
      });
    }
  }
  Future<void> _loadVisitDurations() async {
  setState(() {
    isLoadingVisitDurations = true;
  });

  try {
    final apiService = ApiService();
    final professions = await apiService.fetchProfessions();

    List<String> availableDurations = [];

    // Find the profession that contains the service with matching serviceId
    for (final profession in professions) {
      if (profession.services != null && profession.services!.isNotEmpty) {
        // Look for matching service in the services list
        for (final service in profession.services!) {
          if (service.id == widget.serviceId) {
            // Extract the duration from service name
            // Handles both English (e.g., "FAWRAN 4 Hours") and Arabic (e.g., "فوران 4 ساعات")
            final serviceName = service.name;
            
            // Check for Arabic "ساعات" first
            final arabicMatch = RegExp(r'(\d+)\s*ساعات').firstMatch(serviceName);
            if (arabicMatch != null) {
              final hours = arabicMatch.group(1);
              availableDurations.add('$hours ساعات');
            } else {
              // Check for English "Hours"
              final englishMatch = RegExp(r'(\d+)\s*Hours?', caseSensitive: false)
                  .firstMatch(serviceName);
              if (englishMatch != null) {
                final hours = englishMatch.group(1);
                availableDurations.add('$hours hours');
              }
            }
            break;
          }
        }
      }
    }

    setState(() {
      visitDurations = availableDurations.isNotEmpty ? availableDurations : [];
      isLoadingVisitDurations = false;
    });

    // AUTO-SELECT: If there's exactly one duration and it's not already selected, select it
    if (availableDurations.length == 1 && 
        widget.visitDuration != availableDurations.first &&
        widget.onVisitDurationChanged != null) {
      widget.onVisitDurationChanged!(availableDurations.first);
      _calculatePriceFromAPI();
    }
  } catch (e) {
    print('Error loading visit durations: $e');
    setState(() {
      visitDurations = []; // No fallback values
      isLoadingVisitDurations = false;
    });
  }
}


Future<void> _validateCouponCode() async {
  if (_couponCode.trim().isEmpty) {
    _showValidationMessage('Please enter a coupon code');
    return;
  }

  // Check if all required data is available from the existing calculation
  if (_apiPricePerVisit <= 0 || _apiTotalPrice <= 0 || _apiHourPrice <= 0) {
    _showValidationMessage('Please complete all fields first to apply coupon');
    return;
  }

  setState(() {
    _isValidatingCoupon = true;
    _couponMessage = '';
  });

  try {
    // Get shift ID from selected time
    int shiftId = 1; // Default fallback
    try {
      final serviceShifts = await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
      final matchingShift = serviceShifts.firstWhere(
        (shift) => shift['service_shifts']?.toString().toLowerCase() == widget.selectedTime.toLowerCase(),
        orElse: () => {'id': 1},
      );
      shiftId = int.parse(matchingShift['id'].toString());
    } catch (e) {
      print('❌ Error fetching shift ID for coupon: $e');
    }

    // Get city code - you might need to adjust this based on your address model
    int cityCode = 1; // Default
    if (widget.selectedAddress != null) {
      cityCode = int.tryParse(widget.selectedAddress!.cityCode.toString()) ?? 1;
    }

    // Use existing calculated values instead of calling calculatePackagePrice again
    final finalPrice = _apiFinalPricePerVisit; // Use already calculated final price with VAT
    final totalVisits = _apiTotalVisits; // Calculate total visits
    final hourPrice = _apiHourPrice; // Use already calculated hour price

    print('🔍 [COUPON] Validating coupon with parameters:');
    print('  - promotionCode: $_couponCode');
    print('  - shiftId: $shiftId');
    print('  - cityCode: $cityCode');
    print('  - originalPrice: $finalPrice');
    print('  - hourPrice: $hourPrice');
    print('  - totalVisits: $totalVisits');

    // Call the validatePromotion API with the existing calculated values
    final response = await ApiService.validatePromotion(
      promotionCode: _couponCode.trim(),
      shiftId: shiftId,
      cityCode: cityCode,
      originalPrice: finalPrice, // Use existing final_price
      hourPrice: hourPrice, // Use existing hour_price
      totalVisits: totalVisits, // Use calculated total_visits
    );

    print('🔍 [COUPON] API response: $response');

    if (response != null && response['valid'] == true) {
      // Store original prices if not already stored
      if (_originalFinalPrice == 0.0) {
        _originalFinalPrice = _apiFinalPricePerVisit;
        _originalPricePerVisit = _apiPricePerVisit;
      }

      // Update prices with coupon discount
      final newFinalPrice = response['final_price']?.toDouble() ?? _apiFinalPricePerVisit;
      final newPricePerVisit = response['price_per_visit']?.toDouble() ?? _apiPricePerVisit;
      final promotionId = response['promotion_id'] as int?;
      
      print("newFinalPrice = ${newFinalPrice}");
      print("newPricePerVisit = ${newPricePerVisit}");
      setState(() {
        _isCouponValid = true;
        _isCouponApplied = true;
        _couponMessage = response['message'] ?? 'Coupon applied successfully!';
        _appliedPromotionId = promotionId;
        
        // Update the prices with coupon discount
        _apiFinalPricePerVisit = newFinalPrice;
        _apiPricePerVisit = newPricePerVisit;
        
        _isValidatingCoupon = false;
      });

      // Call the promotion callback if available
      if (widget.onPromotionIdChanged != null && promotionId != null) {
        widget.onPromotionIdChanged!(promotionId);
      }

      // Recalculate total price with new discounted price
      if (_internalSelectedDates.isNotEmpty) {
        double newTotalPrice = _internalSelectedDates.length * _apiPricePerVisit;
        print("newTotalPrice = ${newTotalPrice}");
        setState(() {
          _calculatedTotalPrice = newTotalPrice;
        });

        print("_calculatedTotalPrice = ${_calculatedTotalPrice}");
        // Update parent with new total price
        if (widget.onTotalPriceChanged != null) {
          widget.onTotalPriceChanged!(newTotalPrice);
        }
      }

      // Update parent callbacks with new prices
      if (widget.onPricePerVisitChanged != null) {
        widget.onPricePerVisitChanged!(_apiPricePerVisit);
      }

      print('✅ [COUPON] Coupon applied successfully');
    } else {
      setState(() {
        _isCouponValid = false;
        _isCouponApplied = false;
        _couponMessage = response?['message'] ?? 'Invalid coupon code';
        _isValidatingCoupon = false;
      });
      print('❌ [COUPON] Invalid coupon code');
    }
  } catch (e) {
    print('💥 [COUPON] Error validating coupon: $e');
    setState(() {
      _isValidatingCoupon = false;
      _isCouponValid = false;
      _isCouponApplied = false;
      _couponMessage = 'Error validating coupon. Please try again.';
    });
  }
}

// 3. Add this method to remove coupon

void _removeCoupon() {
  setState(() {
    _isCouponApplied = false;
    _isCouponValid = false;
    _couponMessage = '';
    _couponCode = '';
    _couponController.clear();
    _appliedPromotionId = null;
    
    // Restore original prices
    if (_originalFinalPrice > 0) {
      _apiFinalPricePerVisit = _originalFinalPrice;
      _apiPricePerVisit = _originalPricePerVisit;
      _originalFinalPrice = 0.0;
      _originalPricePerVisit = 0.0;
    }
  });

  // Recalculate total price with original prices
  if (_internalSelectedDates.isNotEmpty) {
    double originalTotalPrice = _internalSelectedDates.length * _apiFinalPricePerVisit;
    setState(() {
      _calculatedTotalPrice = originalTotalPrice;
    });

    // Update parent with original total price
    if (widget.onTotalPriceChanged != null) {
      widget.onTotalPriceChanged!(originalTotalPrice);
    }
  }

  // Update parent callbacks with original prices
  if (widget.onPricePerVisitChanged != null) {
    widget.onPricePerVisitChanged!(_apiPricePerVisit);
  }

  if (widget.onPromotionIdChanged != null) {
    widget.onPromotionIdChanged!(null);
  }
}

void _resetDependentFields(String changedField) {
    switch (changedField) {
      case 'nationality':
        // Reset all fields below nationality
        if (widget.onTimeChanged != null) widget.onTimeChanged!('');
        widget.onVisitsPerWeekChanged(0); // Changed from '' to 0
        widget.onContractDurationChanged(0); // Changed from '' to 0
        break;
      case 'workerCount':
        // Reset all fields below worker count
        widget.onContractDurationChanged(0); // Changed from '' to 0
        if (widget.onTimeChanged != null) widget.onTimeChanged!('');
        widget.onVisitsPerWeekChanged(0); // Changed from '' to 0
        break;
      case 'contractDuration':
        // Reset fields below contract duration
        if (widget.onTimeChanged != null) widget.onTimeChanged!('');
        widget.onVisitsPerWeekChanged(0); // Changed from '' to 0
        break;
      case 'time':
        // Reset fields below time
        widget.onVisitsPerWeekChanged(0); // Changed from '' to 0
        break;
      case 'visitDuration':
        // Reset fields below visit duration
        widget.onVisitsPerWeekChanged(0); // Changed from '' to 0
        break;
    }
    
    // Always reset calendar and dates for any field change
    _resetCalendarSelection();
  }




Future<void> _calculatePriceFromAPI() async {
    print('🔍 DEBUG: Starting _calculatePriceFromAPI calculation');
    
    // Check if all required fields are selected
    print('🔍 DEBUG: Checking required fields:');
    print('  - selectedNationality: "${widget.selectedNationality}" (isEmpty: ${widget.selectedNationality.isEmpty})');
    print('  - contractDuration: ${widget.contractDuration} (is <= 0: ${widget.contractDuration <= 0})');
    print('  - selectedTime: "${widget.selectedTime}" (isEmpty: ${widget.selectedTime.isEmpty})');
    print('  - visitDuration: "${widget.visitDuration}" (isEmpty: ${widget.visitDuration.isEmpty})');
    print('  - visitsPerWeek: ${widget.visitsPerWeek} (is <= 0: ${widget.visitsPerWeek <= 0})');
    print('  - workerCount: ${widget.workerCount} (is <= 0: ${widget.workerCount <= 0})');
    
    if (widget.selectedNationality.isEmpty ||
        widget.contractDuration <= 0 ||
        widget.selectedTime.isEmpty ||
        widget.visitDuration.isEmpty ||
        widget.visitsPerWeek <= 0 ||
        widget.workerCount <= 0) {
      print('❌ DEBUG: Missing required fields, exiting calculation');
      return;
    }

    print('✅ DEBUG: All required fields are present, proceeding with calculation');
    
    setState(() {
      _isCalculatingPrice = true;
    });
    print('🔄 DEBUG: Set _isCalculatingPrice to true');

    try {
      // Extract duration from visit duration string (e.g., "4 hours" -> 4)
      print('🔍 DEBUG: Extracting duration from visitDuration: "${widget.visitDuration}"');
      final durationMatch = RegExp(r'(\d+)').firstMatch(widget.visitDuration);
      final duration = durationMatch != null ? int.parse(durationMatch.group(1)!) : 4;
      print('🔍 DEBUG: Extracted duration: $duration hours (match found: ${durationMatch != null})');

      // Use contractDuration directly (it's already in weeks)
      final numberOfWeeks = widget.contractDuration;
      print('🔍 DEBUG: Contract duration in weeks: $numberOfWeeks');

      // Use visitsPerWeek directly (it's already the number of visits)
      final numberOfVisits = widget.visitsPerWeek;
      print('🔍 DEBUG: Number of visits per week: $numberOfVisits');

      // Get group code from nationality
      print('🔍 DEBUG: Fetching group code for nationality: "${widget.selectedNationality}"');
      String groupCode = '2'; // Default fallback
      print('🔍 DEBUG: Default groupCode set to: $groupCode');
      
      try {
        print('🌐 DEBUG: Calling ApiService.fetchCountryGroups with serviceId: ${widget.serviceId}');
        final countryGroups = await ApiService.fetchCountryGroups(serviceId: widget.serviceId);
        print('🔍 DEBUG: Received ${countryGroups.length} country groups from API');
        
        final matchingGroup = countryGroups.firstWhere(
          (group) {
            final groupName = group['group_name']?.toString().toLowerCase();
            final selectedNat = widget.selectedNationality.toLowerCase();
            print('🔍 DEBUG: Comparing group_name "$groupName" with selected "$selectedNat"');
            return groupName == selectedNat;
          },
          orElse: () {
            print('🔍 DEBUG: No matching group found, using default');
            return {'group_code': '2'};
          },
        );
        groupCode = matchingGroup['group_code'].toString();
        print('✅ DEBUG: Final groupCode: $groupCode');
      } catch (e) {
        print('❌ DEBUG: Error fetching group code: $e');
        print('🔍 DEBUG: Using default groupCode: $groupCode');
      }

      // Get shift ID from selected time
      print('🔍 DEBUG: Fetching shift ID for selected time: "${widget.selectedTime}"');
      int shiftId = 1; // Default fallback
      print('🔍 DEBUG: Default shiftId set to: $shiftId');
      
      try {
        print('🌐 DEBUG: Calling ApiService.fetchServiceShifts with serviceId: ${widget.serviceId}');
        final serviceShifts = await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
        print('🔍 DEBUG: Received ${serviceShifts.length} service shifts from API');
        
        final matchingShift = serviceShifts.firstWhere(
          (shift) {
            final serviceShifts = shift['service_shifts']?.toString().toLowerCase();
            final selectedTime = widget.selectedTime.toLowerCase();
            print('🔍 DEBUG: Comparing service_shifts "$serviceShifts" with selected "$selectedTime"');
            return serviceShifts == selectedTime;
          },
          orElse: () {
            print('🔍 DEBUG: No matching shift found, using default');
            return {'shift_id': 1};
          },
        );
        shiftId = int.parse(matchingShift['id'].toString());
        print('✅ DEBUG: Final shiftId: $shiftId');
      } catch (e) {
        print('❌ DEBUG: Error fetching shift ID: $e');
        print('🔍 DEBUG: Using default shiftId: $shiftId');
      }

      // Call the calculate price API
      print('🌐 DEBUG: Calling ApiService.calculatePackagePrice with parameters:');
      print('  - serviceId: ${widget.serviceId}');
      print('  - duration: $duration');
      print('  - groupCode: $groupCode');
      print('  - numberOfWeeks: $numberOfWeeks');
      print('  - numberOfVisits: $numberOfVisits');
      print('  - shiftId: $shiftId');
      print('  - numberOfWorkers: ${widget.workerCount}');
      
      final response = await ApiService.calculatePackagePrice(
        serviceId: widget.serviceId,
        duration: duration,
        groupCode: groupCode,
        numberOfWeeks: numberOfWeeks,
        numberOfVisits: numberOfVisits,
        shiftId: shiftId,
        numberOfWorkers: widget.workerCount,
      );

      print('🔍 DEBUG: API response received: $response');
      print('🔍 DEBUG: Response is null: ${response == null}');

      if (response != null) {
        final pricePerVisit = response['price_per_visit']?.toDouble() ?? 0.0;
        final totalPrice = response['total_price']?.toDouble() ?? 0.0;
        final finalPrice = response['final_price']?.toDouble() ?? 0.0; // Price with VAT
        final hourPrice = response['hour_price']?.toDouble() ?? 0.0;
        final priceVat = response['price_vat']?.toDouble() ?? 0.0;
        final totalVisits = response['total_visits']?.toDouble() ?? 0.0;
        
        print('🔍 DEBUG: Extracted from response:');
        print('  - price_per_visit: $pricePerVisit (without VAT)');
        print('  - total_price: $totalPrice (without VAT)');
        print('  - final_price: $finalPrice (with VAT)');
        print('  - hour_price: $hourPrice');
        print('  - price_vat: $priceVat');
        print('  - total_visits: $totalVisits');
        
        // Calculate VAT amount and final price per visit
        final vatAmount = priceVat;
        final finalPricePerVisit = finalPrice; // This is already the price with VAT per visit
        
        print('🔍 DEBUG: Calculated VAT values:');
        print('  - VAT amount per visit: $vatAmount');
        print('  - Final price per visit (with VAT): $finalPricePerVisit');
        print('  - Hour price: $hourPrice');
        print('  - Price VAT from API: $priceVat'); 
        
        setState(() {
          _apiPricePerVisit = pricePerVisit; // Without VAT
          _apiTotalPrice = totalPrice; // Without VAT
          _apiFinalPricePerVisit = finalPricePerVisit; // With VAT
          _vatAmount = vatAmount; // VAT amount per visit
          _apiHourPrice = hourPrice;
          _apiPriceVat = priceVat;
          _apiTotalVisits = totalVisits.toInt(); 
          _isCalculatingPrice = false;
        });
        
        print('✅ DEBUG: Updated state with new prices');
        print('🔄 DEBUG: Set _isCalculatingPrice to false');

        if (widget.onPricePerVisitChanged != null) {
          widget.onPricePerVisitChanged!(_apiPricePerVisit); // Pass price with VAT
          print('✅ DEBUG: Called onPricePerVisitChanged callback with: $_apiPricePerVisit');
        }

        if (widget.onHourPriceChanged != null) {
          widget.onHourPriceChanged!(_apiHourPrice);
          print('✅ DEBUG: Called onHourPriceChanged callback with: $_apiHourPrice');
        }

        if (widget.onPriceVatChanged != null) {
          widget.onPriceVatChanged!(_apiPriceVat);
          print('✅ DEBUG: Called onPriceVatChanged callback with: $_apiPriceVat');
        }

        // Re-validate coupon if it was previously applied
        if (_isCouponApplied && _isCouponValid && _couponCode.isNotEmpty) {
          print('🔄 DEBUG: Re-validating coupon after price calculation');
          await _validateCouponCode();
        }

        // Update parent with the new price per visit if callback is available
        print('🔍 DEBUG: Checking callback and selected dates:');
        print('  - onTotalPriceChanged is null: ${widget.onTotalPriceChanged == null}');
        print('  - _internalSelectedDates.length: ${_internalSelectedDates.length}');
        
        if (widget.onTotalPriceChanged != null && _internalSelectedDates.isNotEmpty) {
          // Use final price per visit (with VAT) for calculation
          double calculatedTotal = _internalSelectedDates.length * _apiFinalPricePerVisit;
          print('🔍 DEBUG: Calculated total with VAT: ${_internalSelectedDates.length} dates × $_apiFinalPricePerVisit = $calculatedTotal');
          
          widget.onTotalPriceChanged!(calculatedTotal);
          print('✅ DEBUG: Called onTotalPriceChanged callback with: $calculatedTotal');
          
          setState(() {
            _calculatedTotalPrice = calculatedTotal;
          });
          print('✅ DEBUG: Updated _calculatedTotalPrice to: $calculatedTotal');
        } else {
          print('⏭️ DEBUG: Skipping callback - either callback is null or no dates selected');
        }
      } else {
        print('❌ DEBUG: API returned null response, throwing exception');
        throw Exception('API returned null response');
      }
    } catch (e) {
      print('❌ DEBUG: Exception caught in _calculatePriceFromAPI: $e');
      print('🔍 DEBUG: Exception type: ${e.runtimeType}');
      
      setState(() {
        _isCalculatingPrice = false;
        // Fallback to widget's pricePerVisit if API fails
        _apiPricePerVisit = widget.pricePerVisit;
        _apiFinalPricePerVisit = widget.pricePerVisit; // Assume no VAT in fallback
        _vatAmount = 0.0;
      });
      
      print('🔄 DEBUG: Set _isCalculatingPrice to false');
      print('🔄 DEBUG: Fallback to widget.pricePerVisit: ${widget.pricePerVisit}');
      print('✅ DEBUG: Updated prices to fallback values');
    }
    
    print('🏁 DEBUG: _calculatePriceFromAPI method completed');
  }


Future<bool> _validateWorkers() async {
  print('🔍 [_validateWorkers] Starting worker validation...');
  
  // Check if all required fields are selected
  if (!_isValidDateSelection()) {
    print('❌ [_validateWorkers] Invalid date selection, skipping validation');
    return false;
  }

  setState(() {
    _isValidatingWorkers = true;
  });
  

  try {
    // Get shift ID from selected time
    int shiftId = 1; // Default fallback
    try {
      final serviceShifts = await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
      final matchingShift = serviceShifts.firstWhere(
        (shift) => shift['service_shifts']?.toString().toLowerCase() == widget.selectedTime.toLowerCase(),
        orElse: () => {'id': 1},
      );
      shiftId = int.parse(matchingShift['id'].toString());
    } catch (e) {
      print('❌ [_validateWorkers] Error fetching shift ID: $e');
    }

    // Get nationality ID (group code) from selected nationality
    String nationalityId = '2'; // Default fallback
    try {
      final countryGroups = await ApiService.fetchCountryGroups(serviceId: widget.serviceId);
      final matchingGroup = countryGroups.firstWhere(
        (group) => group['group_name']?.toString().toLowerCase() == widget.selectedNationality.toLowerCase(),
        orElse: () => {'group_code': '2'},
      );
      nationalityId = matchingGroup['group_code'].toString();
    } catch (e) {
      print('❌ [_validateWorkers] Error fetching nationality ID: $e');
    }

    // Get start and end dates from selected dates
    if (_internalSelectedDates.isEmpty) {
      print('❌ [_validateWorkers] No dates selected');
      return false;
    }

    final startDate = _internalSelectedDates.first;
    final endDate = _internalSelectedDates.last;

    // Convert selected dates to appointment dates format
    final appointmentDates = _internalSelectedDates
        .map((date) => DateFormat('MM-dd-yyyy').format(date))
        .toList();

    // Get address details - you might need to adjust these based on your address model
    String cityCode = '1'; // Default
    String districtId = '18'; // Default
    
    if (widget.selectedAddress != null) {
      // Adjust these based on your Address model structure
      cityCode = widget.selectedAddress!.cityCode.toString();
      districtId = widget.selectedAddress!.districtCode;
    }

    print('🔍 [_validateWorkers] Validation parameters:');
    print('  - positionId: ${widget.professionId}');
    print('  - nationalityId: $nationalityId');
    print('  - numWorkers: ${widget.workerCount}');
    print('  - startDate: ${DateFormat('MM-dd-yyyy').format(startDate)}');
    print('  - endDate: ${DateFormat('MM-dd-yyyy').format(endDate)}');
    print('  - shiftId: $shiftId');
    print('  - cityCode: $cityCode');
    print('  - districtId: $districtId');
    print('  - appointmentDates: $appointmentDates');

    // Call the validation API
    final validationResult = await ApiService.validateWorkersHourly(
      positionId: widget.professionId,
      nationalityId: nationalityId,
      numWorkers: widget.workerCount,
      startDate: startDate,
      endDate: endDate,
      shiftId: shiftId,
      cityCode: cityCode,
      districtId: districtId,
      appointmentDates: appointmentDates,
    );

    print('📥 [_validateWorkers] Validation result: $validationResult');

    if (validationResult != null) {
      final isValid = validationResult['valid'] == true;
      final availableWorkers = validationResult['available_workers'] ?? 0;
      final workerIds = (validationResult['worker_ids'] as List?)?.cast<int>() ?? [];
      final message = validationResult['message'] ?? "No workers available for the selected time and dates. Please try different options.";

      print('✅ [_validateWorkers] Validation complete:');
      print('  - Valid: $isValid');
      print('  - Available workers: $availableWorkers');
      print('  - Worker IDs: $workerIds');

      if (isValid && availableWorkers > 0) {
        setState(() {
          _validatedWorkerIds = workerIds;
        });

        // Pass worker IDs back to parent
        if (widget.onWorkerIdsChanged != null) {
          widget.onWorkerIdsChanged!(workerIds);
        }

        return true;
      } else {
        // Show error message for no available workers
        _showValidationMessage(message);
        return false;
      }
    } else {
      print('❌ [_validateWorkers] Validation API returned null');
      return false;
    }
  } catch (e) {
    print('💥 [_validateWorkers] Error during validation: $e');
    _showValidationMessage('Error validating worker availability. Please try again.');
    return false;
  } finally {
    setState(() {
      _isValidatingWorkers = false;
    });
  }
}


  void _resetCalendarSelection() {
  setState(() {
    _internalSelectedDates.clear();
    _calculatedTotalPrice = 0.0;
    _showCalendar = false;
  });

  // Call the total price callback to update parent
  if (widget.onTotalPriceChanged != null) {
    widget.onTotalPriceChanged!(0.0);
  }
  
  // Reset the parent's selected days
  widget.onSelectedDaysChanged([]);
  
  // Reset selected dates in parent if callback exists
  if (widget.onSelectedDatesChanged != null) {
    widget.onSelectedDatesChanged!([]);
  }
}

  void _onDateSelectionComplete(List<DateTime> dates) {
  setState(() {
    _internalSelectedDates = dates;
    // Use API final price per visit (with VAT) instead of widget.pricePerVisit
    double priceToUse = _apiFinalPricePerVisit > 0 ? _apiFinalPricePerVisit : widget.pricePerVisit;
    _calculatedTotalPrice = dates.isNotEmpty ? dates.length * priceToUse : 0.0;
    _showCalendar = false;
  });

  // Convert dates to day names for the callback
  List<String> dayNames = dates.map((d) => DateFormat('EEEE').format(d)).toList();

  // Update parent component with selected days
  widget.onSelectedDaysChanged(dayNames);

  // Add this callback for selected dates
  if (widget.onSelectedDatesChanged != null) {
    widget.onSelectedDatesChanged!(dates);
  }

  // Also update parent with total price if callback is available
  if (widget.onTotalPriceChanged != null) {
    widget.onTotalPriceChanged!(_calculatedTotalPrice);
  }

  // Force rebuild to show bottom navigation immediately when dates are selected
  if (dates.isNotEmpty) {
    setState(() {
      // This additional setState ensures the bottom navigation appears
      // as soon as the first date is selected
    });
  }
}

Widget _buildCouponCodeField(AppLocalizations loc) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    bool canApplyCoupon = _apiPricePerVisit > 0 && _apiTotalPrice > 0 && _apiHourPrice > 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: canApplyCoupon ? Colors.grey.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canApplyCoupon ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
  alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
  child: Text(
            loc.couponCode,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: canApplyCoupon ? Color(0xFF091735) : const Color(0xFF768090),
            ),
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          ),
          ),
          
          SizedBox(height: 12),
          Row(
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: canApplyCoupon,
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  onChanged: canApplyCoupon ? (value) {
                    setState(() {
                      _couponCode = value;
                      _couponMessage = '';
                    });
                  } : null,
                  decoration: InputDecoration(
                    hintText: loc.enterCouponCode,
                    hintStyle: TextStyle(
                      color: canApplyCoupon ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: canApplyCoupon ? Colors.grey.shade300 : Colors.grey.shade400,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: canApplyCoupon ? Colors.grey.shade300 : Colors.grey.shade400,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: canApplyCoupon ? Color(0xFF1E3A8A) : Colors.grey.shade400,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    filled: true,
                    fillColor: canApplyCoupon ? Colors.white : Colors.grey.shade200,
                    suffixIcon: (_isCouponApplied && canApplyCoupon)
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: _removeCoupon,
                          )
                        : null,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: canApplyCoupon ? Colors.black : const Color(0xFF768090),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                height: 36,
                child: ElevatedButton(
                  onPressed: (canApplyCoupon && !_isValidatingCoupon) ? _validateCouponCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canApplyCoupon 
                        ? (_isCouponApplied ? Colors.green : Color(0xFF1E3A8A))
                        : Colors.grey.shade400,
                    disabledBackgroundColor: Color(0xFF768090),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    minimumSize: Size(80, 48),
                  ),
                  child: _isValidatingCoupon
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isCouponApplied ? loc.applied : loc.apply,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_couponMessage.isNotEmpty && canApplyCoupon) ...[
            SizedBox(height: 8),
            Row(
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              children: [
                Icon(
                  _isCouponValid ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _isCouponValid ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _couponMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCouponValid ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// Add this method to build the Select Date field
  Widget _buildSelectDateField(AppLocalizations loc) {
  bool hasSelectedDates = _internalSelectedDates.isNotEmpty;
  bool canSelectDates = widget.contractDuration > 0 && widget.visitsPerWeek > 0;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';

  return Container(
    margin: EdgeInsets.only(bottom: 15),
    child: Column(
      children: [
        if (!canSelectDates)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              loc.dialogForPrevious,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        // Date selection trigger field
        GestureDetector(
          onTap: canSelectDates
              ? () {
                  setState(() {
                    _showCalendar = !_showCalendar;
                  });
                }
              : () {
                  _showValidationMessage(
                      loc.dialogForPrevious);
                },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              children: [
                Expanded(
                  child: Text(
                    loc.date,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF768090),
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
                if (hasSelectedDates)
                  Text(
                    isArabic
                        ? (_internalSelectedDates.length == 1
                            ? 'تم اختيار تاريخ واحد'
                            : 'تم اختيار ${_internalSelectedDates.length} تواريخ')
                        : (_internalSelectedDates.length == 1
                            ? '1 date selected'
                            : '${_internalSelectedDates.length} dates selected'),
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF10295C),
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  )
                else
                  Text(
                    loc.tapToSelect,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF768090),
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                SizedBox(width: 4),
                Icon(
                    _showCalendar
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20),
              ],
            ),
          ),
        ),

        // Animated calendar container
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _showCalendar ? 650 : 0,
          curve: Curves.easeInOut,
          child: _showCalendar
              ? Container(
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomDateSelectionStep(
                      selectedDates: _internalSelectedDates,
                      onDatesChanged: (dates) {
                        setState(() {
                          _internalSelectedDates = dates;
                        });

                        // Convert dates to day names and update parent
                        List<String> dayNames = dates.map((d) => DateFormat('EEEE').format(d)).toList();
                        widget.onSelectedDaysChanged(dayNames);
                        
                        // Add this callback for selected dates
                        if (widget.onSelectedDatesChanged != null) {
                          widget.onSelectedDatesChanged!(dates);
                        }
                      },
                      onTotalPriceChanged: (price) {
                        setState(() {
                          _calculatedTotalPrice = price;
                        });

                        // Update parent with total price if callback is available
                        if (widget.onTotalPriceChanged != null) {
                          widget.onTotalPriceChanged!(_calculatedTotalPrice);
                        }
                      },
                      onNextPressed: null,
                      // Pass the correct price based on coupon status
                      pricePerVisit: _isCouponApplied && _isCouponValid 
                          ? _apiPricePerVisit  // Use discounted price when coupon is applied
                          : (_apiPricePerVisit > 0 ? _apiPricePerVisit : widget.pricePerVisit),
                      contractDuration: widget.contractDuration,
                      visitsPerWeek: widget.visitsPerWeek,
                      maxSelectableDates: _getMaxSelectableDates(),
                      showBottomNavigation: false,
                      vatAmount: _isCouponApplied && _isCouponValid ? 0.0 : _vatAmount, // No additional VAT when coupon is applied
                      professionId: widget.professionId,
                      workerCount: widget.workerCount,
                    )
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    ),
  );
}

  bool _isValidDateSelection() {
    // Check if all required fields are selected
    if (widget.contractDuration <= 0 || 
        widget.visitsPerWeek <= 0 ||
        widget.selectedNationality.isEmpty ||
        widget.selectedTime.isEmpty ||
        widget.visitDuration.isEmpty ||
        widget.workerCount <= 0) {
      return false;
    }

    // Check if dates are actually selected
    if (_internalSelectedDates.isEmpty) {
      return false;
    }

    // Calculate the expected total number of visits
    int expectedTotalVisits = _getMaxSelectableDates();
    
    // Validate that the user has selected exactly the expected number of dates
    bool hasCorrectDateCount = _internalSelectedDates.length == expectedTotalVisits;
    
    // Also ensure the total price is calculated
    bool hasTotalPrice = _calculatedTotalPrice > 0;
    
    return hasCorrectDateCount && hasTotalPrice;
  }



// Add this method to calculate max selectable dates
  int _getMaxSelectableDates() {
    // Use contract duration (weeks) and visits per week directly
    int durationInWeeks = widget.contractDuration > 0 ? widget.contractDuration : 1;
    int visitsPerWeekCount = widget.visitsPerWeek > 0 ? widget.visitsPerWeek : 1;

    int maxDates = durationInWeeks * visitsPerWeekCount;
    
    // Optional: Add a reasonable limit for very long contracts
    // Uncomment the line below if you want to limit to 365 dates maximum
    // maxDates = maxDates > 365 ? 365 : maxDates;
    
    return maxDates;
  }


  Future<void> _loadCountryGroups() async {
    setState(() {
      isLoadingNationalities = true;
    });

    try {
      final response =
          await ApiService.fetchCountryGroups(serviceId: widget.serviceId);
      if (response is List && response.isNotEmpty) {
        setState(() {
          nationalities = response
              .map((item) => item['group_name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          isLoadingNationalities = false;
        });
      }
    } catch (e) {
      print('Error loading country groups: $e');
      setState(() {
        isLoadingNationalities = false;
      });
      // Keep default nationalities on error
    }
  }

  Future<void> _loadServiceShifts() async {
    setState(() {
      isLoadingTimeSlots = true;
    });

    try {
      final response =
          await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
      if (response is List && response.isNotEmpty) {
        setState(() {
          timeSlots = response
              .map((item) => item['service_shifts']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          isLoadingTimeSlots = false;
        });
      }
    } catch (e) {
      print('Error loading service shifts: $e');
      setState(() {
        isLoadingTimeSlots = false;
      });
      // Keep default time slots on error
    }
  }

  int _getMaxSelectableDays() {
    // Use the visits per week value directly
    return widget.visitsPerWeek > 0 ? widget.visitsPerWeek : 1;
  }

  Widget _buildDaySelectionWidget() {
    final maxSelectable = _getMaxSelectableDays();
    final selectedCount = widget.selectedDays.length;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Please select ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF091735),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text:
                        maxSelectable == 1 ? 'one day' : '$maxSelectable days',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isSelected = widget.selectedDays.contains(day);
              final canSelect = selectedCount < maxSelectable || isSelected;

              return GestureDetector(
                onTap: canSelect ? () => _toggleDaySelection(day) : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Color(0xFF1E3A8A)
                          : canSelect
                              ? Colors.grey[300]!
                              : Colors.grey[200]!,
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    color: isSelected
                        ? Color(0xFF1E3A8A).withOpacity(0.1)
                        : canSelect
                            ? Colors.white
                            : Colors.grey[50],
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Color(0xFF1E3A8A)
                            : canSelect
                                ? Colors.grey[700]
                                : Colors.grey[400],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleDaySelection(String day) {
    List<String> newSelectedDays = List.from(widget.selectedDays);

    if (newSelectedDays.contains(day)) {
      newSelectedDays.remove(day);
    } else {
      final maxSelectable = _getMaxSelectableDays();
      if (newSelectedDays.length < maxSelectable) {
        newSelectedDays.add(day);
      }
    }

    widget.onSelectedDaysChanged(newSelectedDays);

    // Auto-navigate to date selection when required days are selected
    final maxSelectable = _getMaxSelectableDays();
    if (newSelectedDays.length == maxSelectable &&
        widget.onSelectDatePressed != null) {
      // Add a small delay to show the selection state before navigating
      Future.delayed(Duration(milliseconds: 300), () {
        widget.onSelectDatePressed!();
      });
    }
  }

  Widget _buildDropdownField(
  String label,
  String value,
  List<String> options,
  Function(String) onChanged, {
  bool isEnabled = true,
  String? customTitle,
  bool isLoading = false,
  required AppLocalizations loc,
}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  bool hasValidValue = value.isNotEmpty && options.contains(value);

  return Container(
    margin: EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Label
        Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 8),
        
        // Dropdown Container
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: isEnabled ? Colors.white : Colors.grey[100],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text(
                loc.select,
                style: TextStyle(
                  color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              value: hasValidValue ? value : null,
              items: options.map((String option) {
  return DropdownMenuItem<String>(
    value: option,
    child: Align(
      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
      option,
      style: TextStyle(
        fontSize: 16,
        color: isEnabled ? Colors.black : Colors.grey[400],
      ),
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
    ),
    ),
  );
}).toList(),
              onChanged: isEnabled && !isLoading ? (String? selectedValue) {
                if (selectedValue != null) {
                  onChanged(selectedValue);
                }
              } : null,
              icon: isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  )
                : Icon(
                    Icons.keyboard_arrow_down,
                    color: isEnabled ? Colors.grey[600] : Colors.grey[400]
                  ),
              isExpanded: true,
              dropdownColor: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


Future<void> _handleDonePressed() async {
  if (!_isValidDateSelection()) {
    _showValidationMessage('Please complete all required fields and select dates.');
    return;
  }

  // Validate workers before proceeding
  final isValidWorkers = await _validateWorkers();
  
  if (isValidWorkers && widget.onDonePressed != null) {
    widget.onDonePressed!();
  }
}

  Widget _buildVisitDurationField(AppLocalizations loc) {
  // Always show as read-only field since duration is auto-selected
  bool hasValidDuration = widget.visitDuration.isNotEmpty;

  return Container(
    margin: EdgeInsets.only(bottom: 15),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!, width: 1.5),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            loc.durationOfVisit,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF768090),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isLoadingVisitDurations)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          )
        else if (hasValidDuration)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.visitDuration.replaceAll(RegExp(r'\s*hours?'), '').replaceAll(RegExp(r'\s*ساعات'), ''),
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF10295C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6),
              Text(
                widget.visitDuration.contains('ساعات') ? 'ساعات' : 'Hours',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF10295C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    ),
  );
}

  Widget _buildWorkerCountField(AppLocalizations loc) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.professionals,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF768090),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Worker count circles
              for (int i = 1; i <= 4; i++)
                GestureDetector(
                  onTap: () {
                    widget.onWorkerCountChanged(i);
                    _resetDependentFields('workerCount');
                    _calculatePriceFromAPI();
                    // Recalculate total price if dates are selected
                    if (_internalSelectedDates.isNotEmpty &&
                        widget.onTotalPriceChanged != null) {
                      _calculatedTotalPrice =
                          _internalSelectedDates.length * widget.pricePerVisit;
                      widget.onTotalPriceChanged!(_calculatedTotalPrice);
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: EdgeInsets.only(right: i < 4 ? 16 : 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.workerCount == i
                          ? const Color(0xFF10295C)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.workerCount == i
                            ? const Color(0xFF10295C)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.workerCount == i
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showValidationMessage(String message) {
  if (_isSnackBarShowing) return; // Prevent multiple snackbars
  
  _isSnackBarShowing = true;
  
  FlashyFlushbar(
    leadingWidget: const Icon(
      Icons.info_outline,
      color: Colors.white,
      size: 24,
    ),
    message: message,
    duration: const Duration(seconds: 2),
    trailingWidget: IconButton(
      icon: const Icon(
        Icons.close,
        color: Colors.white,
        size: 20,
      ),
      onPressed: () {
        FlashyFlushbar.cancel();
        _isSnackBarShowing = false;
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
  
  // Reset the flag after the duration + a small buffer
  Future.delayed(Duration(seconds: 3), () {
    _isSnackBarShowing = false;
  });
}

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  return Directionality(
  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
  child: Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Service Title and Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isCustomBooking
                                    ? loc.designYourCard
                                    : '1 weekly visit:Cleaning Visit',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF091735),
                                ),
                              ),
                              SizedBox(height: 8),
                              if (!widget.isCustomBooking &&
                                  widget.discountPercentage != null &&
                                  widget.discountPercentage! > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Get ${widget.discountPercentage!.toInt()}% off',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildCouponCodeField(loc),

                    SizedBox(height: 20),

                    // Form Fields
                    _buildDropdownField(
                      loc.nationality,
                      widget.selectedNationality,
                      nationalities,
                      (value) {
                        if (widget.onNationalityChanged != null) {
                          widget.onNationalityChanged!(value);
                          _resetDependentFields('nationality'); // Add this line
                          _calculatePriceFromAPI();
                        }
                      },
                      isEnabled: widget.isCustomBooking && widget.onNationalityChanged != null,
                      customTitle: loc.selectNationality,
                      isLoading: isLoadingNationalities,
                      loc: loc
                    ),

                    _buildWorkerCountField(loc),

                    _buildDropdownField(
                      loc.contractDuration,
                      widget.contractDuration > 0 
                          ? contractDurations.firstWhere(
                              (item) => item['weeks'] == widget.contractDuration,
                              orElse: () => {'label': 'Unknown'}
                            )['label'] ?? 'Unknown'
                          : '',
                      contractDurations.map((item) => item['label'] as String).toList(),
                      (value) {
                        // Find the selected item and get its weeks value
                        final selectedItem = contractDurations.firstWhere(
                          (item) => item['label'] == value,
                          orElse: () => {'weeks': 0}
                        );
                        final weeks = selectedItem['weeks'] as int;
                        widget.onContractDurationChanged(weeks);
                        _resetDependentFields('contractDuration');
                        if (widget.isCustomBooking) {
                          _calculatePriceFromAPI();
                        }
                      },
                      customTitle: loc.selectContractDuration,
                      isLoading: isLoadingContractDurations,
                      loc: loc,
                    ),

                    _buildDropdownField(
                      loc.time,
                      widget.selectedTime,
                      timeSlots,
                      (value) {
                        if (widget.onTimeChanged != null) {
                          widget.onTimeChanged!(value);
                          _resetDependentFields('time'); // Add this line
                          _calculatePriceFromAPI();
                        }
                      },
                      isEnabled: widget.isCustomBooking && widget.onTimeChanged != null,
                      customTitle: loc.selectTimeSlot,
                      isLoading: isLoadingTimeSlots,
                      loc: loc,
                    ),


                    _buildVisitDurationField(loc),

                    _buildDropdownField(
                      loc.visitsWeeksNumber,
                      widget.visitsPerWeek > 0
                          ? hourlyVisits.firstWhere(
                              (item) => item['visits_number'] == widget.visitsPerWeek,
                              orElse: () => {'label': 'Unknown'}
                            )['label'] ?? 'Unknown'
                          : '',
                      hourlyVisits.map((item) => item['label'] as String).toList(),
                      (value) async {
                        // Find the selected item and get its visits_number value
                        final selectedItem = hourlyVisits.firstWhere(
                          (item) => item['label'] == value,
                          orElse: () => {'visits_number': 0}
                        );
                        final visitsNumber = selectedItem['visits_number'] as int;
                        widget.onVisitsPerWeekChanged(visitsNumber);
                        _resetCalendarSelection();
                        
                        await Future.delayed(Duration(milliseconds: 100));
                        
                        if (widget.isCustomBooking) {
                          await _calculatePriceFromAPI();
                        }
                      },
                      customTitle: loc.selectVisitsPerWeek,
                      isLoading: isLoadingHourlyVisits,
                      loc: loc,
                    ),

                    // Day Selection Widget - Auto-navigates when complete
                    _buildSelectDateField(loc),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation (shown only when dates are selected)
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 45),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E49A0).withOpacity(0.15), // Blue tinted shadow
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, -5),
                ),
                BoxShadow(
                  color: Color(0xFF1E49A0).withOpacity(0.08), // Additional lighter blue shadow
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: Offset(0, -10),
                ),
              ],
            ),
              child: Row(
                children: [
                  SizedBox(width: 16),

                  // Price section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.totalIncVat,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(_calculatedTotalPrice > 0 && _internalSelectedDates.isNotEmpty) ? _calculatedTotalPrice.toStringAsFixed(2) : '0.0'} ${loc.currencyHourly}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF091735),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Done Button
                  Expanded(
                    flex: 10,
                    child: GestureDetector(
                      onTap: _isValidDateSelection() && !_isValidatingWorkers ? _handleDonePressed : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: (_isValidDateSelection() && !_isValidatingWorkers)
                              ? Color(0xFF10295C)
                              : Color(0xFF768090),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: _isValidatingWorkers
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  loc.done,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    ),
    );
  }
}