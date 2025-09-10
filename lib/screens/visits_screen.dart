import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'reschedule_calendar_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'dart:ui' as ui;

class VisitsScreen extends ConsumerStatefulWidget {
  final int customerId;
  
  const VisitsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> expandedTickets = {};
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Set<String> expandedTodayTickets = {};
  Set<String> expandedUpcomingTickets = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // This will rebuild the UI when tab changes
    });
    _loadUserData();
    _loadVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final firstName = await _secureStorage.read(key: 'first_name') ?? '';
    final middleName = await _secureStorage.read(key: 'middle_name') ?? '';
    final lastName = await _secureStorage.read(key: 'last_name') ?? '';
    
    setState(() {
      _firstName = firstName;
      _middleName = middleName;
      _lastName = lastName;
    });
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final visits = await ApiService.getVisits(widget.customerId);
      if (visits != null) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load visits';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading visits: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _todayVisits {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _visits.where((visit) => visit['visit_date'] == today).toList();
  }

  List<Map<String, dynamic>> get _upcomingVisits {
    final today = DateTime.now();
    return _visits.where((visit) {
      final visitDate = DateTime.parse(visit['visit_date']);
      return visitDate.isAfter(today);
    }).toList();
  }

  void _navigateToReschedule(Map<String, dynamic> visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleCalendarScreen(
          visit: visit,
          customerId: widget.customerId,
          onRescheduleSuccess: _loadVisits, // Refresh visits after reschedule
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, bool isToday) {
  final loc = AppLocalizations.of(context)!;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  final visitDate = DateTime.parse(visit['visit_date']);
  final formattedDate = DateFormat('dd/MM/yyyy').format(visitDate);
  final visitId = visit['visit_id']?.toString() ?? '';
  
  // Create unique identifier by combining visit ID with tab type
  final uniqueId = '${isToday ? "today" : "upcoming"}_${visitId}_${visit['visit_date']}_${visit['shift'] ?? ""}';
  
  // Use the appropriate expanded set based on whether it's today or upcoming
  final currentExpandedSet = isToday ? expandedTodayTickets : expandedUpcomingTickets;
  final isExpanded = isToday 
    ? expandedTodayTickets.contains(uniqueId)
    : expandedUpcomingTickets.contains(uniqueId);
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1E49A0), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          spreadRadius: 0,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header section with full-width blue background
        Container(
          child: Row(
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              // Blue background section extending from left to divider
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E49A0),
                    borderRadius: BorderRadius.only(
                      topLeft: isArabic ? Radius.zero : Radius.circular(9),
                      topRight: isArabic ? Radius.circular(9) : Radius.zero,
                      bottomLeft: isArabic ? Radius.zero : Radius.circular(0),
                      bottomRight: isArabic ? Radius.circular(0) : Radius.zero,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    children: [
                      // Expand/Collapse arrow
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isToday) {
                              if (expandedTodayTickets.contains(uniqueId)) {
                                expandedTodayTickets.remove(uniqueId);
                              } else {
                                expandedTodayTickets.add(uniqueId);
                              }
                            } else {
                              if (expandedUpcomingTickets.contains(uniqueId)) {
                                expandedUpcomingTickets.remove(uniqueId);
                              } else {
                                expandedUpcomingTickets.add(uniqueId);
                              }
                            }
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                    ],
                  ),
                ),
              ),
              // White section with name and time info
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl :ui.TextDirection.ltr,
                        children: [
                          SvgPicture.asset(
                            'assets/images/person.svg', // Replace with your person SVG file name
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(Color(0xFF1E3A8A), BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_firstName.isNotEmpty ? _firstName : ''} ${_middleName.isNotEmpty ? _middleName + ' ' : ''}${_lastName.isNotEmpty ? _lastName : ''}' + (_firstName.isEmpty && _middleName.isEmpty && _lastName.isEmpty ? 'User Name' : ''),
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF1E49A0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${loc.from ?? 'From'} ${_formatShift(visit['shift'])}',
                            style: const TextStyle(
                              color: Color(0xFF1E49A0),
                              fontSize: 9,
                            ),
                            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Expandable content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isExpanded ? null : 0,
          child: isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // Divider
                      Container(
                        height: 1,
                        color: const Color(0xFFE0E0E0),
                        margin: const EdgeInsets.only(bottom: 16),
                      ),
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.attach_money,
                              visit['worker_names'],
                              useWorkerIcon: true,
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Service details in rows format
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.attach_money,
                              '${visit['price'] ?? '0'} ${loc.currencyHourly ?? 'SAR'}',
                              isArabic: isArabic,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.business,
                              visit['service_name'] ?? (loc.service ?? 'Service'),
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.access_time,
                              visit['contract_id'] ?? 'Unknown',
                              isArabic: isArabic,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.info_outline,
                              visit['contract_status'] ?? 'Unknown',
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.receipt_long,
                              visit['visit_status'] ?? 'Unknown',
                              isArabic: isArabic,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailColumn(
                              Icons.calendar_today,
                              formattedDate,
                              isArabic: isArabic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Reschedule button - now integrated at the bottom of the card
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToReschedule(visit),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              loc.reschedule ?? 'Reschedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDetailColumn(IconData icon, String text, {Color? statusColor, bool useWorkerIcon = false, required bool isArabic}) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          children: [
            useWorkerIcon 
              ? SvgPicture.asset(
                  'assets/images/worker.svg', // Replace with your worker SVG from assets/images
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(Color(0xFF1E49A0), BlendMode.srcIn),
                )
              : SvgPicture.asset(
                  'assets/icons/info.svg',
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(Color(0xFF1E49A0), BlendMode.srcIn),
                ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF091735),
                  fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? statusColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: statusColor ?? Colors.grey[700],
              fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'new':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatShift(String? shift) {
    if (shift == null) return 'N/A';
    
    switch (shift.toUpperCase()) {
      case 'MORNING':
        return '08:00AM To 12:00PM';
      case 'AFTERNOON':
        return '12:00PM To 04:00PM';
      case 'EVENING':
        return '04:00PM To 08:00PM';
      default:
        return shift;
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
        backgroundColor: const Color(0xFFF8FAFC), // Match bookings background
        body: Column(
          children: [
            // Updated Header to match bookings screen
            Container(
              height: 124,
              decoration: const BoxDecoration(
                color: Color(0xFF10295C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: isArabic ? null : 0,
                    right: isArabic ? 0 : null,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: Icon(
                          isArabic ? Icons.arrow_back_ios : Icons.arrow_back_ios,
                          color: Color(0xFFFFA200), 
                          size: 20
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Title
                  Center(
                    child: Text(
                      loc.visits ?? 'Visits',
                      style: const TextStyle(
                        color: Color(0xFFFFA200),
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0EAFF),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                children: ['today', 'upcoming'].map((tab) {
                  String label = tab == 'today' 
                    ? (loc.todayVisits ?? 'Today Visits') 
                    : (loc.comingVisits ?? 'Coming Visits');
                  final isSelected = (tab == 'today' && _tabController.index == 0) ||
                                   (tab == 'upcoming' && _tabController.index == 1);
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.animateTo(tab == 'today' ? 0 : 1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF1E49A0)  // Blue for both selected tabs
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white  // White text for both selected tabs
                                : const Color(0xFF9CA3AF),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10295C)),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadVisits,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10295C),
                                  ),
                                  child: Text(loc.retry ?? 'Retry'),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              // Today Visits
                              _todayVisits.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc.noVisitsToday ?? 'No visits scheduled for today',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadVisits,
                                      color: const Color(0xFF10295C),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                                        itemCount: _todayVisits.length,
                                        itemBuilder: (context, index) {
                                          return _buildVisitCard(_todayVisits[index], true); // Pass true for today visits
                                        },
                                      ),
                                    ),
                              
                              // Upcoming Visits
                              _upcomingVisits.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc.noUpcomingVisits ?? 'No upcoming visits scheduled',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadVisits,
                                      color: const Color(0xFF10295C),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                                        itemCount: _upcomingVisits.length,
                                        itemBuilder: (context, index) {
                                          return _buildVisitCard(_upcomingVisits[index], false); // Pass false for upcoming visits
                                        },
                                      ),
                                    ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}