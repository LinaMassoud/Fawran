import 'package:flutter/material.dart';

class DateSelectionStep extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final VoidCallback? onNextPressed;
  final int maxSelectableDates; // This is now the total workers needed

  const DateSelectionStep({
    Key? key,
    required this.selectedDates,
    required this.onDatesChanged,
    this.onNextPressed,
    this.maxSelectableDates = 1,
  }) : super(key: key);

  @override
  _DateSelectionStepState createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
  late DateTime currentMonth;
  late DateTime nextMonth;
  late List<DateTime> selectedDates;
  Map<DateTime, int> dateWorkerCount = {};
  int totalDatesSelected = 0;
  
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
    
    _initializeWorkerAvailability();
    _calculateSelectedDates();
  }

  void _initializeWorkerAvailability() {
    final now = DateTime.now();
    
    // Initialize worker availability for current month
    final daysInCurrentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInCurrentMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      if (date.isBefore(DateTime(now.year, now.month, now.day))) continue;
      
      // Dynamic worker availability logic based on day patterns
      if (day % 7 == 0 || day % 7 == 1) { // Weekend - fewer workers available
        dateWorkerCount[date] = 2;
      } else if (day % 5 == 0) {
        dateWorkerCount[date] = 4;
      } else {
        dateWorkerCount[date] = 6;
      }
    }
    
    // Initialize worker availability for next month
    final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInNextMonth; day++) {
      final date = DateTime(nextMonth.year, nextMonth.month, day);
      dateWorkerCount[date] = 8;
    }
  }

  void _calculateSelectedDates() {
    totalDatesSelected = selectedDates.length;
  }

  bool _isDateDisabled(DateTime date) {
    final now = DateTime.now();
    final workerCount = dateWorkerCount[date] ?? 0;
    
    // Disable if date is in the past, has no workers, or doesn't have enough workers for the requirement
    return date.isBefore(DateTime(now.year, now.month, now.day)) || 
           workerCount < widget.maxSelectableDates;
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
        // Remove date
        selectedDates.removeWhere((selectedDate) => 
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day
        );
        totalDatesSelected--;
      } else {
        // Check if we can add more dates (for cases where user might want multiple dates)
        // For now, assuming one date selection, but keeping flexible for future use
        selectedDates.add(date);
        totalDatesSelected++;
        
      }
    });
    
    // Notify parent component of changes
    widget.onDatesChanged(selectedDates);
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
      final isSelected = _isDateSelected(date);
      
      dayWidgets.add(
        GestureDetector(
          onTap: () => _toggleDateSelection(date),
          child: Container(
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue[100]
                : isDisabled
                  ? Colors.grey[100]
                  : Colors.transparent,
              border: isSelected 
                ? Border.all(color: Colors.blue[600]!, width: 2)
                : Border.all(color: Colors.grey[200]!, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDisabled 
                    ? Colors.grey[400]
                    : isSelected
                      ? Colors.blue[800]
                      : Colors.black,
                ),
              ),
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
        
        // Day headers with background color and bold text
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200], // Light grey background like in the image
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Container(
                      width: 35,
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800, // Made more bold
                          color: Colors.black87,
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
          height: 240,
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
                  SizedBox(height: 20),
                  Text(
                    'Select Dates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  
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
                            
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
                  // Circular count indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: totalDatesSelected > 0 
                          ? Colors.green[100] 
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$totalDatesSelected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: totalDatesSelected > 0 
                              ? Colors.green[800] 
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Selection status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dates Selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$totalDatesSelected',
                        style: TextStyle(
                          fontSize: 20,
                          color: totalDatesSelected > 0 
                              ? Colors.green 
                              : Colors.grey,
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
                      onTap: totalDatesSelected > 0 && widget.onNextPressed != null 
                          ? widget.onNextPressed 
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: totalDatesSelected > 0 
                              ? Color(0xFF1E3A8A)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            totalDatesSelected > 0 
                                ? 'Next' 
                                : 'Select Date',
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
