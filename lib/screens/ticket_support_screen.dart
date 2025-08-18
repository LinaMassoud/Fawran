import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'create_ticket_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/generated/app_localizations.dart';

class TicketsSupportScreen extends ConsumerStatefulWidget {
  const TicketsSupportScreen({Key? key}) : super(key: key);

  ConsumerState<TicketsSupportScreen> createState() => _TicketsSupportScreenState();
}

class _TicketsSupportScreenState extends ConsumerState<TicketsSupportScreen> {
  List<Map<String, dynamic>> tickets = [];
  Set<String> expandedTickets = {};
  bool isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
  try {
    setState(() {
      isLoading = true;
    });

    // Get customer ID from secure storage
    final customerId = await _secureStorage.read(key: 'user_id');
    
    if (customerId != null) {
      // Fetch tickets first
      final fetchedTickets = await ApiService.getTickets(customerId);
      
      // Process each ticket to get category and type names
      for (var ticket in fetchedTickets) {
        // Get category name
        if (ticket['ticket_category_id'] != null && ticket['sector_type'] != null) {
          try {
            final categories = await ApiService.fetchTicketCategories(ticket['sector_type']);
            final category = categories.firstWhere(
              (cat) => cat['id'] == ticket['ticket_category_id'],
              orElse: () => {'category_name': 'Unknown Category', 'name': 'Unknown Category'},
            );
            ticket['category_name'] = category['category_name'] ?? category['name'] ?? 'Unknown Category';
          } catch (e) {
            ticket['category_name'] = 'Unknown Category';
            print('Error fetching category for ticket ${ticket['ticket_id']}: $e');
          }
        }
        
        // Get type name
        if (ticket['ticket_type_id'] != null && ticket['ticket_category_id'] != null) {
          try {
            final types = await ApiService.fetchTicketTypes(ticket['ticket_category_id']);
            final type = types.firstWhere(
              (typ) => typ['id'] == ticket['ticket_type_id'],
              orElse: () => {'type_name': 'Unknown Type', 'name': 'Unknown Type'},
            );
            ticket['type_name'] = type['type_name'] ?? type['name'] ?? 'Unknown Type';
          } catch (e) {
            ticket['type_name'] = 'Unknown Type';
            print('Error fetching type for ticket ${ticket['ticket_id']}: $e');
          }
        }
        
        // Get city name
        if (ticket['city_code'] != null) {
          try {
            final cities = await ApiService.fetchCitiesForTicket();
            final city = cities.firstWhere(
              (cty) => cty['city_code'].toString() == ticket['city_code'].toString(),
              orElse: () => {'city_name': 'Unknown City', 'name': 'Unknown City'},
            );
            ticket['city_name'] = city['city_name'] ?? city['name'] ?? 'Unknown City';
          } catch (e) {
            ticket['city_name'] = 'Unknown City';
            print('Error fetching city for ticket ${ticket['ticket_id']}: $e');
          }
        }
      }
      
      setState(() {
        tickets = fetchedTickets;
      });
    }
  } catch (e) {
    print('Error loading tickets: $e');
    // Show error snackbar if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load tickets')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'closed':
        return const Color(0xFF00BCD4); // Cyan color for closed
      case 'pending':
        return Color(0xFF90A3B2);
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    final loc = AppLocalizations.of(context)!;
    switch (status?.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'closed':
        return loc.statusClosed;
      case 'pending':
        return loc.statusPending;
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status ?? 'Unknown';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      // Try to parse the date and format it
      DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    final isRtl = isArabic;
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
              Icons.arrow_back_ios,
              color: Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          loc.ticketsSupport,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10295C)),
              ),
            )
          : tickets.isEmpty
              ? const Center(
                  child: Text(
                    'No tickets found',
                    style: TextStyle(
                      color: Color(0xFF091735),
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  color: const Color(0xFF10295C),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(ticket);
                    },
                  ),
                ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF10295C),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () async {
            // Navigate to create new ticket screen
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateTicketScreen(),
              ),
            );
            
            // If ticket was created successfully, refresh the tickets list
            if (result == true) {
              _loadTickets();
            }
          },
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
Widget _buildTicketCard(Map<String, dynamic> ticket) {
  final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    
    final ticketId = ticket['ticket_id']?.toString() ??
        ticket['id']?.toString() ??
        'Unknown';
    final status = ticket['status']?.toString() ?? 'open';
    
    // Use the fetched names directly from the ticket data
    final category = ticket['category_name'] ?? 'Unknown Category';
    final ticketType = ticket['type_name'] ?? 'Unknown Type';
    final cityName = ticket['city_name'] ?? 'Unknown City';
    
    final description = ticket['description']?.toString() ??
        ticket['subject']?.toString() ??
        'No description';
    final createdDate = ticket['created_at']?.toString() ??
        ticket['date']?.toString() ??
        ticket['created_date']?.toString();
    final details = ticket['details']?.toString() ?? '';

    final isExpanded = expandedTickets.contains(ticketId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            expandedTickets.remove(ticketId);
          } else {
            expandedTickets.add(ticketId);
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Color(0xFFE0EAFF), // White-Blue background
          border: Border.all(
            color: Color(0xFF1E49A0), // Second-blue border
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background SVG positioned at bottom right for LTR, bottom left for RTL
              Positioned(
                bottom: 0,
                right: isArabic ? null : 0,
                left: isArabic ? 0 : null,
                child: SvgPicture.asset(
                    'assets/images/design.svg', // Your background SVG path
                    width: 96, // Adjust size as needed
                    height: 96, // Adjust size as needed
                    fit: BoxFit.contain,
                  ),
              ),
              
              // Main content column
              Column(
                children: [
                  // Main card content with Stack
                  Stack(
                    children: [
                      // Main ticket content with padding
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32), // Space at top
                            _buildTicketDetail(
                              iconPath: 'assets/icons/info.svg',
                              text: '${loc.ticketCategory}: $category',
                              isArabic: isArabic,
                            ),
                            const SizedBox(height: 8),
                            _buildTicketDetail(
                              iconPath: 'assets/icons/info.svg',
                              text: '${loc.ticketType}: $ticketType',
                              isArabic: isArabic,
                            ),
                            const SizedBox(height: 8),
                            _buildTicketDetail(
                              iconPath: 'assets/icons/info.svg',
                              text: '${loc.date}: ${_formatDate(createdDate)}',
                              isArabic: isArabic,
                            ),
                          ],
                        ),
                      ),

                      // Positioned ticket number container - adjust for RTL
                      Positioned(
                        top: 0,
                        left: isArabic ? null : 0,
                        right: isArabic ? 0 : null,
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.only(
                              topLeft: isArabic ? Radius.zero : Radius.circular(16),
                              topRight: isArabic ? Radius.circular(16) : Radius.zero,
                              bottomLeft: isArabic ? Radius.circular(16) : Radius.zero,
                              bottomRight: isArabic ? Radius.zero : Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            'T CS $ticketId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                        ),
                      ),

                      // Positioned status and expand button - adjust for RTL
                      Positioned(
                        top: 0,
                        right: isArabic ? null : 0,
                        left: isArabic ? 0 : null,
                        child: Container(
                          height: 40,
                          padding: EdgeInsets.only(
                            right: isArabic ? 0 : 16,
                            left: isArabic ? 16 : 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF90A3B2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Expandable details section
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: isExpanded && details.isNotEmpty ? null : 0,
                    child: isExpanded && details.isNotEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Text(
                                    details,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF091735),
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTicketDetail({
    required String iconPath,
    required String text,
    required bool isArabic,
  }) {
    return Row(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Container(
          child: SvgPicture.asset(
            iconPath,
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(Color((0xFF1E49A0)), BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF091735),
              fontWeight: FontWeight.w600,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ],
    );
  }

}