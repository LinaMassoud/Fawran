import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final Function(double)? onTotalPriceChanged;
  final VoidCallback? onNextPressed;
  final double pricePerVisit;
  final String contractDuration;
  final String visitsPerWeek;
  final int maxSelectableDates;
  final bool showBottomNavigation;
  
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
    required this.visitsPerWeek,
    required this.maxSelectableDates,
    this.showBottomNavigation = true,
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

  void _calculateContractDetails() {
    // Parse contract duration
    int durationInWeeks = 0;
    String duration = widget.contractDuration.toLowerCase();
    
    if (duration.contains('year')) {
      int years = int.tryParse(widget.contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      durationInWeeks = years * 52;
    } else if (duration.contains('month')) {
      int months = int.tryParse(widget.contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      durationInWeeks = months * 4;
    } else if (duration.contains('week')) {
      durationInWeeks = int.tryParse(widget.contractDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    }

    // Parse visits per week
    _visitsPerWeekCount = int.tryParse(widget.visitsPerWeek.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

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
      // If we're still selecting the start date
      if (_isSelectingStartDate) {
        _userSelectedStartDate = date;
        _selectedDates.clear();
        _selectedDates.add(date);
        _isSelectingStartDate = false;
        _calculateContractDetails();
        _updateWeeklyVisitCounts();
        widget.onDatesChanged(_selectedDates);
        _notifyPriceChange();
        return;
      }

      // Regular date selection for visits
      if (_selectedDates.contains(date)) {
        // Don't allow removing the start date
        if (date == _userSelectedStartDate) {
          _showSnackBar('Cannot remove start date. Tap "Reset" to choose a new start date.');
          return;
        }
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
    
    // If selecting start date, only allow today or future dates
    if (_isSelectingStartDate) {
      return dateOnly.isAfter(todayOnly) || dateOnly.isAtSameMomentAs(todayOnly);
    }
    
    // Check if date is within contract period
    if (_contractStartDate != null && _contractEndDate != null) {
      if (dateOnly.isBefore(_contractStartDate!) || dateOnly.isAfter(_contractEndDate!)) {
        return false;
      }
    }

    // Check if date is already selected
    if (_selectedDates.contains(date)) {
      return true;
    }

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
      final isOutsideContract = !_isSelectingStartDate && _contractStartDate != null && _contractEndDate != null &&
          (date.isBefore(_contractStartDate!) || date.isAfter(_contractEndDate!));
      final isStartDate = date == _userSelectedStartDate;

      Color backgroundColor = Colors.transparent;
      Color textColor = Colors.black;
      Color priceColor = Colors.green;

      if (isSelected) {
        if (isStartDate) {
          backgroundColor = Color(0xFF1E3A8A);
          textColor = Colors.white;
          priceColor = Colors.white;
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
              border: isSelected ? Border.all(color: Color(0xFF1E3A8A), width: 1) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
                if (isStartDate && !_isSelectingStartDate) ...[
                  Text(
                    'START',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ] else if (isWeekFull && !isSelected && !_isSelectingStartDate) ...[
                  Text(
                    'Full',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ] else if (isSelectable && !isOutsideContract) ...[
                  Text(
                    _formatPrice(widget.pricePerVisit),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMonthHeader(DateTime month) {
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

  double _calculateTotalPrice() {
    return (_selectedDates.length * widget.pricePerVisit) + widget.vatAmount;
  }

  Widget _buildContractInfo() {
    String statusText = _isSelectingStartDate 
        ? 'Please select your start date'
        : 'Select visit dates within contract period';
        
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
            'Duration: ${widget.contractDuration} • Visits: $_visitsPerWeekCount per week',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1E3A8A),
            ),
          ),
          Text(
            'Total Visits: $_totalAllowedVisits • Selected: ${_selectedDates.length}',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1E3A8A),
            ),
          ),
          if (_contractStartDate != null && _contractEndDate != null)
            Text(
              'Contract Period: ${DateFormat('MMM dd, yyyy').format(_contractStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_contractEndDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A8A),
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
        
        _buildContractInfo(),
        
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
              return _buildMonthView(month);
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