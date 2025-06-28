import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';

class DateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
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

  const DateSelectionStep({
    Key? key,
    required this.selectedDates,
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

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController();
    _selectedDates = List.from(widget.selectedDates);
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

  void _selectDate(DateTime date) {
    setState(() {
      // If we're still selecting the start date
      if (_isSelectingStartDate) {
        _userSelectedStartDate = date;
        _selectedDates.clear();
        _selectedDates.add(date);
        _isSelectingStartDate = false;
        _calculateContractDetails(); // Recalculate with new start date
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        return;
      }

      // If user clicks on the current start date, allow them to change it
      if (date == _userSelectedStartDate) {
        _resetToStartDateSelection();
        return;
      }

      // Regular date selection for visits
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

        // Check if date matches selected days (for package bookings)
        if (!widget.isCustomBooking && !_isDateAllowedForPackage(date)) {
          String selectedDaysText = widget.selectedDays.isNotEmpty
              ? widget.selectedDays.join(', ')
              : 'your selected days';
          _showSnackBar('Please select dates that match $selectedDaysText');
          return;
        }

        _selectedDates.add(date);
      }
      _selectedDates.sort();
      _updateWeeklyVisitCounts();
    });
    widget.onDatesChanged(_selectedDates);
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
      _calculateContractDetails();
    });
    widget.onDatesChanged(_selectedDates);
    _showSnackBar('Please select a new start date');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
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

  Widget _buildContractInfo() {
    String statusText = _isSelectingStartDate
        ? 'Please select your start date'
        : 'Select visit dates within contract period (tap START date to change)';

    // Get contract duration text using the helper method
    String contractDurationText = _getContractDurationText();

    // Get package name if available
    String packageInfo = widget.package?.packageName ?? 'Custom Package';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  packageInfo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              if (!_isSelectingStartDate)
                TextButton(
                  onPressed: _resetToStartDateSelection,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
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
              color: _isSelectingStartDate ? Colors.orange : Colors.blue.shade600,
            ),
          ),
          Text(
            'Duration: $contractDurationText • Visits: $_visitsPerWeekCount per week',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
          ),
          if (widget.selectedDays.isNotEmpty)
            Text(
              'Selected Days: ${widget.selectedDays.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          if (widget.package != null) ...[
            Text(
              'Service: ${widget.package!.durationDisplay} • ${widget.package!.timeDisplay} • ${widget.package!.nationalityDisplay}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
          Text(
            'Total Visits: $_totalAllowedVisits • Selected: ${_selectedDates.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
          ),
          if (_contractStartDate != null && _contractEndDate != null)
            Text(
              'Contract Period: ${DateFormat('MMM dd, yyyy').format(_contractStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_contractEndDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
        ],
      ),
    );
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
        // _buildContractInfo(),
        Expanded(
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
                  onPressed: _selectedDates.isNotEmpty &&
                          !_isSelectingStartDate &&
                          _selectedDates.length == _totalAllowedVisits &&
                          widget.onNextPressed != null
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
              )
            ],
          ),
        ),
      ],
    );
  }
}