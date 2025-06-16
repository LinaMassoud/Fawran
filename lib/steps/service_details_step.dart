import 'package:flutter/material.dart';
import '../widgets/booking_bottom_navigation.dart';
import '../services/api_service.dart';
import '../models/profession_model.dart';
import 'package:intl/intl.dart';
import 'custom_date_selection.dart';


class ServiceDetailsStep extends StatefulWidget {
  final String selectedNationality;
  final int workerCount;
  final String contractDuration;
  final String selectedTime;
  final String visitDuration;
  final String visitsPerWeek;
  final List<String> selectedDays;
  final Function(String) onContractDurationChanged;
  final Function(int) onWorkerCountChanged;
  final Function(String) onVisitsPerWeekChanged;
  final Function(List<String>) onSelectedDaysChanged;
  final VoidCallback? onSelectDatePressed;
  final VoidCallback? onDonePressed;
  final VoidCallback? onNextPressed; 
  final bool showBottomNavigation;
  final double totalPrice;
  final List<DateTime> selectedDates;
  final double? discountPercentage; 
  final int serviceId; // Add this line
  final double pricePerVisit;
  
  // New parameters for custom booking support
  final bool isCustomBooking;
  final Function(String)? onNationalityChanged;
  final Function(String)? onTimeChanged;
  final Function(String)? onVisitDurationChanged;
final Function(List<DateTime>)? onSelectedDatesChanged;
  final Function(double)? onTotalPriceChanged;

const ServiceDetailsStep({
  Key? key,
  this.selectedNationality = '',
  required this.workerCount,
  this.contractDuration = '',
  this.selectedTime = '',
  this.visitDuration = '',
  this.visitsPerWeek = '',
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
  this.pricePerVisit = 0.0,
  this.onTotalPriceChanged, // Add this line
}) : super(key: key);

  @override
  _ServiceDetailsStepState createState() => _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  final List<String> weekDays = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Saturday'
  ];

  // Add these new state variables
  List<String> nationalities = []; // Remove default values
List<String> timeSlots = []; // Remove default values
List<String> visitDurations = []; // Add new variable for visit durations
bool isLoadingNationalities = false;
bool isLoadingTimeSlots = false;
bool isLoadingVisitDurations = false;

bool _showCalendar = false;
List<DateTime> _internalSelectedDates = [];
double _calculatedTotalPrice = 0.0;




@override
void initState() {
  super.initState();
  if (widget.isCustomBooking) {
    _loadCountryGroups();
    _loadServiceShifts();
    _loadVisitDurations(); // Add this call
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
            // Extract the duration from service name (e.g., "FAWRAN 4 Hours" -> "4 hours")
            final serviceName = service.name;
            final match = RegExp(r'(\d+)\s*Hours?').firstMatch(serviceName);
            if (match != null) {
              final hours = match.group(1);
              availableDurations.add('$hours hours');
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
    
  } catch (e) {
    print('Error loading visit durations: $e');
    setState(() {
      visitDurations = []; // No fallback values
      isLoadingVisitDurations = false;
    });
  }
}

void _resetCalendarSelection() {
  setState(() {
    _internalSelectedDates.clear();
    _calculatedTotalPrice = 0.0; // Explicitly set to 0
    _showCalendar = false;
  });
  
  // Call the total price callback to update parent
  if (widget.onTotalPriceChanged != null) {
    widget.onTotalPriceChanged!(0.0);
  }
}
void _onDateSelectionComplete(List<DateTime> dates) {
  setState(() {
    _internalSelectedDates = dates;
    // Only calculate price if dates are actually selected
    _calculatedTotalPrice = dates.isNotEmpty ? dates.length * widget.pricePerVisit : 0.0;
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
Widget _buildSelectDateField() {
  bool hasSelectedDates = _internalSelectedDates.isNotEmpty;
  bool canSelectDates = widget.contractDuration.isNotEmpty && widget.visitsPerWeek.isNotEmpty;
  
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
              'Please select Contract Duration and Visits Per Week first',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Date selection trigger field

        GestureDetector(
          onTap: canSelectDates ? () {
            setState(() {
              _showCalendar = !_showCalendar;
            });
          } : () {
            _showValidationMessage('Please select Contract Duration and Visits Per Week first');
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!, 
                width: 1.5
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Date',
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
                    'Tap to select',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                SizedBox(width: 4),
                Icon(
                  _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                  color: Colors.grey[600], 
                  size: 20
                ),
              ],
            ),
          ),
        ),
        
        // Animated calendar container
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _showCalendar ? 600 : 0,
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
      // Only calculate price if dates are actually selected
      _calculatedTotalPrice = dates.isNotEmpty ? dates.length * widget.pricePerVisit : 0.0;
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
      // Only update if we have selected dates, otherwise keep it 0
      _calculatedTotalPrice = _internalSelectedDates.isNotEmpty ? price : 0.0;
    });
    
    // Update parent with total price if callback is available
    if (widget.onTotalPriceChanged != null) {
      widget.onTotalPriceChanged!(_calculatedTotalPrice);
    }
  },
  onNextPressed: null,
  pricePerVisit: widget.pricePerVisit,
  contractDuration: widget.contractDuration,
  visitsPerWeek: widget.visitsPerWeek,
  maxSelectableDates: _getMaxSelectableDates(),
  showBottomNavigation: false,
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
  // Check if required fields are selected
  if (widget.contractDuration.isEmpty || widget.visitsPerWeek.isEmpty) {
    return false;
  }
  
  // Check if dates are actually selected (not just initialized)
  if (_internalSelectedDates.isEmpty) {
    return false;
  }
  
  // Validate date count matches expected visits
  int expectedVisits = _getMaxSelectableDates();
  return _internalSelectedDates.length <= expectedVisits && _calculatedTotalPrice > 0;
}

