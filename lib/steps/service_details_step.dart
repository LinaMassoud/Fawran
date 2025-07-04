import 'package:flutter/material.dart';
import '../widgets/booking_bottom_navigation.dart';

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
  final bool showBottomNavigation;
  final double totalPrice;
  final List<DateTime> selectedDates;

  const ServiceDetailsStep({
    Key? key,
    required this.selectedNationality,
    required this.workerCount,
    required this.contractDuration,
    required this.selectedTime,
    required this.visitDuration,
    required this.visitsPerWeek,
    this.selectedDays = const [],
    required this.onContractDurationChanged,
    required this.onWorkerCountChanged,
    required this.onVisitsPerWeekChanged,
    required this.onSelectedDaysChanged,
    this.onSelectDatePressed,
    this.onDonePressed,
    this.showBottomNavigation = false,
    this.totalPrice = 0.0,
    this.selectedDates = const [],
  }) : super(key: key);

  @override
  _ServiceDetailsStepState createState() => _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  final List<String> weekDays = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Saturday'
];

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
                      color: Color(0xFF7B2CBF),
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
                          ? Color(0xFF7B2CBF) 
                          : canSelect 
                              ? Colors.grey[300]! 
                              : Colors.grey[200]!,
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    color: isSelected 
                        ? Color(0xFF7B2CBF).withOpacity(0.1) 
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
                            ? Color(0xFF7B2CBF) 
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
          
          // Selection status indicator
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

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged, {bool isEnabled = true}) {
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
            PopupMenuButton<String>(
              onSelected: onChanged,
              offset: Offset(0, 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                ],
              ),
              itemBuilder: (context) => options.map((option) => 
                PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                )
              ).toList(),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCountField() {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.workerCount} Worker${widget.workerCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.workerCount > 1) {
                    widget.onWorkerCountChanged(widget.workerCount - 1);
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.remove, size: 18, color: Colors.grey[600]),
                ),
              ),
              SizedBox(width: 15),
              Text(
                '${widget.workerCount}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  widget.onWorkerCountChanged(widget.workerCount + 1);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Icon(Icons.add, size: 18, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> contractDurations = [
      '1 week', '2 weeks', '1 month', '3 months', '6 months'
    ];
    final List<String> visitFrequencies = [
      '1 visit weekly', '2 visits weekly', '3 visits weekly'
    ];
    final List<String> nationalities = ['East Asia', 'South Asia', 'Africa', 'Europe'];
    final List<String> times = ['Morning', 'Afternoon', 'Evening'];
    final List<String> durations = ['2 hours', '3 hours', '4 hours', '5 hours', '6 hours'];

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
                                '1 weekly visit:Cleaning Visit',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Get SAR 225 off',
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
                      (value) {},
                      isEnabled: false
                    ),
                    
                    _buildWorkerCountField(),
                    
                    _buildDropdownField(
                      'Contract Duration', 
                      widget.contractDuration, 
                      contractDurations, 
                      widget.onContractDurationChanged
                    ),
                    
                    _buildDropdownField(
                      'Time', 
                      widget.selectedTime,
                      times,
                      (value) {},
                      isEnabled: false
                    ),
                    
                    _buildDropdownField(
                      'Duration of visit', 
                      widget.visitDuration,
                      durations,
                      (value) {},
                      isEnabled: false
                    ),
                    
                    _buildDropdownField(
                      'Visits week number', 
                      widget.visitsPerWeek, 
                      visitFrequencies, 
                      widget.onVisitsPerWeekChanged
                    ),
                    
                    // Day Selection Widget - Auto-navigates when complete
                    _buildDaySelectionWidget(),
                    
                    // Removed the _buildSelectDateButton() call
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Navigation (shown only when dates are selected)
          if (widget.showBottomNavigation)
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
                          '${widget.selectedDates.length}',
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
                          'SAR ${widget.totalPrice.toInt()}',
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
                        onTap: widget.onDonePressed,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF7B2CBF),
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