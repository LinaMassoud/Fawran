import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import 'package:fawran/generated/app_localizations.dart';

class CustomDateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final Function(double)? onTotalPriceChanged;
  final VoidCallback? onNextPressed;
  final double pricePerVisit;
  final int contractDuration;
  final int workerCount;
  final int visitsPerWeek;
  final int maxSelectableDates;
  final bool showBottomNavigation;
  final int professionId;

  final Function(List<String>)? onSelectedDaysChanged;
final List<String> selectedDays;
  
  final double vatAmount;
  final double priceWithoutVat;
  
  const CustomDateSelectionStep({
    Key? key,
    required this.selectedDates,
    required this.onDatesChanged,
    this.onTotalPriceChanged,
    this.onNextPressed,
    this.vatAmount = 0.0,
    this.priceWithoutVat = 0.0,
    required this.pricePerVisit,
    required this.contractDuration,
    required this.workerCount,
    required this.visitsPerWeek,
    required this.maxSelectableDates,
    this.showBottomNavigation = true,
    required this.professionId,
    this.selectedDays = const [],        // Add this line
  this.onSelectedDaysChanged,  
  }) : super(key: key);

  @override
  State<CustomDateSelectionStep> createState() => _CustomDateSelectionStepState();
}

class _CustomDateSelectionStepState extends State<CustomDateSelectionStep> {
  late PageController _pageController;
  late DateTime _currentMonth;
  List<DateTime> _selectedDates = [];
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  DateTime? _userSelectedStartDate;
  int _totalAllowedVisits = 0;
  int _visitsPerWeekCount = 0;
  Map<String, int> _weeklyVisitCounts = {};
  bool _isSelectingStartDate = true;
  List<String> _localSelectedDays = [];
  bool _isSnackBarShowing = false;

  @override
void initState() {
  super.initState();
  _currentMonth = DateTime.now();
  _pageController = PageController();
  _selectedDates = List.from(widget.selectedDates);
  _localSelectedDays = List.from(widget.selectedDays);  // Add this line
  _calculateContractDetails();
  _updateWeeklyVisitCounts();
}

  @override
  void didUpdateWidget(CustomDateSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent's selected dates if they changed externally
    if (widget.selectedDates != oldWidget.selectedDates) {
      setState(() {
        _selectedDates = List.from(widget.selectedDates);
        _updateWeeklyVisitCounts();
      });
    }
    
    // Recalculate if price or VAT changed
    if (widget.pricePerVisit != oldWidget.pricePerVisit || 
        widget.vatAmount != oldWidget.vatAmount) {
      _notifyPriceChange();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Check if a date is Friday (weekday 5)
  bool _isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }

  // Get the number of working days (excluding Fridays) in a week
  int _getWorkingDaysPerWeek() {
    return 6; // 7 days - 1 Friday = 6 working days
  }

  // Calculate available working days in the contract period
  int _getAvailableWorkingDaysInPeriod(DateTime startDate, DateTime endDate) {
    int totalDays = 0;
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (!_isFriday(current)) {
        totalDays++;
      }
      current = current.add(Duration(days: 1));
    }
    
    return totalDays;
  }

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

  void _calculateContractDetails() {
  // Contract duration is now directly in weeks
  int durationInWeeks = widget.contractDuration;

  // Visits per week is now directly an int
  _visitsPerWeekCount = widget.visitsPerWeek;
  
  // Ensure visits per week doesn't exceed working days (6 days max)
  if (_visitsPerWeekCount > _getWorkingDaysPerWeek()) {
    _visitsPerWeekCount = _getWorkingDaysPerWeek();
  }

  // Calculate total allowed visits based on working days only
  _totalAllowedVisits = durationInWeeks * _visitsPerWeekCount;

  // Only set default dates if user hasn't selected a start date
  if (_userSelectedStartDate == null) {
    final today = DateTime.now();
    DateTime proposedStartDate = DateTime(today.year, today.month, today.day);
    
    // If today is Friday, move to the next working day (Saturday)
    while (_isFriday(proposedStartDate)) {
      proposedStartDate = proposedStartDate.add(Duration(days: 1));
    }
    
    _contractStartDate = proposedStartDate;
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
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  bool _isWeekFull(DateTime date) {
    String weekKey = _getWeekKey(date);
    int currentWeekCount = _weeklyVisitCounts[weekKey] ?? 0;
    return currentWeekCount >= _visitsPerWeekCount;
  }

  void _notifyPriceChange() {
    if (widget.onTotalPriceChanged != null) {
      // Use the same calculation as _calculateTotalPrice() to ensure consistency
      double totalPrice = _calculateTotalPrice();
      // Use WidgetsBinding to ensure this runs after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTotalPriceChanged!(totalPrice);
      });
    }
  }