// Add this method to calculate max selectable dates
int _getMaxSelectableDates() {
  // Parse contract duration
  int durationInWeeks = 0;
  if (widget.contractDuration.toLowerCase().contains('month')) {
    int months = int.tryParse(widget.contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    durationInWeeks = months * 4;
  } else if (widget.contractDuration.toLowerCase().contains('week')) {
    durationInWeeks = int.tryParse(widget.contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  }
  
  // Parse visits per week
  int visitsPerWeekCount = int.tryParse(widget.visitsPerWeek.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  
  return durationInWeeks * visitsPerWeekCount;
}
  Future<void> _loadCountryGroups() async {
    setState(() {
      isLoadingNationalities = true;
    });

    try {
      final response = await ApiService.fetchCountryGroups(serviceId: widget.serviceId);
      if (response is List && response.isNotEmpty) {
        setState(() {
          nationalities = response.map((item) => item['group_name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
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
      final response = await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
      if (response is List && response.isNotEmpty) {
        setState(() {
          timeSlots = response.map((item) => item['service_shifts']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
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
    // Extract number from visits per week string (e.g., "2 visits weekly" -> 2)
    final match = RegExp(r'^(\d+)').firstMatch(widget.visitsPerWeek);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 1; // Default to 1 if parsing fails
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
                    text: maxSelectable == 1 ? 'one day' : '$maxSelectable days',
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    if (newSelectedDays.length == maxSelectable && widget.onSelectDatePressed != null) {
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
}) {
  // Check if value is empty or not in options
  bool hasValidValue = value.isNotEmpty && options.contains(value);
  
  return Container(
    margin: EdgeInsets.only(bottom: 15),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.grey[300]!, 
        width: 1.5
      ),
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
        if (isEnabled)
          GestureDetector(
            onTap: isLoading ? null : () => _showCustomDropdown(context, options, value, onChanged, customTitle),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                if (!isLoading)
                  Text(
                    hasValidValue ? value : 'Select',
                    style: TextStyle(
                      fontSize: 16,
                      color: hasValidValue ? Colors.black : Colors.grey[500],
                      fontWeight: hasValidValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                if (!isLoading)
                  SizedBox(width: 4),
                if (!isLoading)
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
              ],
            ),
          )
        else
          Text(
            hasValidValue ? value : 'Not selected',
            style: TextStyle(
              fontSize: 16,
              color: hasValidValue ? Colors.black : Colors.grey[500],
              fontWeight: hasValidValue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
      ],
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
                  // Only show as selected if currentValue is not empty and matches
                  final isSelected = currentValue.isNotEmpty && option == currentValue;
                  
                  return InkWell(
                    onTap: () {
                      onChanged(option);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? Color(0xFF1E3A8A) : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildVisitDurationField() {
  if (widget.isCustomBooking && widget.onVisitDurationChanged != null) {
    // Editable visit duration for custom booking - use loaded durations
    return _buildDropdownField(
      'Duration of visit',
      widget.visitDuration,
      visitDurations,
      (value) {
        // Call the callback
        widget.onVisitDurationChanged!(value);
      },
      customTitle: 'Select Visit Duration',
      isLoading: isLoadingVisitDurations,
    );
  } else {
    // Read-only visit duration for package booking
    bool hasValidDuration = widget.visitDuration.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!, 
          width: 1.5
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Duration of visit',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasValidDuration)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.visitDuration.replaceAll(RegExp(r'\s*hours?'), ''),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Hours',
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
              'Not selected',
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
}

 Widget _buildWorkerCountField() {
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
          'How many professionals do you need?',
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
                  _resetCalendarSelection();
                  // Recalculate total price if dates are selected
                  if (_internalSelectedDates.isNotEmpty && widget.onTotalPriceChanged != null) {
                    _calculatedTotalPrice = _internalSelectedDates.length * widget.pricePerVisit;
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
    // Extended contract duration options
    final List<String> contractDurations = [
      '1 week',
      '2 weeks', 
      '3 weeks',
      '1 month',    // 4 weeks
      '5 weeks',
      '6 weeks',
      '7 weeks',
      '2 months',   // 8 weeks
      '9 weeks',
      '10 weeks',
      '3 months',   // 12 weeks
      '4 months',
      '5 months',
      '6 months',
      '1 year'
    ];
    
    // Extended visit frequency options
    final List<String> visitFrequencies = [
      '1 visit weekly', 
      '2 visits weekly', 
      '3 visits weekly',
      '4 visits weekly',
      '5 visits weekly',
      '6 visits weekly'
    ];

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
                                    ? 'Design your card'
                                    : '1 weekly visit:Cleaning Visit',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              if (!widget.isCustomBooking && widget.discountPercentage != null && widget.discountPercentage! > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  'Nationality', 
  widget.selectedNationality,
  nationalities,
  (value) {
    // Call the callback if available
    if (widget.onNationalityChanged != null) {
      widget.onNationalityChanged!(value);
    }
  },
  isEnabled: widget.isCustomBooking && widget.onNationalityChanged != null,
  customTitle: 'Select Nationality',
  isLoading: isLoadingNationalities,
),
                    
                    _buildWorkerCountField(),
                    
                    _buildDropdownField(
                    'Contract Duration', 
                    widget.contractDuration, 
                    contractDurations, 
                    (value) {
                      widget.onContractDurationChanged(value);
                      _resetCalendarSelection(); // Add this line
                    },
                    customTitle: 'Select Contract Duration',
                  ),
                    
                    _buildDropdownField(
  'Time', 
  widget.selectedTime,
  timeSlots,
  (value) {
    // Call the callback if available
    if (widget.onTimeChanged != null) {
      widget.onTimeChanged!(value);
    }
  },
  isEnabled: widget.isCustomBooking && widget.onTimeChanged != null,
  customTitle: 'Select Time Slot',
  isLoading: isLoadingTimeSlots,
),
                    
                    _buildVisitDurationField(),
                    
                    _buildDropdownField(
                    'Visits week number', 
                    widget.visitsPerWeek, 
                    visitFrequencies, 
                    (value) {
                      widget.onVisitsPerWeekChanged(value);
                      _resetCalendarSelection(); // Add this line
                    },
                    customTitle: 'Select Visits Per Week',
                  ),
                    
                    // Day Selection Widget - Auto-navigates when complete
                      _buildSelectDateField(),
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
                // Count indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_internalSelectedDates.isNotEmpty ? _internalSelectedDates.length : widget.selectedDates.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Price section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                    'SAR ${(_calculatedTotalPrice > 0 && _internalSelectedDates.isNotEmpty) ? _calculatedTotalPrice.toStringAsFixed(1) : '0.0'}',
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
                  onTap: _isValidDateSelection() ? widget.onDonePressed : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isValidDateSelection() ? Color(0xFF1E3A8A) : Colors.grey[400],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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