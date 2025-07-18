import 'package:flutter/material.dart';
import '../widgets/booking_bottom_navigation.dart';
import '../services/api_service.dart';
import '../models/profession_model.dart';
import 'package:intl/intl.dart';
import 'custom_date_selection.dart';
import 'package:fawran/generated/app_localizations.dart';

class ServiceDetailsStep extends StatefulWidget {
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
    required this.onContractDurationChanged,
    required this.onWorkerCountChanged,
    required this.onVisitsPerWeekChanged,
    required this.onSelectedDaysChanged,
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
  }) : super(key: key);

  @override
  _ServiceDetailsStepState createState() => _ServiceDetailsStepState();
}
class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
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

double _apiFinalPricePerVisit = 0.0; // Price per visit with VAT
double _vatAmount = 0.0;
double _apiPriceVat = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.isCustomBooking) {
      _loadCountryGroups();
      _loadServiceShifts();
      _loadVisitDurations(); // Add this call
      _loadContractDurations(); // Add this
      _loadHourlyVisits();
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
        
        print('🔍 DEBUG: Extracted from response:');
        print('  - price_per_visit: $pricePerVisit (without VAT)');
        print('  - total_price: $totalPrice (without VAT)');
        print('  - final_price: $finalPrice (with VAT)');
        print('  - hour_price: $hourPrice');
        print('  - price_vat: $priceVat');
        
        // Calculate VAT amount and final price per visit
        final vatAmount = finalPrice - totalPrice;
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
  
  // Also reset the parent's selected days
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

// Add this method to build the Select Date field
  Widget _buildSelectDateField(AppLocalizations loc) {
    bool hasSelectedDates = _internalSelectedDates.isNotEmpty;
    bool canSelectDates = widget.contractDuration > 0 && widget.visitsPerWeek > 0;

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
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
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
                children: [
                  Expanded(
                    child: Text(
                      loc.date,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasSelectedDates)
                    Text(
                      '${_internalSelectedDates.length} dates selected',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      loc.tapToSelect,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
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
                            // The price calculation is now handled inside the CustomDateSelectionStep
                            // and communicated back via onTotalPriceChanged callback
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
                            // Now this callback will be called whenever dates change
                            // with the correct price calculation
                            _calculatedTotalPrice = price;
                          });

                          // Update parent with total price if callback is available
                          if (widget.onTotalPriceChanged != null) {
                            widget.onTotalPriceChanged!(_calculatedTotalPrice);
                          }
                        },
                        onNextPressed: null,
                        pricePerVisit: _apiPricePerVisit > 0 ? _apiPricePerVisit : widget.pricePerVisit,
                        contractDuration: widget.contractDuration,
                        visitsPerWeek: widget.visitsPerWeek,
                        maxSelectableDates: _getMaxSelectableDates(),
                        showBottomNavigation: false,
                        vatAmount: _vatAmount,
                        professionId: widget.professionId,
                        workerCount: widget.workerCount,
                      ),
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
                      color: Colors.black87,
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
  // Check if value is empty or not in options
  bool hasValidValue = value.isNotEmpty && options.contains(value);

  return Container(
    margin: EdgeInsets.only(bottom: 15),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled && !isLoading
            ? () => _showCustomDropdown(
                context, options, value, onChanged, customTitle)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isEnabled) ...[
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  )
                else ...[
                  Text(
                    hasValidValue ? value : loc.select,
                    style: TextStyle(
                      fontSize: 16,
                      color: hasValidValue ? Colors.black : Colors.grey[500],
                      fontWeight:
                          hasValidValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[600], size: 20),
                ],
              ] else
                Text(
                  hasValidValue ? value : 'Select',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasValidValue ? Colors.black : Colors.grey[500],
                    fontWeight: hasValidValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showCustomDropdown(
  BuildContext context,
  List<String> options,
  String currentValue,
  Function(String) onChanged,
  String? customTitle,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              customTitle ?? 'Select Option',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            Divider(color: Colors.grey[200]),

            // Scrollable options
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = currentValue.isNotEmpty && option == currentValue;

                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      
                      // Call the onChanged callback and handle if it's async
                      final result = onChanged(option);
                      if (result is Future) {
                        await result;
                      }
                      
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFF1E3A8A).withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Color(0xFF1E3A8A)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Color(0xFF1E3A8A),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6),
              Text(
                widget.visitDuration.contains('ساعات') ? 'ساعات' : 'Hours',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
                    margin: EdgeInsets.only(right: i < 4 ? 16 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.workerCount == i
                          ? Color(0xFF1E3A8A)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.workerCount == i
                            ? Color(0xFF1E3A8A)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
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
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'SAR ${(_calculatedTotalPrice > 0 && _internalSelectedDates.isNotEmpty) ? _calculatedTotalPrice.toStringAsFixed(2) : '0.0'}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Done Button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap:
                          _isValidDateSelection() ? widget.onDonePressed : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isValidDateSelection()
                              ? Color(0xFF1E3A8A)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
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
          ),
        ],
      ),
    );
  }
}