import 'package:fawran/providers/contractsProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import 'package:fawran/generated/app_localizations.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  const BookingsScreen({super.key, this.initialTab});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _selectedTab = 'all';
  Timer? _deadlineTimer;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    Future.microtask(() {
      ref.read(contractsProvider.notifier).fetchContracts();
    });
    _selectedTab = widget.initialTab ?? 'all';
    _startDeadlineTimer();
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(initializationSettings);
  }

  void _startDeadlineTimer() {
    _deadlineTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDeadlines();
    });
  }

  void _checkDeadlines() {
    final state = ref.read(contractsProvider);
    final allContracts = [...state.permanent, ...state.hourly];
    
    for (var contract in allContracts) {
      if (contract["status"]?.toLowerCase() == "not confirmed") {
        final minutesLeft = _extractMinutesLeft(contract["time_info"]);
        if (minutesLeft != null && minutesLeft <= 15 && minutesLeft > 0) {
          _showDeadlineNotification(contract, minutesLeft);
        }
      }
    }
  }

  int? _extractMinutesLeft(String? timeInfo) {
    if (timeInfo == null || timeInfo.isEmpty) return null;
    
    final regex = RegExp(r'(\d+)\s*minutes?\s*left', caseSensitive: false);
    final match = regex.firstMatch(timeInfo);
    
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  Future<void> _showDeadlineNotification(Map<String, dynamic> contract, int minutesLeft) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'deadline_channel',
          'Deadline Notifications',
          channelDescription: 'Notifications for contract deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final contractId = contract["contract_id"] ?? contract["service_contract_id"];
    
    await _notifications.show(
      contractId.hashCode,
      'Contract Deadline Alert',
      'Contract $contractId expires in $minutesLeft minutes. Please confirm or it will be cancelled.',
      platformChannelSpecifics,
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDeadlineTime(String? timeInfo, String status) {
    if (timeInfo == null || timeInfo.isEmpty) return "Not specified";
    
    if (status.toLowerCase() == "not confirmed") {
      return timeInfo;
    } else {
      try {
        final dateTime = DateTime.parse(timeInfo);
        return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        return timeInfo;
      }
    }
  }

  Widget _buildHeaderWithBadges(String serviceType, String status, String? timeInfo, Color serviceTypeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time left badge at the top (only for "not confirmed" status)
        if (status.toLowerCase() == "not confirmed" && timeInfo != null && timeInfo.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300, width: 1),
            ),
            child: Text(
              "Time remaining for payment - $timeInfo",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        
        // Service type and status badges row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: serviceTypeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                serviceType,
                style: TextStyle(
                  color: serviceTypeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            _buildStatusBadge(status),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor = Colors.grey;
    switch (status.toLowerCase()) {
      case "active":
        statusColor = Colors.green;
        break;
      case "pending":
        statusColor = Colors.orange;
        break;
      case "cancelled":
      case "canceled":
        statusColor = Colors.red;
        break;
      case "not confirmed":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPermanentContractCard(Map<String, dynamic> booking) {
    String status = booking["status"] ?? "success";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            _buildHeaderWithBadges("Permanent Service", status, booking["time_info"], Colors.blue),
            const SizedBox(height: 12),
            
            _infoRow("Contract ID", booking["contract_id"] ?? ""),
            _infoRow("Nationality", booking["nationality_name"] ?? ""),
            _infoRow("Profession", booking["profession_name"] ?? ""),
            _infoRow("Package", booking["package_name"] ?? ""),
            _infoRow("Days", booking["period_days"].toString()),
            _infoRow("Vat", "${booking["vat_amount"]} Riyal"),
            _infoRow("Price", "${booking["amount_to_pay"]} Riyal"),
            if (booking["delivery_charges"] > 0)
              _infoRow("Delivery", booking["delivery_charges"].toString()),
            
            // Show cancelled time below other info if status is cancelled
            if (status.toLowerCase() == "cancelled" || status.toLowerCase() == "canceled")
              _infoRow(
                "Cancelled Time",
                _formatDeadlineTime(booking["time_info"], status)
              ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Payment logic
                  },
                  child: const Text("Pay Now"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: status == "cancelled" || status == "canceled"
                      ? null
                      : () {
                          ref
                              .read(contractsProvider.notifier)
                              .cancelPermContract(
                                booking["contract_id"].toString(),
                                isHourly: false,
                              );
                        },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyContractCard(Map<String, dynamic> booking, AppLocalizations loc) {
    String status = booking["status"] ?? "success";

    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return "Not specified";
      try {
        final date = DateTime.parse(dateStr);
        return "${date.day}/${date.month}/${date.year}";
      } catch (_) {
        return dateStr;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            _buildHeaderWithBadges(
              loc.hourlyService ?? "Hourly Service", 
              status, 
              booking["time_info"], 
              Colors.green
            ),
            const SizedBox(height: 12),
            
            _infoRow(loc.serviceContractId ?? "Service Contract ID",
                booking["service_contract_id"]?.toString() ?? ""),
            _infoRow(loc.contractId ?? "Contract ID", booking["contract_id"]?.toString() ?? ""),
            _infoRow(loc.customer ?? "Customer", booking["customer_display"] ?? ""),
            _infoRow(loc.service ?? "Service", booking["service_id"]?.toString() ?? ""),
            _infoRow(loc.totalPrice ?? "Total Price", "${booking["total_price"] ?? 0} Riyal"),
            _infoRow(loc.vat ?? "VAT", "${booking["vat_price"] ?? 0}  Riyal"),
            _infoRow(loc.startDate ?? "Start Date", formatDate(booking["contract_start_date"])),
            
            // Show cancelled time below start date if status is cancelled
            if (status.toLowerCase() == "cancelled" || status.toLowerCase() == "canceled")
              _infoRow(
                "Cancelled Time",
                _formatDeadlineTime(booking["time_info"], status)
              ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Payment logic
                  },
                  child: Text(loc.payNow ?? "Pay Now"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: booking["status"] == "2"
                      ? null
                      : () {
                          ref
                              .read(contractsProvider.notifier)
                              .cancelHourlyContract(
                                booking["service_contract_id"].toString(),
                                isHourly: false,
                              );
                        },
                  child: Text(loc.cancel ?? "Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getFilteredContracts(
      List<Map<String, dynamic>> permanent, List<Map<String, dynamic>> hourly, AppLocalizations loc) {
    List<Widget> contracts = [];

    if (_selectedTab == 'all' || _selectedTab == 'permanent') {
      contracts.addAll(permanent.map(_buildPermanentContractCard));
    }

    if (_selectedTab == 'all' || _selectedTab == 'hourly') {
      contracts.addAll(hourly.map((booking) => _buildHourlyContractCard(booking, loc)));
    }

    return contracts;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(contractsProvider);
    final notifier = ref.read(contractsProvider.notifier);
    final userId = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text(
                          'All',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      ButtonSegment(
                        value: 'permanent',
                        label: Text(
                          'Permanent',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      ButtonSegment(
                        value: 'hourly',
                        label: Text(
                          'Hourly',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                    selected: {_selectedTab},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedTab = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.fetchContracts,
              child: Builder(
                builder: (context) {
                  final filtered = _getFilteredContracts(state.permanent, state.hourly, loc);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No bookings found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(children: filtered);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.fetchContracts,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}