import 'package:flutter/material.dart';

class DateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final VoidCallback? onNextPressed;
  final int maxSelectableDates;
  final List<String> selectedDays; // Days selected in service details
  final String contractDuration; // Contract duration from service details

  const DateSelectionStep({
    Key? key,
    required this.selectedDates,
    required this.onDatesChanged,
    this.onNextPressed,
    this.maxSelectableDates = 10,
    this.selectedDays = const [],
    this.contractDuration = '1 month',
  }) : super(key: key);

  @override
  _DateSelectionStepState createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
  late DateTime currentMonth;
  late DateTime nextMonth;
  DateTime? serviceStartingDate;
  DateTime? serviceEndingDate;
  List<DateTime> autoSelectedDates = [];
  List<DateTime> availableStartDates = [];
  bool showDateDropdown = false;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonth = DateTime(now.year, now.month);
    
    // Handle year rollover properly
    if (now.month == 12) {
      nextMonth = DateTime(now.year + 1, 1);
    } else {
      nextMonth = DateTime(now.year, now.month + 1);
    }
    
    // Auto-select the latest available date
    _initializeAutoSelection();
  }

  void _initializeAutoSelection() {
    if (widget.selectedDays.isNotEmpty) {
      _generateAvailableStartDates();
      if (availableStartDates.isNotEmpty) {
        // Auto-select the latest (first) available date
        serviceStartingDate = availableStartDates.first;
        _calculateAutoSelectedDates();
      }
    }
  }

  void _generateAvailableStartDates() {
  availableStartDates = [];
  final selectedWeekdays = widget.selectedDays.map(_dayNameToWeekday).toList();
  
  if (selectedWeekdays.isEmpty) return;
  
  // Get only the earliest weekday (lowest number) from selected days
  final earliestWeekday = selectedWeekdays.reduce((a, b) => a < b ? a : b);
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  // Generate next 3 weeks of available dates for the earliest weekday only
  for (int week = 0; week < 4; week++) { // Increased to 4 weeks for better options
    DateTime weekStart = today.add(Duration(days: week * 7));
    // Find the start of the week (Sunday = 0)
    DateTime startOfWeek = weekStart.subtract(Duration(days: weekStart.weekday % 7));
    
    // Calculate target date for the earliest weekday
    int daysToAdd = earliestWeekday == 7 ? 0 : earliestWeekday; // Sunday is 7 in our system, 0 in DateTime
    DateTime targetDate = startOfWeek.add(Duration(days: daysToAdd));
    
    // Only add if it's not in the past, not Friday, and is valid
    if (!targetDate.isBefore(today) && 
        targetDate.weekday != 5 && // Not Friday
        _isDateAllowed(targetDate)) {
      availableStartDates.add(targetDate);
    }
  }
  
  // Sort dates chronologically
  availableStartDates.sort();
  
  // Remove duplicates
  availableStartDates = availableStartDates.toSet().toList();
}

  // Convert contract duration string to number of months and visits
  Map<String, int> _getContractDetails() {
    final duration = widget.contractDuration.toLowerCase();
    int months = 1;
    int totalVisits = 0;
    
    if (duration.contains('week')) {
      final match = RegExp(r'(\d+)\s*week').firstMatch(duration);
      final weeks = int.parse(match?.group(1) ?? '1');
      months = (weeks / 4).ceil(); // Convert weeks to months (round up)
      totalVisits = weeks; // For weekly contracts, total visits = weeks
    } else if (duration.contains('month')) {
      final match = RegExp(r'(\d+)\s*month').firstMatch(duration);
      months = int.parse(match?.group(1) ?? '1');
      
      // Calculate total visits based on visits per week
      final visitsPerWeek = _getVisitsPerWeek();
      totalVisits = months * 4 * visitsPerWeek; // months * 4 weeks * visits per week
    }
    
    return {'months': months, 'totalVisits': totalVisits};
  }

  // Extract visits per week from the selected days
  int _getVisitsPerWeek() {
    return widget.selectedDays.length; // Number of selected days = visits per week
  }

  // Convert day names to weekday numbers (1 = Monday, 7 = Sunday)
  int _dayNameToWeekday(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }

  // Check if a date matches any of the selected weekdays and is not Friday
  bool _isDateAllowed(DateTime date) {
    // Always disable Fridays
    if (date.weekday == 5) return false;
    
    if (widget.selectedDays.isEmpty) return false;
    
    final selectedWeekdays = widget.selectedDays.map(_dayNameToWeekday).toList();
    return selectedWeekdays.contains(date.weekday);
  }

  void _calculateAutoSelectedDates() {
    if (serviceStartingDate == null || widget.selectedDays.isEmpty) {
      autoSelectedDates = [];
      return;
    }

    autoSelectedDates = [];
    final contractDetails = _getContractDetails();
    final months = contractDetails['months']!;
    final totalVisits = contractDetails['totalVisits']!;
    final selectedWeekdays = widget.selectedDays.map(_dayNameToWeekday).toList();
    
    // Calculate service ending date based on months
    serviceEndingDate = DateTime(
      serviceStartingDate!.year,
      serviceStartingDate!.month + months,
      serviceStartingDate!.day,
    );
    
    // Generate dates for the entire contract period
    DateTime currentDate = serviceStartingDate!;
    int visitsGenerated = 0;
    
    // Generate visits week by week until we reach the total visits or end date
    while (visitsGenerated < totalVisits && currentDate.isBefore(serviceEndingDate!)) {
      // For each selected weekday in the current week
      for (int weekday in selectedWeekdays) {
        if (visitsGenerated >= totalVisits) break;
        
        // Find the date for this weekday in the current week
        DateTime weekStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
        
        // Calculate how many days to add to get to the target weekday
        int daysToAdd = (weekday - weekStart.weekday) % 7;
        DateTime targetDate = weekStart.add(Duration(days: daysToAdd));
        
        // If the target date is before the current date, move to next week
        if (targetDate.isBefore(currentDate)) {
          targetDate = targetDate.add(Duration(days: 7));
        }
        
        // Only add if it's within the contract period and not Friday
        if ((targetDate.isBefore(serviceEndingDate!) || targetDate.isAtSameMomentAs(serviceEndingDate!)) 
            && targetDate.weekday != 5) { // Not Friday
          autoSelectedDates.add(targetDate);
          visitsGenerated++;
        }
      }
      
      // Move to next week
      currentDate = currentDate.add(Duration(days: 7));
    }
    
    // Sort the dates
    autoSelectedDates.sort();
    
    // Update the service ending date to the last visit date if we have visits
    if (autoSelectedDates.isNotEmpty) {
      serviceEndingDate = autoSelectedDates.last;
    }
    
    // Update parent component
    widget.onDatesChanged(autoSelectedDates);
  }

  bool _isDateDisabled(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Disable if it's in the past
    if (date.isBefore(today)) return true;
    
    // Always disable Fridays
    if (date.weekday == 5) return true;
    
    // Disable if it's not one of the allowed weekdays
    if (!_isDateAllowed(date)) return true;
    
    return false;
  }

  bool _isDateAutoSelected(DateTime date) {
    return autoSelectedDates.any((selectedDate) => 
      selectedDate.year == date.year &&
      selectedDate.month == date.month &&
      selectedDate.day == date.day
    );
  }

  bool _isServiceStartingDate(DateTime date) {
    if (serviceStartingDate == null) return false;
    return serviceStartingDate!.year == date.year &&
           serviceStartingDate!.month == date.month &&
           serviceStartingDate!.day == date.day;
  }

  void _selectStartingDate(DateTime date) {
    if (_isDateDisabled(date)) return;
    
    setState(() {
      serviceStartingDate = date;
      showDateDropdown = false; // Close dropdown after selection
      _calculateAutoSelectedDates();
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return '${days[date.weekday % 7]} ${date.day} ${months[date.month]}';
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (DateTime date in autoSelectedDates) {
      // Use the same pricing logic as before
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

  Widget _buildServiceDateInfo() {
  final contractDetails = _getContractDetails();
  final totalVisits = contractDetails['totalVisits'];
  
  return Container(
    margin: EdgeInsets.only(bottom: 20),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      children: [
        Text(
          'Please select starting date',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service starting date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showDateSelectionDialog(),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              serviceStartingDate != null 
                                ? '${serviceStartingDate!.day.toString().padLeft(2, '0')}/${serviceStartingDate!.month.toString().padLeft(2, '0')}/${serviceStartingDate!.year}'
                                : 'Select date',
                              style: TextStyle(
                                fontSize: 16,
                                color: serviceStartingDate != null ? Colors.black87 : Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: Color(0xFF00BCD4),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
              margin: EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service end date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    serviceEndingDate != null 
                      ? '${serviceEndingDate!.day.toString().padLeft(2, '0')}/${serviceEndingDate!.month.toString().padLeft(2, '0')}/${serviceEndingDate!.year}'
                      : '--/--/----',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
bool _hasDiscount(DateTime date) {
  final day = date.day;
  // Same logic as your pricing - weekend-like or special pricing dates get discounts
  return (day % 7 == 0 || day % 7 == 1 || day % 5 == 0);
}

// Add this method to get discount percentage
String _getDiscountText(DateTime date) {
  final day = date.day;
  if (day % 7 == 0 || day % 7 == 1) {
    return '8%'; // Weekend-like pricing (125 vs ~115 base = ~8% premium, could be shown as discount from higher rate)
  } else if (day % 5 == 0) {
    return '3%'; // Special pricing (119 vs 115 = ~3% premium)
  }
  return '';
}
void _showDateSelectionDialog() {
  if (availableStartDates.isEmpty) return;
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Starting Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Select the first ${widget.selectedDays.first} of your service:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: availableStartDates.take(8).map((date) {
                      final isSelected = serviceStartingDate != null &&
                          serviceStartingDate!.year == date.year &&
                          serviceStartingDate!.month == date.month &&
                          serviceStartingDate!.day == date.day;
                      
                      return GestureDetector(
                        onTap: () {
                          _selectStartingDate(date);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Color(0xFF00BCD4).withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Color(0xFF00BCD4)
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Color(0xFF00BCD4)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected 
                                          ? Color(0xFF00BCD4)
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00BCD4),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  Widget _buildCalendarGrid(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final firstWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;
  
  List<Widget> dayWidgets = [];
  
  // Add empty spaces for days before the first day of month
  for (int i = 0; i < firstWeekday; i++) {
    dayWidgets.add(Container());
  }
  
  // Add actual days
  for (int day = 1; day <= lastDay.day; day++) {
    final date = DateTime(month.year, month.month, day);
    final isDisabled = _isDateDisabled(date);
    final isAutoSelected = _isDateAutoSelected(date);
    final isStartingDate = _isServiceStartingDate(date);
    final isAllowed = _isDateAllowed(date);
    final isFriday = date.weekday == 5;
    final hasDiscount = _hasDiscount(date);
    final discountText = _getDiscountText(date);
    
    dayWidgets.add(
      Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isStartingDate
              ? Color(0xFF1E3A8A)
              : isAutoSelected
                  ? Color(0xFF1E3A8A).withOpacity(0.1)
                  : Colors.transparent,
          border: isAutoSelected && !isStartingDate
              ? Border.all(color: Color(0xFF1E3A8A), width: 1)
              : isStartingDate
                  ? Border.all(color: Color(0xFF1E3A8A), width: 2)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Main date content
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled 
                    ? Colors.grey[400]
                    : isStartingDate
                        ? Colors.white
                        : isAutoSelected
                            ? Color(0xFF1E3A8A)
                            : Colors.grey[400],
                ),
              ),
            ),
            
            // Discount icon - shown on all dates that have discounts
            if (hasDiscount)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDisabled 
                        ? Colors.orange.withOpacity(0.5) // Faded for disabled dates
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    size: 10,
                    color: Colors.black,
                  ),
                ),
              ),
              
          ],
        ),
      ),
    );
  }
  
  return GridView.count(
    crossAxisCount: 7,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    childAspectRatio: 1.0,
    children: dayWidgets,
  );
}

  Widget _buildMonthSection(DateTime month) {
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 
      'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return Column(
      children: [
        // Month header
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${monthNames[month.month]} ${month.year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        
        // Day headers
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Container(
                      width: 35,
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Calendar grid
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          height: 250,
          child: _buildCalendarGrid(month),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Main content - Made fully scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    
                    Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Days Selected : ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Days selection display (read-only)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Wrap(
                          spacing: 8,
                          children: widget.selectedDays.map((day) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Service date info with dropdown
                    _buildServiceDateInfo(),
                    
                    // Calendar content
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Current month
                          _buildMonthSection(currentMonth),
                          
                          SizedBox(height: 20),
                          
                          // Next month
                          _buildMonthSection(nextMonth),
                          
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 100), // Extra space for bottom navigation
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Navigation
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
                  // Total section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total (${autoSelectedDates.length} visits)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'SAR${_calculateTotalPrice().toInt()}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  Spacer(),
                  
                  // Next Button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: serviceStartingDate != null && widget.onNextPressed != null 
                          ? widget.onNextPressed 
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: serviceStartingDate != null 
                              ? Color(0xFF1E3A8A)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'Next',
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