  void _selectDate(DateTime date) {
  setState(() {
    // If we have selected days, handle auto-generated dates differently
    if (_localSelectedDays.isNotEmpty && !_isSelectingStartDate) {
      // Allow changing the start date
      if (date == _userSelectedStartDate) {
        _showStartDateChangeDialog();
        return;
      }
      
      // Allow deselecting auto-generated dates and selecting preferred dates within the same week
      if (_selectedDates.contains(date)) {
        // Allow deselection of auto-generated dates
        _selectedDates.remove(date);
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        _notifyPriceChange();
        return;
      } else {
        // Allow manual selection within the same week if:
        // 1. The date is within the contract period
        // 2. The date is not a Friday
        // 3. The week isn't already full
        // 4. We haven't exceeded total visits
        
        if (_isFriday(date)) {
          _showSnackBar('Friday is a holiday and cannot be selected');
          return;
        }
        
        // Check if date is within contract period
        if (_contractStartDate != null && _contractEndDate != null) {
          if (date.isBefore(_contractStartDate!) || date.isAfter(_contractEndDate!)) {
            _showSnackBar('Date is outside the contract period');
            return;
          }
        }
        
        // Check if we've reached the total visit limit
        if (_selectedDates.length >= _totalAllowedVisits) {
          _showSnackBar('Maximum $_totalAllowedVisits visits allowed for this contract');
          return;
        }
        
        // Check if the week is already full
        if (_isWeekFull(date)) {
          _showSnackBar('Maximum $_visitsPerWeekCount visits per week allowed');
          return;
        }
        
        // REMOVED: Check if the selected day matches the weekday of the date
        // This was the main issue - we should allow any day in the week once user starts manual selection
        
        // Add the manually selected date
        _selectedDates.add(date);
        _selectedDates.sort();
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        _notifyPriceChange();
        return;
      }
    }
    
    // If we're still selecting the start date
    if (_isSelectingStartDate) {
      // Don't allow Friday as start date
      if (_isFriday(date)) {
        _showSnackBar('Friday is a holiday and cannot be selected');
        return;
      }
      
      _userSelectedStartDate = date;
      _selectedDates.clear();
      _isSelectingStartDate = false;
      _calculateContractDetails();
      
      // Auto-select dates based on selected days after start date is chosen
      if (_localSelectedDays.isNotEmpty) {
        _autoSelectDatesBasedOnDays();
      } else {
        _selectedDates.add(date);
      }
      
      _updateWeeklyVisitCounts();
      widget.onDatesChanged(_selectedDates);
      _notifyPriceChange();
      return;
    }

    // If clicking on the start date, allow user to change it
    if (date == _userSelectedStartDate) {
      _showStartDateChangeDialog();
      return;
    }

    // Don't allow selecting Fridays for regular visits
    if (_isFriday(date)) {
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

      // Check if the week is already full
      if (_isWeekFull(date)) {
        _showSnackBar('Maximum $_visitsPerWeekCount visits per week allowed');
        return;
      }

      _selectedDates.add(date);
    }
    _selectedDates.sort();
    _updateWeeklyVisitCounts();
  });
  
  // Always notify parent of date changes
  widget.onDatesChanged(_selectedDates);
  
  // Always notify parent of price changes
  _notifyPriceChange();
}

String _weekdayToName(int weekday) {
  switch (weekday) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return 'Unknown';
  }
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

// Set start date from selected days
void _setStartDateFromSelectedDays([List<String>? selectedDays]) {
  List<String> daysToUse = selectedDays ?? _localSelectedDays;
  
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

// Auto-select dates based on selected days
void _autoSelectDatesBasedOnDays([List<String>? selectedDays]) {
  List<String> daysToUse = selectedDays ?? _localSelectedDays;
  
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
  _notifyPriceChange();
}

// Reset to start date selection
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
  
  _notifyPriceChange();
  _showSnackBar('Please select days and start date');
}


