import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

class RescheduleCalendarScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> visit;
  final int customerId;
  final VoidCallback? onRescheduleSuccess;

  const RescheduleCalendarScreen({
    Key? key,
    required this.visit,
    required this.customerId,
    this.onRescheduleSuccess,
  }) : super(key: key);

  @override
  ConsumerState<RescheduleCalendarScreen> createState() => _RescheduleCalendarScreenState();
}

class _RescheduleCalendarScreenState extends ConsumerState<RescheduleCalendarScreen> {
  late PageController _pageController;
  late DateTime _currentMonth;
  late DateTime _originalVisitDate;
  DateTime? _newSelectedDate;
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _originalVisitDate = DateTime.parse(widget.visit['visit_date']);
    _currentMonth = DateTime(_originalVisitDate.year, _originalVisitDate.month);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _canSelectDate(DateTime date) {
  // Prevent selection if it's before 24 hours from now
  final now = DateTime.now();
  final twentyFourHoursFromNow = now.add(const Duration(hours: 24));
  
  // Only allow dates that are at least 24 hours from now
  if (date.isBefore(twentyFourHoursFromNow.subtract(const Duration(hours: 1)))) {
    return false;
  }

  // Don't allow selecting the original visit date
  if (_isSameDay(date, _originalVisitDate)) {
    return false;
  }

  // Disable Fridays (weekday 5)
  if (date.weekday == 5) {
    return false;
  }

  // Allow all other dates (removed week restriction)
  return true;
}

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
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

  // Add current month days
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(month.year, month.month, day);
    final isOriginalDate = _isSameDay(date, _originalVisitDate);
    final isNewSelectedDate = _newSelectedDate != null && _isSameDay(date, _newSelectedDate!);
    final isSelectable = _canSelectDate(date);
    final isToday = _isSameDay(date, DateTime.now());

    Color backgroundColor = Colors.transparent;
    Color textColor = Color(0xFF10295C); // Updated default text color
    Color borderColor = Colors.transparent;
    String? labelText;

    if (isOriginalDate) {
      backgroundColor = Color(0xFF10295C);
      textColor = Colors.white;
      labelText = 'ORIG';
    } else if (isNewSelectedDate) {
      backgroundColor = Color(0xFFFFA200); // Updated to match theme
      textColor = Colors.white;
      labelText = 'NEW';
    } else if (isToday && isSelectable) {
      backgroundColor = Color(0xFF10295C); // Updated to match theme
      textColor = Colors.white;
      labelText = 'TODAY';
    } else if (!isSelectable) {
      backgroundColor = Colors.grey.withOpacity(0.2);
      textColor = Colors.grey;
    }
    // Removed the blue background for selectable dates

    dayWidgets.add(
      GestureDetector(
        onTap: isSelectable ? () {
          setState(() {
            _newSelectedDate = date;
          });
        } : null,
        child: Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: borderColor != Colors.transparent 
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (labelText != null) ...[
                const SizedBox(height: 2),
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: textColor,
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
    mainAxisSpacing: 2,
    crossAxisSpacing: 2,
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
            color: canNavigateLeft ? Color(0xFF10295C) : Colors.grey, // Updated color
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
              color: Color(0xFF10295C), // Updated color
            ),
          ),
        ),
        IconButton(
          onPressed: canNavigateRight ? () => _navigateToMonth(1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: canNavigateRight ? Color(0xFF10295C) : Colors.grey, // Updated color
            size: 28,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDayHeaders() {
    const dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: dayNames.map((day) {
          return Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    return Column(
      children: [
        _buildMonthHeader(month),
        _buildDayHeaders(),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildCalendarGrid(month),
          ),
        ),
      ],
    );
  }

  Future<void> _rescheduleVisit() async {
    if (_newSelectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a new date for the visit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.rescheduleVisit(
        customerId: widget.customerId,
        hourlyVisitId: widget.visit['appointment_id'],
        newDate: DateFormat('yyyy-MM-dd').format(_newSelectedDate!),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Visit rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onRescheduleSuccess?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to reschedule visit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



 @override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  return Directionality(
    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
    child: Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: Color(0xFF10295C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              isArabic ? Icons.arrow_back_ios : Icons.arrow_back_ios,
              color: Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          isArabic ? 'إعادة جدولة الزيارة' : 'Reschedule Visit',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // Visit Info Card with Arabic support
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    widget.visit['service_name'] ?? (isArabic ? 'خدمة' : 'Service'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10295C),
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      isArabic 
                        ? 'تاريخ الزيارة الحالي: ${DateFormat('dd/MM/yyyy').format(_originalVisitDate)}'
                        : 'Current Visit Date: ${DateFormat('dd/MM/yyyy').format(_originalVisitDate)}',
                      style: TextStyle(color: Colors.grey[700]),
                      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          
          // Calendar with Arabic day headers
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
          ),
          
          // Action buttons with Arabic support - FIXED: Removed Positioned widget
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom + 10
                : 25,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E49A0).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, -5),
                ),
                BoxShadow(
                  color: Color(0xFF1E49A0).withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              children: [
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10295C)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isArabic ? 'إلغاء' : 'Cancel',
                        style: const TextStyle(
                          color: Color(0xFF10295C),
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: ElevatedButton(
                      onPressed: _isLoading || _newSelectedDate == null
                          ? null
                          : _rescheduleVisit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_newSelectedDate != null && !_isLoading)
                            ? Color(0xFF10295C)
                            : null,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Color(0xFF768090),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: (_newSelectedDate != null && !_isLoading) ? 2 : 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isArabic ? 'إعادة الجدولة' : 'Reschedule',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}