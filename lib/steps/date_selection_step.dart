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
  Map<DateTime, int> allocatedWorkers = {}; // Track workers allocated per date
  int totalWorkersAllocated = 0;
  
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
    _calculateAllocatedWorkers();
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

  void _calculateAllocatedWorkers() {
    allocatedWorkers.clear();
    totalWorkersAllocated = 0;
    
    for (DateTime date in selectedDates) {
      // For existing selections, assume 1 worker per date (for backward compatibility)
      // In a real implementation, you might want to store this information differently
      allocatedWorkers[date] = 1;
      totalWorkersAllocated += 1;
    }
  }

  bool _isDateDisabled(DateTime date) {
    final now = DateTime.now();
    final workerCount = dateWorkerCount[date] ?? 0;
    return date.isBefore(DateTime(now.year, now.month, now.day)) || workerCount == 0;
  }

  bool _isDateSelected(DateTime date) {
    return selectedDates.any((selectedDate) => 
      selectedDate.year == date.year &&
      selectedDate.month == date.month &&
      selectedDate.day == date.day
    );
  }

  int _getAvailableWorkersForDate(DateTime date) {
    final totalAvailable = dateWorkerCount[date] ?? 0;
    final currentlyAllocated = allocatedWorkers[date] ?? 0;
    return totalAvailable - currentlyAllocated;
  }

  void _toggleDateSelection(DateTime date) {
    if (_isDateDisabled(date)) return;
    
    setState(() {
      if (_isDateSelected(date)) {
        // Remove date and its allocated workers
        selectedDates.removeWhere((selectedDate) => 
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day
        );
        totalWorkersAllocated -= (allocatedWorkers[date] ?? 0);
        allocatedWorkers.remove(date);
      } else {
        // Calculate how many workers we can allocate to this date
        final availableWorkers = _getAvailableWorkersForDate(date);
        final workersNeeded = widget.maxSelectableDates - totalWorkersAllocated;
        
        if (workersNeeded <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already allocated all ${widget.maxSelectableDates} workers.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        if (availableWorkers <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No workers available on this date.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        // Efficiently allocate the maximum possible workers for this date
        final workersToAllocate = availableWorkers >= workersNeeded ? workersNeeded : availableWorkers;
        
        selectedDates.add(date);
        allocatedWorkers[date] = workersToAllocate;
        totalWorkersAllocated += workersToAllocate;
        
        // Show allocation message
        if (totalWorkersAllocated == widget.maxSelectableDates) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Perfect! All ${widget.maxSelectableDates} worker${widget.maxSelectableDates > 1 ? 's' : ''} allocated successfully.'
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (workersToAllocate < workersNeeded) {
          final remainingWorkers = workersNeeded - workersToAllocate;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Allocated $workersToAllocate worker${workersToAllocate > 1 ? 's' : ''} for this date. '
                'You still need $remainingWorkers more worker${remainingWorkers > 1 ? 's' : ''}.'
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Allocated $workersToAllocate worker${workersToAllocate > 1 ? 's' : ''} for this date.'
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
    
    // Notify parent component of changes
    widget.onDatesChanged(selectedDates);
  }

  Color _getWorkerCountColor(int availableWorkers) {
    if (availableWorkers == 1) {
      return Colors.red;
    } else if (availableWorkers < 3) {
      return Colors.orange; // Yellow/Orange for less than 3
    } else {
      return Colors.green; // Green for 3 or more
    }
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
      final availableWorkers = _getAvailableWorkersForDate(date);
      
      dayWidgets.add(
        GestureDetector(
          onTap: () => _toggleDateSelection(date),
          child: Container(
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue[100]
                : Colors.transparent,
              border: isSelected 
                ? Border.all(color: Colors.blue[600]!, width: 2)
                : Border.all(color: Colors.grey[200]!, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                if (!isDisabled) ...[
                  SizedBox(height: 1),
                  Text(
                    '$availableWorkers left',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getWorkerCountColor(availableWorkers),
                    ),
                    textAlign: TextAlign.center,
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
                      color: totalWorkersAllocated == widget.maxSelectableDates 
                          ? Colors.green[100] 
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$totalWorkersAllocated',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: totalWorkersAllocated == widget.maxSelectableDates 
                              ? Colors.green[800] 
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Allocation progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Workers Allocated',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$totalWorkersAllocated/${widget.maxSelectableDates}',
                        style: TextStyle(
                          fontSize: 20,
                          color: totalWorkersAllocated == widget.maxSelectableDates 
                              ? Colors.green 
                              : Colors.blue,
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
                      onTap: totalWorkersAllocated > 0 && widget.onNextPressed != null 
                          ? widget.onNextPressed 
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: totalWorkersAllocated > 0 
                              ? Color(0xFF1E3A8A)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            totalWorkersAllocated == widget.maxSelectableDates 
                                ? 'Perfect!' 
                                : 'Next',
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