  bool _isDateSelectable(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  
  // Never allow selecting Fridays
  if (_isFriday(date)) {
    return false;
  }
  
  // If selecting start date, only allow today or future dates (excluding Fridays)
  if (_isSelectingStartDate) {
    return dateOnly.isAfter(todayOnly) || dateOnly.isAtSameMomentAs(todayOnly);
  }
  
  // Always allow clicking on the start date to change it (if it's not Friday)
  if (date == _userSelectedStartDate) {
    return true;
  }
  
  // Check if date is within contract period
  if (_contractStartDate != null && _contractEndDate != null) {
    if (dateOnly.isBefore(_contractStartDate!) || dateOnly.isAfter(_contractEndDate!)) {
      return false;
    }
  }

  // Check if date is already selected (allow deselection)
  if (_selectedDates.contains(date)) {
    return true;
  }

  // REMOVED: If we have selected days, allow manual selection within those days
  // This was blocking users from selecting other days in the week after deselecting a system-generated date

  // Check if we've reached the total visit limit
  if (_selectedDates.length >= _totalAllowedVisits) {
    return false;
  }

  // Check if the week is already full
  if (_isWeekFull(date)) {
    return false;
  }

  return true;
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

  String _formatPrice(double price) {
    return 'SAR ${price.toStringAsFixed(0)}';
  }

  void _navigateToMonth(int monthOffset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + monthOffset);
    });
    
    final now = DateTime.now();
    final targetMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final currentMonth = DateTime(now.year, now.month);
    
    int monthDifference = (targetMonth.year - currentMonth.year) * 12 + 
                         (targetMonth.month - currentMonth.month);
    
    if (monthDifference >= 0 && monthDifference < 60) {
      _pageController.animateToPage(
        monthDifference,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

Widget _buildDaySelectionWidget(AppLocalizations loc) {
  final days = _getLocalizedDays(loc);
  
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
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: '${_visitsPerWeekCount} ${loc.days}',
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
            String englishDay = _getEnglishDayName(day, loc);
            bool isSelected = _localSelectedDays.contains(englishDay);
            bool isFriday = day == 'Friday';
            
            return GestureDetector(
              onTap: isFriday ? null : () {
                _handleDayToggle(englishDay);
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
                    fontWeight: FontWeight.w600,
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
        // Text(
        //   _userSelectedStartDate != null 
        //       ? 'Start date: ${DateFormat('MMM dd, yyyy').format(_userSelectedStartDate!)}'
        //       : _localSelectedDays.isNotEmpty 
        //           ? 'Start date will be set automatically'
        //           : 'Please select days first',
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w500,
        //     color: _userSelectedStartDate != null 
        //         ? Colors.green.shade700 
        //         : Colors.grey.shade600,
        //   ),
        // ),
      ],
    ),
  );
}
  Widget _buildCalendarGrid(DateTime month,AppLocalizations loc) {
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
      final isOutsideContract = !_isSelectingStartDate && _contractStartDate != null && _contractEndDate != null &&
          (date.isBefore(_contractStartDate!) || date.isAfter(_contractEndDate!));
      final isStartDate = date == _userSelectedStartDate;
      final isFridayHoliday = _isFriday(date);

      Color backgroundColor = Colors.transparent;
      Color textColor = Colors.black;
      Color priceColor = Colors.green;
      String? overlayText;

      if (isFridayHoliday) {
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
      } else if (isSelected) {
        if (isStartDate) {
          backgroundColor = Color(0xFF1E3A8A);
          textColor = Colors.white;
          priceColor = Colors.white;
          overlayText = 'START\n(tap to change)';
        } else {
          backgroundColor = Colors.orange;
          textColor = Colors.white;
          priceColor = Colors.white;
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
            border: isSelected ? Border.all(
              color: isStartDate ? Color(0xFF1E3A8A) : Colors.orange, 
              width: 1
            ) : null,
          ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatNumber(day, loc),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (isStartDate && !_isSelectingStartDate) ...[
                  Text(
                    'START',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ] else if (isWeekFull && !isSelected && !_isSelectingStartDate) ...[
                  
                ] else if (isSelectable && !isOutsideContract) ...[
                  Text(
                    _formatPrice(widget.pricePerVisit),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: priceColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

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

  Widget _buildMonthHeader(DateTime month,AppLocalizations loc) {
    final now = DateTime.now();
    final canNavigateLeft = month.isAfter(DateTime(now.year, now.month));
    final canNavigateRight = month.isBefore(DateTime(now.year + 5, now.month));

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
              _formatMonthYear(month, loc),
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

  Widget _buildMonthView(DateTime month,AppLocalizations loc) {
    return Column(
      children: [
        _buildMonthHeader(month,loc),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _getDayAbbreviations(loc).map((day) {
              return Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: day == loc.fridayShort ? Colors.grey : Colors.black, // Grey out Friday header
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
            child: _buildCalendarGrid(month,loc),
          ),
        ),
      ],
    );
  }

  double _calculateTotalPrice() {
  print("vatAmount inside _calculateTotalPrice = ${widget.vatAmount}");
  double totalPrice = (_selectedDates.length * widget.pricePerVisit) + widget.vatAmount;
  return double.parse(totalPrice.toStringAsFixed(0));
}

  Widget _buildContractInfo() {
    String statusText = _isSelectingStartDate 
        ? 'Please select your start date'
        : 'Select visit dates within contract period (excluding Fridays)';
        
    int availableWorkingDays = 0;
    if (_contractStartDate != null && _contractEndDate != null) {
      availableWorkingDays = _getAvailableWorkingDaysInPeriod(_contractStartDate!, _contractEndDate!);
    }
        
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1E3A8A).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contract Terms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              if (!_isSelectingStartDate)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectingStartDate = true;
                      _userSelectedStartDate = null;
                      _selectedDates.clear();
                      _contractStartDate = null;
                      _contractEndDate = null;
                      _weeklyVisitCounts.clear();
                      _calculateContractDetails();
                    });
                    widget.onDatesChanged(_selectedDates);
                    _notifyPriceChange();
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isSelectingStartDate ? Colors.orange : Color(0xFF1E3A8A),
            ),
          ),
          
          Text(
            'Duration: ${widget.contractDuration} • Working Days: ${_getWorkingDaysPerWeek()} per week (excluding Fridays)',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1E3A8A),
            ),
          ),
          Text(
            'Visits: $_visitsPerWeekCount per week • Total: $_totalAllowedVisits • Selected: ${_selectedDates.length}',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1E3A8A),
            ),
          ),
          if (_contractStartDate != null && _contractEndDate != null) ...[
            Text(
              'Contract Period: ${DateFormat('MMM dd, yyyy').format(_contractStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_contractEndDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A8A),
              ),
            ),
            
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (widget.showBottomNavigation)
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

          _buildDaySelectionWidget(loc),
        
        // _buildContractInfo(),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentMonth = DateTime(DateTime.now().year, DateTime.now().month + index);
              });
            },
            itemCount: 60,
            itemBuilder: (context, index) {
              final month = DateTime(DateTime.now().year, DateTime.now().month + index);
              return _buildMonthView(month,loc);
            },
          ),
        ),
        
        if (widget.showBottomNavigation)
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
                      _formatPrice(_calculateTotalPrice()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Container(
                  width: 120,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedDates.isNotEmpty && !_isSelectingStartDate && widget.onNextPressed != null
                        ? widget.onNextPressed
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
                ),
              ],
            ),
          ),
      ],
    );
  }
}

