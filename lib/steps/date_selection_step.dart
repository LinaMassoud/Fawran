import 'package:fawran/providers/address_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:ui' as ui;

class DateSelectionStep extends ConsumerStatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final Function(List<String>)? onSelectedDaysChanged;
  final Function(List<int>)? onWorkerValidationSuccess;
  final Function(int?)? onPromotionIdChanged;
  final Function(String?)? onPromotionCodeChanged;
  final Function(double)? onPriceChanged;
  final VoidCallback? onNextPressed;
  final int maxSelectableDates;
  final List<String> selectedDays;
  final String contractDuration;
  final int workerCount;
  final double totalPrice;
  final bool isCustomBooking;
  final double pricePerVisit;
  final PackageModel? package;
  final int professionId;
  final Address? selectedAddress;

  const DateSelectionStep({
    Key? key,
    required this.selectedDates,
    this.selectedAddress,
    required this.onDatesChanged,
    this.onNextPressed,
    this.maxSelectableDates = 10,
    this.selectedDays = const [],
    required this.workerCount,
    this.contractDuration = '1 month',
    required this.totalPrice,
    this.isCustomBooking = false,
    this.pricePerVisit = 0.0,
    this.package,
    required this.professionId,
    this.onSelectedDaysChanged,
    this.onWorkerValidationSuccess,
    this.onPromotionCodeChanged,
    this.onPriceChanged,
    this.onPromotionIdChanged,
  }) : super(key: key);

  @override
  _DateSelectionStepState createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends ConsumerState<DateSelectionStep>  {
  late PageController _pageController;
  late DateTime _currentMonth;
  List<DateTime> _selectedDates = [];
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  DateTime? _userSelectedStartDate;
  int _totalAllowedVisits = 0;
  int _visitsPerWeekCount = 0;
  Map<String, int> _weeklyVisitCounts = {}; // Track visits per week
  bool _isSelectingStartDate = true;
  List<String> _localSelectedDays = [];
  bool _isSnackBarShowing = false;

  TextEditingController _couponController = TextEditingController();
bool _isCouponApplied = false;
double _discountedPrice = 0.0;
String _couponMessage = '';
bool _isValidatingCoupon = false;

 @override
void initState() {
  super.initState();
  _currentMonth = DateTime.now();
  _pageController = PageController();
  _selectedDates = List.from(widget.selectedDates);
  _localSelectedDays = List.from(widget.selectedDays);
  
  // Pre-fill coupon code if available from package and auto-apply
  if (widget.package?.promotionCode != null && widget.package!.promotionCode!.isNotEmpty) {
    _couponController.text = widget.package!.promotionCode!;
    // Auto-apply the promotion without validation since it's already applied in the package
    _isCouponApplied = true;
    _discountedPrice = widget.package!.finalPrice; // Use the already calculated final price
    _couponMessage = 'Promotion applied successfully!';
    // PASS THE PROMOTION ID FROM PACKAGE
    if (widget.package!.promotionId != null && widget.onPromotionIdChanged != null) {
      widget.onPromotionIdChanged!(widget.package!.promotionId!);
    }
    if (widget.onPromotionCodeChanged != null) {
    widget.onPromotionCodeChanged!(widget.package!.promotionCode!);
  }
  }
  
  _calculateContractDetails();
  _updateWeeklyVisitCounts();
}

  @override
void dispose() {
  _pageController.dispose();
  _couponController.dispose();
  super.dispose();
}

void _updatePromotionMessageLocalization() {
  if (widget.package?.promotionCode != null && 
      widget.package!.promotionCode!.isNotEmpty && 
      _isCouponApplied && 
      _couponMessage == 'Promotion applied successfully!') {
    setState(() {
      _couponMessage = AppLocalizations.of(context)!.promotionAppliedSuccessfully;
    });
  }
}



void _validateCouponCode() async {
  if (_couponController.text.trim().isEmpty) {
    setState(() {
      _isCouponApplied = false;
      _discountedPrice = 0.0;
      _couponMessage = '';
    });
    return;
  }

  // Check if this is the pre-applied promotion code from the package
  if (widget.package?.promotionCode != null && 
      _couponController.text.trim() == widget.package!.promotionCode!) {
    setState(() {
      _isCouponApplied = true;
      _discountedPrice = widget.package!.finalPrice;
      _couponMessage = AppLocalizations.of(context)!.promotionAppliedSuccessfully;
    });
    return;
  }

  if (widget.selectedAddress == null) {
    _showSnackBar('Please select an address first');
    return;
  }

  setState(() {
    _isValidatingCoupon = true;
    _couponMessage = '';
  });

  try {
    print('🌐 DEBUG: Calling ApiService.validatePromotion with parameters:');
    print('  - promotionCode: ${_couponController.text.trim()}');
    print('  - shiftId: ${widget.package!.serviceShift}');
    print('  - cityCode: ${widget.selectedAddress!.cityCode}');
    print('  - originalPrice: ${widget.package?.originalPrice}');
    print('  - hourPrice: ${widget.package?.hourPrice}');

    final result = await ApiService.validatePromotion(
      promotionCode: _couponController.text.trim(),
      shiftId: int.parse(widget.package!.serviceShift),
      cityCode: widget.selectedAddress!.cityCode,
      originalPrice: widget.package?.originalPrice ?? widget.totalPrice,
      hourPrice: widget.package?.hourPrice ?? 0.0,
    );

    setState(() {
      _isValidatingCoupon = false;
      
      if (result != null) {
        bool isValid = result['valid'] == true;
        String message = result['message']?.toString() ?? '';
        
        if (isValid) {
          _isCouponApplied = true;
          _discountedPrice = (result['final_price'] as num?)?.toDouble() ?? widget.totalPrice;
          _couponMessage = message;
          _showSnackBar('Coupon applied successfully!');

          // EXTRACT AND PASS PROMOTION ID
          int? promotionId = result['promotion_id'] as int?;
          if (promotionId != null && widget.onPromotionIdChanged != null) {
            widget.onPromotionIdChanged!(promotionId);
          }
          if (widget.onPromotionCodeChanged != null) {
          widget.onPromotionCodeChanged!(_couponController.text.trim());
        }
          if (widget.onPriceChanged != null) {
          widget.onPriceChanged!(_discountedPrice);
        }
        } else {
          _isCouponApplied = false;
          _discountedPrice = 0.0;
          _couponMessage = message.isNotEmpty ? message : 'Invalid coupon code';
          _showSnackBar(_couponMessage);

          if (widget.onPromotionIdChanged != null) {
            widget.onPromotionIdChanged!(null);
          }
          if (widget.onPriceChanged != null) {
          widget.onPriceChanged!(widget.package?.originalPrice ?? widget.totalPrice);
        }
        }
      } else {
        _isCouponApplied = false;
        _discountedPrice = 0.0;
        _couponMessage = 'Failed to validate coupon';
        _showSnackBar(_couponMessage);
        if (widget.onPriceChanged != null) {
        widget.onPriceChanged!(widget.package?.originalPrice ?? widget.totalPrice);
      }
      }
    });
  } catch (e) {
    setState(() {
      _isValidatingCoupon = false;
      _isCouponApplied = false;
      _discountedPrice = 0.0;
      _couponMessage = 'Error validating coupon';
    });
    _showSnackBar('Error validating coupon: ${e.toString()}');
    if (widget.onPromotionIdChanged != null) {
      widget.onPromotionIdChanged!(null);
    }
  }
}

void _removeCoupon() {
  setState(() {
    _couponController.clear();
    _isCouponApplied = false;
    _discountedPrice = 0.0;
    _couponMessage = '';
  });
  // Clear promotion ID when coupon is removed
  if (widget.onPromotionIdChanged != null) {
    widget.onPromotionIdChanged!(null);
  }
  if (widget.onPromotionCodeChanged != null) {
    widget.onPromotionCodeChanged!(null);
  }
  if (widget.onPriceChanged != null) {
    widget.onPriceChanged!(widget.package?.originalPrice ?? widget.totalPrice);
  }
}

Widget _buildCouponSection(AppLocalizations loc) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.couponCode,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF091735),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: loc.enterCouponCode,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  suffixIcon: _isCouponApplied
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: _removeCoupon,
                        )
                      : null,
                ),
                style: TextStyle(fontSize: 14),
                onChanged: (value) {
                // Reset validation state when text changes, but only if it's not the pre-applied promotion
                if (widget.package?.promotionCode == null || 
                    value.trim() != widget.package!.promotionCode!) {
                  if (_isCouponApplied || _couponMessage.isNotEmpty) {
                    setState(() {
                      _isCouponApplied = false;
                      _discountedPrice = 0.0;
                      _couponMessage = '';
                    });
                  }
                }
              },
              ),
            ),
            SizedBox(width: 12),
            Container(
              height: 36,
              child: ElevatedButton(
                onPressed: _isValidatingCoupon ? null : _validateCouponCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCouponApplied ? Colors.green : Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 25),
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
        if (_couponMessage.isNotEmpty) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isCouponApplied ? Icons.check_circle : Icons.error,
                size: 16,
                color: _isCouponApplied ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _couponMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isCouponApplied ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
List<String> _getLocalizedDays(AppLocalizations loc) {
  return [
    loc.sunday,
    loc.monday, 
    loc.tuesday,
    loc.wednesday,
    loc.thursday,
    loc.saturday
  ];
}

// Helper method to get day abbreviations for calendar header
List<String> _getDayAbbreviations(AppLocalizations loc) {
  return [
    loc.sundayShort,    // S
    loc.mondayShort,    // M
    loc.tuesdayShort,   // T
    loc.wednesdayShort, // W
    loc.thursdayShort,  // T
    loc.fridayShort,    // F
    loc.saturdayShort   // S
  ];
}

// Helper method to convert English day names to localized names
String _getLocalizedDayName(String englishDayName, AppLocalizations loc) {
  switch (englishDayName.toLowerCase()) {
    case 'sunday':
      return loc.sunday;
    case 'monday':
      return loc.monday;
    case 'tuesday':
      return loc.tuesday;
    case 'wednesday':
      return loc.wednesday;
    case 'thursday':
      return loc.thursday;
    case 'friday':
      return loc.friday;
    case 'saturday':
      return loc.saturday;
    default:
      return englishDayName;
  }
}

// Helper method to convert localized day names back to English for logic
String _getEnglishDayName(String localizedDayName, AppLocalizations loc) {
  if (localizedDayName == loc.sunday) return 'Sunday';
  if (localizedDayName == loc.monday) return 'Monday';
  if (localizedDayName == loc.tuesday) return 'Tuesday';
  if (localizedDayName == loc.wednesday) return 'Wednesday';
  if (localizedDayName == loc.thursday) return 'Thursday';
  if (localizedDayName == loc.friday) return 'Friday';
  if (localizedDayName == loc.saturday) return 'Saturday';
  return localizedDayName;
}

// Helper method to format numbers in Arabic if needed
String _formatNumber(int number, AppLocalizations loc) {
  if (Localizations.localeOf(context).languageCode == 'ar') {
    // Convert Western Arabic numerals to Eastern Arabic numerals
    const westernArabic = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const easternArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    String numberStr = number.toString();
    for (int i = 0; i < westernArabic.length; i++) {
      numberStr = numberStr.replaceAll(westernArabic[i], easternArabic[i]);
    }
    return numberStr;
  }
  return number.toString();
}

// Helper method to format dates in Arabic
String _formatDateForLocale(DateTime date, AppLocalizations loc) {
  if (Localizations.localeOf(context).languageCode == 'ar') {
    // Use Arabic date formatting
    final formatter = DateFormat('MMM dd, yyyy', 'ar');
    return formatter.format(date);
  }
  return DateFormat('MMM dd, yyyy').format(date);
}

// Helper method to format month year for calendar header
String _formatMonthYear(DateTime date, AppLocalizations loc) {
  if (Localizations.localeOf(context).languageCode == 'ar') {
    final formatter = DateFormat('MMMM yyyy', 'ar');
    return formatter.format(date);
  }
  return DateFormat('MMMM yyyy').format(date);
}
  void _calculateContractDetails() {
    // Get duration from package using noOfWeeks or fallback to widget parameter
    int durationInWeeks = 0;
    String contractDuration = '';

    if (widget.package?.noOfWeeks != null && widget.package!.noOfWeeks! > 0) {
      // Use noOfWeeks from package
      durationInWeeks = widget.package!.noOfWeeks!;
      contractDuration = '$durationInWeeks week${durationInWeeks > 1 ? 's' : ''}';
    } else if (widget.package?.noOfMonth != null && widget.package!.noOfMonth > 0) {
      // Fallback to noOfMonth if noOfWeeks is not available
      int months = widget.package!.noOfMonth;
      durationInWeeks = months * 4; // Approximate weeks in months
      contractDuration = '$months month${months > 1 ? 's' : ''}';
    } else {
      // Use widget parameter as final fallback
      contractDuration = widget.contractDuration;
      if (contractDuration.toLowerCase().contains('month')) {
        int months = int.tryParse(contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        durationInWeeks = months * 4; // Approximate weeks in months
      } else if (contractDuration.toLowerCase().contains('week')) {
        durationInWeeks = int.tryParse(contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      } else {
        durationInWeeks = 4; // Default to 4 weeks if unclear
      }
    }

    // Get visits per week from package or fallback to selected days
    _visitsPerWeekCount = widget.package?.visitsWeekly ?? widget.selectedDays.length;

    // Calculate total allowed visits
    _totalAllowedVisits = durationInWeeks * _visitsPerWeekCount;

    // Only set default dates if user hasn't selected a start date
    if (_userSelectedStartDate == null) {
      final today = DateTime.now();
      _contractStartDate = DateTime(today.year, today.month, today.day);
      _contractEndDate = _contractStartDate!.add(Duration(days: durationInWeeks * 7));
    } else {
      _contractStartDate = _userSelectedStartDate;
      _contractEndDate = _contractStartDate!.add(Duration(days: durationInWeeks * 7));
    }
  }

  void _updateWeeklyVisitCounts() {
    _weeklyVisitCounts.clear();
    for (DateTime date in _selectedDates) {
      String weekKey = _getWeekKey(date);
      _weeklyVisitCounts[weekKey] = (_weeklyVisitCounts[weekKey] ?? 0) + 1;
    }
  }

  String _getWeekKey(DateTime date) {
    // Get Monday of the week as the week identifier
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  bool _isWeekFull(DateTime date) {
    String weekKey = _getWeekKey(date);
    int currentWeekCount = _weeklyVisitCounts[weekKey] ?? 0;
    return currentWeekCount >= _visitsPerWeekCount;
  }

  // Convert day names to weekday numbers (1 = Monday, 7 = Sunday)
  int _dayNameToWeekday(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1;
    }
  }

  void _autoSelectDatesBasedOnDays([List<String>? selectedDays]) {
  List<String> daysToUse = selectedDays ?? widget.selectedDays;
  
  if (daysToUse.isEmpty || _userSelectedStartDate == null) {
    return;
  }

  setState(() {
    _selectedDates.clear();
    
    // Convert selected day names to weekday numbers
    List<int> selectedWeekdays = daysToUse.map(_dayNameToWeekday).toList();
    
    // Start from the user-selected start date
    DateTime currentDate = _userSelectedStartDate!;
    int visitsAdded = 0;
    
    // First, add the start date itself
    _selectedDates.add(currentDate);
    visitsAdded++;
    
    // Move to next day for the loop
    currentDate = currentDate.add(Duration(days: 1));
    
    // Loop through each day in the contract period
    while (currentDate.isBefore(_contractEndDate!) || currentDate.isAtSameMomentAs(_contractEndDate!)) {
      // Check if current date's weekday matches any selected days
      if (selectedWeekdays.contains(currentDate.weekday)) {
        // Skip Fridays
        if (currentDate.weekday != 5) {
          // Check if we haven't exceeded the total allowed visits
          if (visitsAdded < _totalAllowedVisits) {
            // Check if this week isn't already full
            String weekKey = _getWeekKey(currentDate);
            int weekCount = _selectedDates.where((date) => _getWeekKey(date) == weekKey).length;
            
            if (weekCount < _visitsPerWeekCount) {
              _selectedDates.add(currentDate);
              visitsAdded++;
            }
          }
        }
      }
      
      // Move to next day
      currentDate = currentDate.add(Duration(days: 1));
      
      // Break if we've reached the maximum visits
      if (visitsAdded >= _totalAllowedVisits) {
        break;
      }
    }
    
    _selectedDates.sort();
    _updateWeeklyVisitCounts();
  });
  
  widget.onDatesChanged(_selectedDates);
}


Future<void> _validateAndProceed() async {
  if (_selectedDates.isEmpty || _isSelectingStartDate || widget.selectedAddress == null) {
    _showSnackBar('Please complete all selections before proceeding');
    return;
  }

  try {
    // Show loading indicator
    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  },
);

    // Prepare appointment dates in MM-dd-yyyy format
    List<String> appointmentDates = _selectedDates
        .map((date) => DateFormat('MM-dd-yyyy').format(date))
        .toList();

    // Get start and end dates from selected dates
    DateTime startDate = _selectedDates.first;
    DateTime endDate = _selectedDates.last;

    // Call the validation API
    final validationResult = await ApiService.validateWorkersHourly(
      positionId: widget.professionId,
      nationalityId: widget.package!.groupCode,
      numWorkers: widget.package!.noOfEmployee,
      startDate: startDate,
      endDate: endDate,
      shiftId: int.parse(widget.package!.serviceShift),
      appointmentDates: appointmentDates,
      cityCode: widget.selectedAddress!.cityCode.toString(),
      districtId: widget.selectedAddress!.districtCode,
    );

    // Close loading dialog
    Navigator.of(context).pop();

    if (validationResult != null) {
      // Extract validation data from the new API response format
      bool isValid = validationResult['valid'] == true;
      int availableWorkers = validationResult['available_workers'] ?? 0;
      final message = validationResult['message'] ?? "No workers available for the selected time and dates. Please try different options.";
      List<int>? workerIds;
      
      // Extract worker_ids if present
      if (validationResult['worker_ids'] != null) {
        workerIds = List<int>.from(validationResult['worker_ids']);
      }
      
      if (isValid && availableWorkers >= widget.workerCount) {
        // Validation successful, proceed to next step
        print('✅ Worker validation successful. Available workers: $availableWorkers, Worker IDs: $workerIds');
        
        // Pass worker IDs back to parent widget if callback is provided
        // You'll need to add this callback to the widget constructor
        if (widget.onWorkerValidationSuccess != null && workerIds != null) {
          widget.onWorkerValidationSuccess!(workerIds);
        }
        
        if (widget.onNextPressed != null) {
          widget.onNextPressed!();
        }
      } else {
        // Validation failed - show specific error message
        String errorMessage;
        if (!isValid) {
          errorMessage = message;
        } else {
          errorMessage = 'Only $availableWorkers worker(s) available, but you need ${widget.workerCount}.';
        }
        _showSnackBar(errorMessage);
        print('❌ Worker validation failed: $errorMessage');
      }
    } else {
      // API returned null response
      _showSnackBar('Worker validation failed. Please try again.');
      print('❌ Worker validation API returned null response');
    }

  } catch (e) {
    // Close loading dialog if still open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    // Show error message
    _showSnackBar('Error validating workers: ${e.toString()}');
    print('💥 Worker validation error: $e');
  }
}

// Add this widget to build the day selection UI (like in your image)
Widget _buildDaySelectionWidget(AppLocalizations loc) {
  final days = _getLocalizedDays(loc); // Use localized days
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: loc.pleaseSelect,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF091735),
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: '${_formatNumber(_visitsPerWeekCount, loc)} ${_visitsPerWeekCount == 1 ? loc.day : loc.days}',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            // Convert localized day back to English for comparison with _localSelectedDays
            String englishDay = _getEnglishDayName(day, loc);
            bool isSelected = _localSelectedDays.contains(englishDay);
            bool isFriday = englishDay == 'Friday';
            
            return GestureDetector(
              onTap: isFriday ? null : () {
                _handleDayToggle(englishDay); // Still use English day internally
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFriday 
                      ? Colors.grey.shade100 
                      : isSelected 
                          ? Color(0xFF10295C) 
                          : Colors.white,
                  border: Border.all(
                    color: isFriday 
                        ? Colors.grey.shade300 
                        : isSelected 
                            ? Color(0xFF10295C) 
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day, // Display localized day name
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFriday 
                        ? Colors.grey.shade400 
                        : isSelected 
                            ? Colors.white 
                            : Color(0xFF091735),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text(
          _userSelectedStartDate != null 
              ? '${loc.startDate}: ${_formatDateForLocale(_userSelectedStartDate!, loc)}'
              : _localSelectedDays.isNotEmpty 
                  ? loc.startDateAutoSet
                  : loc.selectDaysFirst,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _userSelectedStartDate != null 
                ? Colors.green.shade700 
                : Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}

void _handleDayToggle(String day) {
  setState(() {
    if (_localSelectedDays.contains(day)) {
      _localSelectedDays.remove(day);
    } else {
      if (_localSelectedDays.length < _visitsPerWeekCount) {
        _localSelectedDays.add(day);
      } else {
        // Show snackbar with shake animation only if not already showing
        if (!_isSnackBarShowing) {
          _showSnackBarWithShake('You can only select $_visitsPerWeekCount days per week');
        }
        return;
      }
    }
  });
  
  // Update the parent widget with new selected days
  if (widget.onSelectedDaysChanged != null) {
    widget.onSelectedDaysChanged!(_localSelectedDays);
  }
  
  // Auto-select dates if we have days selected
  if (_localSelectedDays.isNotEmpty) {
    _setStartDateFromSelectedDays(_localSelectedDays);
  } else {
    // Reset if no days are selected
    _resetToStartDateSelection();
  }
}

// Add this method to handle day selection
void _onDaySelected(String day) {
  // This method should be called from parent widget
  // when user selects/deselects a day
  
  // After day selection is updated, find the first occurrence of selected days
  // and set it as start date, then auto-select remaining dates
  _setStartDateFromSelectedDays();
}

// Add this new method to find and set start date based on selected days:
void _setStartDateFromSelectedDays([List<String>? selectedDays]) {
  List<String> daysToUse = selectedDays ?? widget.selectedDays;
  
  if (daysToUse.isEmpty) {
    return;
  }

  // Convert selected day names to weekday numbers
  List<int> selectedWeekdays = daysToUse.map(_dayNameToWeekday).toList();
  
  // Find the first occurrence of any selected day from today onwards
  DateTime today = DateTime.now();
  DateTime searchDate = DateTime(today.year, today.month, today.day);
  DateTime? firstSelectedDate;
  
  // Search for up to 14 days to find the first matching day
  for (int i = 0; i < 14; i++) {
    DateTime checkDate = searchDate.add(Duration(days: i));
    // Skip Fridays
    if (checkDate.weekday != 5 && selectedWeekdays.contains(checkDate.weekday)) {
      firstSelectedDate = checkDate;
      break;
    }
  }
  
  if (firstSelectedDate != null) {
    setState(() {
      _userSelectedStartDate = firstSelectedDate;
      _isSelectingStartDate = false;
      _selectedDates.clear();
      _calculateContractDetails();
      
      // Auto-select all dates based on the selected days
      _autoSelectDatesBasedOnDays(daysToUse);
    });
  }
}

  void _selectDate(DateTime date) {
  setState(() {
    // If we have selected days, handle auto-generated dates differently
    if (widget.selectedDays.isNotEmpty && !_isSelectingStartDate) {
      // Allow changing the start date
      if (date == _userSelectedStartDate) {
        _showStartDateChangeDialog();
        return;
      }
      
      // Allow deselecting auto-generated dates
      if (_selectedDates.contains(date)) {
        _selectedDates.remove(date);
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        return;
      } else {
        // For adding new dates when days are selected, apply strict validation
        
        // Don't allow selecting Fridays
        if (date.weekday == 5) {
          return;
        }
        
        // Check if date is within contract period
        if (_contractStartDate != null && _contractEndDate != null) {
          if (date.isBefore(_contractStartDate!) || date.isAfter(_contractEndDate!)) {
            return;
          }
        }
        
        // Check if we've reached the total visit limit
        if (_selectedDates.length >= _totalAllowedVisits) {
          return;
        }
        
        // Check if the week is already full (dates will be disabled by _isDateSelectable)
        if (_isWeekFull(date)) {
          return; // Date should already be disabled, but just in case
        }
        
        // Add the manually selected date
        _selectedDates.add(date);
        _selectedDates.sort();
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        return;
      }
    }
    
    // Original logic for when no days are selected or still selecting start date
    if (_isSelectingStartDate) {
      // Don't allow Friday as start date
      if (date.weekday == 5) {
        return;
      }
      
      _userSelectedStartDate = date;
      _selectedDates.clear();
      _isSelectingStartDate = false;
      _calculateContractDetails();
      
      // Auto-select dates based on selected days after start date is chosen
      if (widget.selectedDays.isNotEmpty) {
        _autoSelectDatesBasedOnDays();
      } else {
        _selectedDates.add(date);
      }
      widget.onDatesChanged(_selectedDates);
      return;
    }

    // If clicking on the start date, allow user to change it
    if (date == _userSelectedStartDate) {
      _showStartDateChangeDialog();
      return;
    }

    // Don't allow selecting Fridays for regular visits
    if (date.weekday == 5) {
      _showSnackBar('Friday is a holiday and cannot be selected');
      return;
    }

    // Regular date selection for visits (only when no days are selected)
    if (_selectedDates.contains(date)) {
      _selectedDates.remove(date);
    } else {
      // Check if we've reached the total visit limit
      if (_selectedDates.length >= _totalAllowedVisits) {
        _showSnackBar('Maximum $_totalAllowedVisits visits allowed for this contract');
        return;
      }

      // FIX: Check week capacity BEFORE adding the date
      // Include ALL dates in the week count (including start date)
      String weekKey = _getWeekKey(date);
      int currentWeekCount = _selectedDates.where((selectedDate) => 
          _getWeekKey(selectedDate) == weekKey
      ).length;
      
      if (currentWeekCount >= _visitsPerWeekCount) {
        _showSnackBar('Maximum $_visitsPerWeekCount visits per week allowed');
        return;
      }

      _selectedDates.add(date);
    }
    _selectedDates.sort();
    _updateWeeklyVisitCounts();
    widget.onDatesChanged(_selectedDates);
  });
}

  void _showStartDateChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Start Date'),
          content: Text(
            'Do you want to change your start date? This will reset all your selected visit dates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetToStartDateSelection();
              },
              child: Text('Change Start Date'),
            ),
          ],
        );
      },
    );
  }

  void _resetToStartDateSelection() {
    setState(() {
      _isSelectingStartDate = true;
      _userSelectedStartDate = null;
      _selectedDates.clear();
      _contractStartDate = null;
      _contractEndDate = null;
      _weeklyVisitCounts.clear();
      _localSelectedDays.clear();
      _calculateContractDetails();
    });
    widget.onDatesChanged(_selectedDates);
    // Notify parent widget that selected days are cleared
  if (widget.onSelectedDaysChanged != null) {
    widget.onSelectedDaysChanged!(_localSelectedDays);
  }
  
  _showSnackBar('Please select days and start date');
  }

  bool _isDateAllowedForPackage(DateTime date) {
    // If it's a custom booking, allow any date
    if (widget.isCustomBooking) return true;

    // If we have selected days from the widget, use those
    if (widget.selectedDays.isNotEmpty) {
      final selectedWeekdays = widget.selectedDays.map(_dayNameToWeekday).toList();
      return selectedWeekdays.contains(date.weekday);
    }

    // If we have a package but no selected days, allow any weekday for now
    // This might need to be adjusted based on your business logic
    return true;
  }

  void _showSnackBar(String message) {
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

// Add this new method for showing snackbar with shake animation
void _showSnackBarWithShake(String message) {
  if (_isSnackBarShowing) {
    // Create a subtle shake animation for the existing snackbar
    // You can implement this by adding a key to your snackbar and animating it
    // For now, we'll just return to prevent multiple snackbars
    return;
  }
  
  _showSnackBar(message);
}

  bool _isDateSelectable(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  // ALWAYS disable Fridays - this is the first check to ensure no Friday can be selected
  if (date.weekday == 5) return false;

  // If selecting start date, only allow today or future dates (but not Fridays - already checked above)
  if (_isSelectingStartDate) {
    return dateOnly.isAfter(todayOnly) || dateOnly.isAtSameMomentAs(todayOnly);
  }

  // Start date is always selectable (for changing) - but not if it's Friday (already checked above)
  if (date == _userSelectedStartDate) {
    return true;
  }

  // Check if date is within contract period
  if (_contractStartDate != null && _contractEndDate != null) {
    if (dateOnly.isBefore(_contractStartDate!) || dateOnly.isAfter(_contractEndDate!)) {
      return false;
    }
  }

  // Check if date is already selected
  if (_selectedDates.contains(date)) {
    return true; // Allow deselection
  }

  // Check if we've reached the total visit limit
  if (_selectedDates.length >= _totalAllowedVisits) {
    return false;
  }

  // Check if the week is already full
  if (_isWeekFull(date)) {
    return false;
  }

  // Special handling for single visit per week: disable other dates in the same week as start date
  if (_visitsPerWeekCount == 1 && _userSelectedStartDate != null) {
    String dateWeekKey = _getWeekKey(date);
    String startDateWeekKey = _getWeekKey(_userSelectedStartDate!);
    
    // If this date is in the same week as the start date and it's not the start date itself
    if (dateWeekKey == startDateWeekKey && date != _userSelectedStartDate) {
      return false; // Disable other dates in the same week
    }
  }

  // For package bookings, check if date matches selected days
  if (!widget.isCustomBooking && !_isDateAllowedForPackage(date)) {
    return false;
  }

  return true;
}

  void _navigateToMonth(int monthOffset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + monthOffset);
    });

    // Calculate the page index for the new month
    final now = DateTime.now();
    final targetMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final currentMonth = DateTime(now.year, now.month);

    int monthDifference = (targetMonth.year - currentMonth.year) * 12 +
        (targetMonth.month - currentMonth.month);

    if (monthDifference >= 0 && monthDifference < 24) {
      _pageController.animateToPage(
        monthDifference,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCalendarGrid(DateTime month) {
  final loc = AppLocalizations.of(context)!;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final firstDayOfMonth = DateTime(month.year, month.month, 1);
  final startingWeekday = firstDayOfMonth.weekday % 7;

  List<Widget> dayWidgets = [];

  // Add empty containers for days before the first day of the month
  for (int i = 0; i < startingWeekday; i++) {
    dayWidgets.add(Container());
  }

  // Add day widgets
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(month.year, month.month, day);
    final isSelected = _selectedDates.contains(date);
    final isSelectable = _isDateSelectable(date);
    final isWeekFull = _isWeekFull(date) && !isSelected;
    final isOutsideContract = !_isSelectingStartDate &&
        _contractStartDate != null &&
        _contractEndDate != null &&
        (date.isBefore(_contractStartDate!) || date.isAfter(_contractEndDate!));
    final isStartDate = date == _userSelectedStartDate;
    final isFriday = date.weekday == 5;

    Color backgroundColor = Colors.transparent;
    Color textColor = Color(0xFF091735);

    if (isSelected) {
      if (isStartDate) {
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
      } else {
        backgroundColor = Color(0xFF1E3A8A);
        textColor = Colors.white;
      }
    } else if (!isSelectable) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey;
    }

    dayWidgets.add(
      GestureDetector(
        onTap: isSelectable ? () => _selectDate(date) : null,
        child: Container(
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: isStartDate ? Colors.green : Color(0xFF1E3A8A), 
                    width: 2
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day number - use localized formatting
              Text(
                _formatNumber(day, loc), // Use localized number formatting
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              // Conditional content based on priority
              if (isStartDate && !_isSelectingStartDate) ...[
                // Highest priority: Start date indicator
                Text(
                  loc.start ?? 'START', // Use localized "START" text
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ] else if (isFriday && !isSelected) ...[
                
              ] else if (isWeekFull && !isSelected && !_isSelectingStartDate) ...[
                // Second priority: Week full indicator
                
              ] else if (!widget.isCustomBooking &&
                  !_isDateAllowedForPackage(date) &&
                  !isOutsideContract &&
                  isSelectable) ...[
                // For package bookings: show if day doesn't match selected days
                Text(
                  loc.notAvailable ?? 'N/A', // Use localized "N/A" text
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Calculate the number of rows needed
  int totalCells = startingWeekday + daysInMonth;
  int numberOfRows = (totalCells / 7).ceil();

  return GridView.count(
    crossAxisCount: 7,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    childAspectRatio: 1.0,
    mainAxisSpacing: 1,
    crossAxisSpacing: 1,
    padding: EdgeInsets.zero,
    children: dayWidgets,
  );
}

  Widget _buildMonthHeader(DateTime month) {
  final loc = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final canNavigateLeft = month.isAfter(DateTime(now.year, now.month));
  final canNavigateRight = month.isBefore(DateTime(now.year + 2, now.month));

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: canNavigateLeft ? () => _navigateToMonth(-1) : null,
          icon: Icon(
            Icons.chevron_left,
            color: canNavigateLeft ? Color(0xFF091735) : Colors.grey,
            size: 28,
          ),
        ),
        Expanded(
          child: Text(
            _formatMonthYear(month, loc), // Use localized month/year formatting
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF091735),
            ),
          ),
        ),
        IconButton(
          onPressed: canNavigateRight ? () => _navigateToMonth(1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: canNavigateRight ? Color(0xFF091735) : Colors.grey,
            size: 28,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMonthView(DateTime month) {
  final loc = AppLocalizations.of(context)!;
  
  return Column(
    children: [
      _buildMonthHeader(month),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _getDayAbbreviations(loc).map((day) { // Use localized abbreviations
            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF091735),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildCalendarGrid(month),
        ),
      ),
    ],
  );
}

  String _getContractDurationText() {
    if (widget.package?.noOfWeeks != null && widget.package!.noOfWeeks! > 0) {
      int weeks = widget.package!.noOfWeeks!;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else if (widget.package?.noOfMonth != null && widget.package!.noOfMonth > 0) {
      int months = widget.package!.noOfMonth;
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return widget.contractDuration;
    }
  }


@override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);
    final isArabic = locale.languageCode == 'ar';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _updatePromotionMessageLocalization();
    }
  });
  return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child:  Column(
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          loc.selectDate,
          style: TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF091735),
                  ),
        ),
      ),
      // Wrap the main content in Expanded and SingleChildScrollView
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ADD THIS LINE: Coupon section
              _buildCouponSection(loc),
              
              // Day selection widget
              _buildDaySelectionWidget(loc),
              // Calendar container with fixed height
              Container(
                height: 450,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month + index);
                    });
                  },
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    final month = DateTime(DateTime.now().year, DateTime.now().month + index);
                    return _buildMonthView(month);
                  },
                ),
              ),
              // Add some bottom padding to ensure content doesn't get cut off
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // Bottom section remains fixed - UPDATE THE PRICE DISPLAY
      Container(
  padding: EdgeInsets.fromLTRB(20, 20, 20, 45), // Added more bottom padding
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
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _formatNumber(_selectedDates.length, loc), // Use localized number
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF091735),
            ),
          ),
        ),
      ),
      SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.total,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600
            ),
          ),
          // UPDATE THIS PART TO SHOW DISCOUNTED PRICE
          Text(
            _isCouponApplied && _discountedPrice > 0
                ? '${_discountedPrice.toInt()} ${loc.currencyHourly}'
                : '${(widget.package?.originalPrice ?? widget.totalPrice).toInt()} ${loc.currencyHourly}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF2582A),
            ),
          ),
        ],
      ),
      Spacer(),
      Container(
        width: MediaQuery.of(context).size.width * 0.50,
        child: ElevatedButton(
          onPressed: _selectedDates.isNotEmpty &&
                  !_isSelectingStartDate &&
                  widget.selectedAddress != null
              ? _validateAndProceed
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10295C),
            disabledBackgroundColor: Color(0xFF768090),
            padding: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Text(
            loc.next,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      )
    ],
  ),
),
    ],
      ),
  );
}
}
