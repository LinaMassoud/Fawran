import 'package:fawran/providers/address_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';

class DateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final Function(List<String>)? onSelectedDaysChanged;
  final Function(List<int>)? onWorkerValidationSuccess;
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
  }) : super(key: key);

  @override
  _DateSelectionStepState createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
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

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController();
    _selectedDates = List.from(widget.selectedDates);
    _localSelectedDays = List.from(widget.selectedDays); 
    _calculateContractDetails();
    _updateWeeklyVisitCounts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          errorMessage = 'No workers are available for the selected dates and times.';
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
Widget _buildDaySelectionWidget() {
  final days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Saturday'
  ];
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Please select ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: '${_visitsPerWeekCount} days',
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
            bool isSelected = _localSelectedDays.contains(day); // Use local state
            bool isFriday = day == 'Friday';
            
            return GestureDetector(
              onTap: isFriday ? null : () {
                _handleDayToggle(day);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFriday 
                      ? Colors.grey.shade100 
                      : isSelected 
                          ? Color(0xFF1E3A8A) 
                          : Colors.white,
                  border: Border.all(
                    color: isFriday 
                        ? Colors.grey.shade300 
                        : isSelected 
                            ? Color(0xFF1E3A8A) 
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isFriday 
                        ? Colors.grey.shade400 
                        : isSelected 
                            ? Colors.white 
                            : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text(
          _userSelectedStartDate != null 
              ? 'Start date: ${DateFormat('MMM dd, yyyy').format(_userSelectedStartDate!)}'
              : _localSelectedDays.isNotEmpty 
                  ? 'Start date will be set automatically'
                  : 'Please select days first',
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
    // If we have selected days, don't allow manual date selection
    if (widget.selectedDays.isNotEmpty && !_isSelectingStartDate) {
      // Only allow changing the start date or deselecting dates
      if (date == _userSelectedStartDate) {
        _showStartDateChangeDialog();
        return;
      }
      
      // Show message that dates are auto-selected based on days
      _showSnackBar('Dates are automatically selected based on your chosen days');
      return;
    }
    
    // Original logic for when no days are selected or still selecting start date
    if (_isSelectingStartDate) {
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

    // Rest of the original logic for manual selection when no days are selected
    if (date == _userSelectedStartDate) {
      _resetToStartDateSelection();
      return;
    }

    // Manual date selection/deselection (only when no days are selected)
    if (_selectedDates.contains(date)) {
      _selectedDates.remove(date);
    } else {
      // Check constraints before adding
      if (_selectedDates.length >= _totalAllowedVisits) {
        _showSnackBar('Maximum $_totalAllowedVisits visits allowed for this contract');
        return;
      }

      if (_isWeekFull(date)) {
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
    Color textColor = Colors.black;

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
              // Day number - always shown
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
              // Conditional content based on priority
              if (isStartDate && !_isSelectingStartDate) ...[
                // Highest priority: Start date indicator
                Text(
                  'START',
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
                  'N/A',
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
              color: canNavigateLeft ? Colors.black : Colors.grey,
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: canNavigateRight ? () => _navigateToMonth(1) : null,
            icon: Icon(
              Icons.chevron_right,
              color: canNavigateRight ? Colors.black : Colors.grey,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    return Column(
      children: [
        _buildMonthHeader(month),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
  return Column(
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          'Select Date',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      // Wrap the main content in Expanded and SingleChildScrollView
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Day selection widget
              _buildDaySelectionWidget(),
              // // Contract info
              // _buildContractInfo(),
              // Calendar container with fixed height
              Container(
              height: 450, // Increased height to accommodate 6 rows
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
      // Bottom section remains fixed
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
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
                  _selectedDates.length.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  widget.package?.formattedFinalPrice ?? 'SAR ${widget.totalPrice.toInt()}',
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
            width: 120,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedDates.isNotEmpty &&
                      !_isSelectingStartDate &&
                      widget.selectedAddress != null
                  ? _validateAndProceed // Changed from widget.onNextPressed to _validateAndProceed
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3A8A),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
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
  );
}
}
