import 'package:flutter/material.dart';

class DateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final VoidCallback? onNextPressed;

  const DateSelectionStep({
    Key? key,
    required this.selectedDates,
    required this.onDatesChanged,
    this.onNextPressed,
  }) : super(key: key);

  @override
  _DateSelectionStepState createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
  late DateTime currentMonth;
  late DateTime nextMonth;
  late List<DateTime> selectedDates;
  Map<DateTime, double> datePrices = {};
  
  @override
  void initState() {
    super.initState();
    selectedDates = List.from(widget.selectedDates);
    final now = DateTime.now();
    currentMonth = DateTime(now.year, now.month);
    
    // Handle year rollover properly
    if (now.month == 12) {
      nextMonth = DateTime(now.year + 1, 1);
    } else {
      nextMonth = DateTime(now.year, now.month + 1);
    }
    
    _initializePrices();
  }

  void _initializePrices() {
    final now = DateTime.now();
    
    // Initialize prices for current month
    final daysInCurrentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInCurrentMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      if (date.isBefore(DateTime(now.year, now.month, now.day))) continue; // Skip past dates
      
      // Dynamic pricing logic based on day patterns
      if (day % 7 == 0 || day % 7 == 1) { // Weekend-like pricing
        datePrices[date] = 125.0; // Premium dates
      } else if (day % 5 == 0) {
        datePrices[date] = 119.0; // Special pricing
      } else {
        datePrices[date] = 115.0; // Standard pricing
      }
    }
    
    // Initialize prices for next month
    final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInNextMonth; day++) {
      final date = DateTime(nextMonth.year, nextMonth.month, day);
      // Generally lower prices for next month
      datePrices[date] = 105.0;
    }
  }

  bool _isDateDisabled(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool _isDateSelected(DateTime date) {
    return selectedDates.any((selectedDate) => 
      selectedDate.year == date.year &&
      selectedDate.month == date.month &&
      selectedDate.day == date.day
    );
  }

  void _toggleDateSelection(DateTime date) {
    if (_isDateDisabled(date)) return;
    
    setState(() {
      if (_isDateSelected(date)) {
        selectedDates.removeWhere((selectedDate) => 
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day
        );
      } else {
        selectedDates.add(date);
      }
    });
    
    // Notify parent component of changes
    widget.onDatesChanged(selectedDates);
  }

  double _calculateTotal() {
    double total = 0;
    for (DateTime date in selectedDates) {
      total += datePrices[date] ?? 0;
    }
    return total;
  }

  Color _getDateColor(DateTime date) {
    if (_isDateDisabled(date)) {
      return Colors.grey[300]!;
    }
    
    final price = datePrices[date] ?? 0;
    if (price >= 125) {
      return Colors.orange; // Premium pricing
    } else if (price >= 119) {
      return Colors.green;
    } else {
      return Colors.green;
    }
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    // Use proper weekday calculation (Sunday = 0, Monday = 1, etc.)
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
      final isSelected = _isDateSelected(date);
      final price = datePrices[date];
      
      dayWidgets.add(
        GestureDetector(
          onTap: () => _toggleDateSelection(date),
          child: Container(
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue[100]
                : Colors.transparent,
              // Show orange border when date is selected AND has premium pricing
              border: isSelected 
                ? (price != null && price >= 125)
                  ? Border.all(color: Colors.orange, width: 2)
                  : Border.all(color: Colors.blue, width: 2)
                : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDisabled 
                      ? Colors.grey[400]
                      : isSelected
                        ? Colors.blue[800]
                        : Colors.black,
                  ),
                ),
                if (price != null && !isDisabled)
                  Flexible(
                    child: Text(
                      'SAR ${price.toInt()}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: _getDateColor(date),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
      childAspectRatio: 0.8,
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
          height: 280, // Increased height to ensure all weeks are visible
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
          // Main content
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Calendar content
                  Expanded(
                    child: Container(
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Current month
                            _buildMonthSection(currentMonth),
                            
                            SizedBox(height: 20),
                            
                            // Next month
                            _buildMonthSection(nextMonth),
                            
                            SizedBox(height: 20), // Extra padding at bottom
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation matching the image design
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
                  // Circular count indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${selectedDates.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Total price section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'SAR ${_calculateTotal().toInt()}',
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
                      onTap: selectedDates.isNotEmpty && widget.onNextPressed != null 
                          ? widget.onNextPressed 
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: selectedDates.isNotEmpty 
                              ? Color(0xFF1E3A8A) // Dark blue color matching the image
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25), // More rounded like in the image
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