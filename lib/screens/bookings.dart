import 'package:checkout_flutter/checkout_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:fawran/providers/contractsProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  const BookingsScreen({super.key, this.initialTab});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String _selectedTab = 'all';
  Timer? _deadlineTimer;
  String _checkoutStatus = 'Ready to checkout';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

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
    _confettiController.dispose();

    super.dispose();
  }

  Future<void> _startCheckout(Map<String, dynamic> booking, {required bool isHourly}) async {
  try {
    setState(() {
      _checkoutStatus = 'Starting checkout...';
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Get user details from secure storage
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    final firstName = await secureStorage.read(key: 'first_name') ?? 'User';
    final lastName = await secureStorage.read(key: 'last_name') ?? '';
    final phoneNumber = await secureStorage.read(key: 'phone_number') ?? '';
    final userId = await secureStorage.read(key: 'user_id') ?? '';

    // Extract booking details based on contract type
    String contractId;
    String amount;
    String customerName;
    String serviceDescription;
    
    if (isHourly) {
      contractId = booking["service_contract_id"]?.toString() ?? '';
      amount = booking["total_price"]?.toString() ?? '0';
      customerName = booking["customer_display"] ?? '';
      serviceDescription = 'Hourly Service - ${booking["service_id"]?.toString() ?? ''}';
    } else {
      contractId = booking["contract_id"]?.toString() ?? '';
      amount = booking["amount_to_pay"]?.toString() ?? '0';
      customerName = booking["profession_name"] ?? '';
      serviceDescription = 'Permanent Service - ${booking["profession_name"] ?? ''}';
    }

    Map<String, dynamic> configurations = {
      "hashString": "",
      "language": "en",
      "themeMode": "light",
      "supportedPaymentMethods": ["VISA", "MASTERCARD", "APPLE_PAY", "MADA","GOOGLE_PAY","STC_PAY"],
      "paymentType": "ALL",
      "selectedCurrency": "SAR",
      "supportedCurrencies": ["SAR"],
      "supportedPaymentTypes": [],
      "supportedRegions": [],
      "supportedSchemes": [],
      "supportedCountries": [],
      "gateway": {
        "publicKey": "pk_test_pLd7nzHMmgBXUqNFP1E0SWOZ",
        "merchantId": "",
      },
      "customer": {
        "firstName": firstName,
        "lastName": lastName,
        "email": "customer@example.com",
        "phone": {"countryCode": "965", "number": phoneNumber},
      },
      "transaction": {
        "mode": "charge",
        "charge": {
          "saveCard": true,
          "auto": {"type": "VOID", "time": 100},
          "redirect": {
            "url": "https://demo.staging.tap.company/v2/sdk/checkout",
          },
          "threeDSecure": true,
          "subscription": {
            "type": "SCHEDULED",
            "amount_variability": "FIXED",
            "txn_count": 0,
          },
          "airline": {
            "reference": {"booking": ""},
          },
        },
      },
      "amount": amount,
      "order": {
        "id": "",
        "currency": "SAR",
        "amount": amount,
        "items": [
          {
            "amount": amount,
            "currency": "SAR",
            "name": customerName,
            "quantity": 1,
            "description": serviceDescription,
          },
        ],
      },
      "cardOptions": {
        "showBrands": true,
        "showLoadingState": true,
        "collectHolderName": true,
        "preLoadCardName": "",
        "cardNameEditable": true,
        "cardFundingSource": "all",
        "saveCardOption": "all",
        "forceLtr": false,
        "alternativeCardInputs": {"cardScanner": false, "cardNFC": false},
      },
      "isApplePayAvailableOnClient": true,
    };

    // Call startCheckout function directly
    final success = await startCheckout(
      configurations: configurations,
      onReady: () {
        Navigator.of(context).pop();
        setState(() {
          _checkoutStatus = 'Checkout is ready!';
        });
        print('Checkout is ready!');
      },
      onSuccess: (data) {
        setState(() {
          _checkoutStatus = 'Payment successful: $data';
        });
        print('Payment successful: $data');
        _confettiController.play();
        _showSuccessDialog();
        
        // Refresh contracts after successful payment
        ref.read(contractsProvider.notifier).fetchContracts();
      },
      onError: (error) {
        setState(() {
          _checkoutStatus = 'Payment failed: $error';
        });
        print('Payment failed: $error');
      },
      onClose: () {
        setState(() {
          _checkoutStatus = 'Checkout closed';
        });
        print('Checkout closed');
      },
      onCancel: () {
        setState(() {
          _checkoutStatus = 'Checkout cancelled';
        });
        print('Checkout cancelled (Android)');
      },
    );

    if (!success) {
      setState(() {
        _checkoutStatus = 'Failed to start checkout';
      });
    }
  } catch (e) {
    setState(() {
      _checkoutStatus = 'Error: $e';
    });
  }
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('🎉 Payment Successful!'),
              content: const Text('Thank you for your purchase.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
            Positioned(
              top: 100,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                gravity: 0.3,
              ),
            ),
          ],
        );
      },
    );
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

  Future<void> _showDeadlineNotification(
      Map<String, dynamic> contract, int minutesLeft) async {
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

    final contractId =
        contract["contract_id"] ?? contract["service_contract_id"];

    await _notifications.show(
      contractId.hashCode,
      'Contract Deadline Alert',
      'Contract $contractId expires in $minutesLeft minutes. Please confirm or it will be cancelled.',
      platformChannelSpecifics,
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

  // Helper method to check if contract is cancelled
  bool _isContractCancelled(Map<String, dynamic> contract, bool isHourly) {
    final statusId = contract["status_id"];
    if (statusId == null) return false;

    // For hourly contracts: status_id 2 means cancelled
    // For permanent contracts: status_id 3 means cancelled
    if (isHourly) {
      return statusId.toString() == "2";
    } else {
      return statusId.toString() == "3";
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade700;
    String statusText = status;

    switch (status.toLowerCase()) {
      case "active":
        backgroundColor = const Color(0xFFE8F5E8); // Light green background
        textColor = const Color(0xFF1EAC1E); // --Done-green
        statusText = "Confirmed";
        break;
      case "pending":
        backgroundColor = const Color(0xFFFFF3E0); // Light orange background
        textColor = const Color(0xFFFFA200); // --Main-Orange
        break;
      case "cancelled":
      case "canceled":
        backgroundColor = const Color(0xFFFFEBEE); // Light red background
        textColor = const Color(0xFFE53935);
        statusText = "Cancelled";
        break;
      case "not confirmed":
        backgroundColor = const Color(0xFFFFF3E0); // Light orange background
        textColor = const Color(0xFFFFA200); // --Main-Orange
        statusText = "Not Confirmed";
        break;
      default:
        backgroundColor = const Color(0xFFE8F5E8); // Light green background
        textColor = const Color(0xFF1EAC1E); // --Done-green
        statusText = "Confirmed";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildServiceTypeBadge(String serviceType, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        serviceType,
        style: const TextStyle(
          color: Color(0xFF1E49A0),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimeRemainingBadge(String? timeInfo, String status) {
    if (status.toLowerCase() != "not confirmed" ||
        timeInfo == null ||
        timeInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        "Time remaining for payment - $timeInfo",
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermanentContractCard(Map<String, dynamic> booking) {
    String status = booking["status"] ?? "success";
    bool isCancelled =
        _isContractCancelled(booking, false); // false for permanent contracts

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time remaining badge
          _buildTimeRemainingBadge(booking["time_info"], status),
          // Header with service type and status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceTypeBadge(
                  "Permanent Service", const Color(0xFFD9F0F9)),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 16),

          // Contract details
          _buildInfoRow("Service Contract ID", booking["contract_id"] ?? ""),
          _buildInfoRow("Contract ID", booking["contract_id"] ?? ""),
          _buildInfoRow("Customer", booking["nationality_name"] ?? ""),
          _buildInfoRow("Service ID", booking["profession_name"] ?? ""),
          _buildInfoRow("Total Price", "${booking["amount_to_pay"] ?? 0}"),
          _buildInfoRow("VAT", "${booking["vat_amount"] ?? 0}"),
          _buildInfoRow("Start Date", booking["period_days"]?.toString() ?? ""),
          _buildInfoRow("Status", status),

          // Show cancelled time if status is cancelled
          if (isCancelled)
            _buildInfoRow("Cancelled Time",
                _formatDeadlineTime(booking["time_info"], status)),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: status.toLowerCase() == "cancelled" ||
                        status.toLowerCase() == "canceled" ||
                        isCancelled
                    ? null
                    : () => _startCheckout(booking, isHourly: false),
                child: Text(
                  "Pay Now",
                  style: TextStyle(
                    color: (status.toLowerCase() == "cancelled" ||
                            status.toLowerCase() == "canceled" ||
                            isCancelled)
                        ? Colors.grey
                        : const Color(0xFF2196F3),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isCancelled
                    ? null
                    : () {
                        ref.read(contractsProvider.notifier).cancelPermContract(
                              booking["contract_id"].toString(),
                              isHourly: false,
                            );
                      },
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: isCancelled
                        ? Colors.grey
                        : const Color(0xFF2196F3), // Same blue color as Pay Now
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyContractCard(
      Map<String, dynamic> booking, AppLocalizations loc) {
    String status = booking["status"] ?? "success";
    bool isCancelled =
        _isContractCancelled(booking, true); // true for hourly contracts

    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return "Not specified";
      try {
        final date = DateTime.parse(dateStr);
        return "${date.day}/${date.month}/${date.year}";
      } catch (_) {
        return dateStr;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time remaining badge
          _buildTimeRemainingBadge(booking["time_info"], status),
          // Header with service type and status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceTypeBadge(loc.hourlyService ?? "Hourly Service",
                  const Color(0xFFD9F0F9)),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 16),

          // Contract details
          _buildInfoRow(loc.serviceContractId ?? "Service Contract ID",
              booking["service_contract_id"]?.toString() ?? ""),
          _buildInfoRow(loc.contractId ?? "Contract ID",
              booking["contract_id"]?.toString() ?? ""),
          _buildInfoRow(
              loc.customer ?? "Customer", booking["customer_display"] ?? ""),
          _buildInfoRow(loc.service ?? "Service ID",
              booking["service_id"]?.toString() ?? ""),
          _buildInfoRow(loc.totalPrice ?? "Total Price",
              "${booking["total_price"] ?? 0}"),
          _buildInfoRow(loc.vat ?? "VAT", "${booking["vat_price"] ?? 0}"),
          _buildInfoRow(loc.startDate ?? "Start Date",
              formatDate(booking["contract_start_date"])),
          _buildInfoRow("Status", status),

          // Show cancelled time if status is cancelled
          if (isCancelled)
            _buildInfoRow("Cancelled Time",
                _formatDeadlineTime(booking["time_info"], status)),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: status.toLowerCase() == "cancelled" ||
                        status.toLowerCase() == "canceled" ||
                        isCancelled
                    ? null
                    : () => _startCheckout(booking, isHourly: true),
                child: Text(
                  loc.payNow ?? "Pay Now",
                  style: TextStyle(
                    color: (status.toLowerCase() == "cancelled" ||
                            status.toLowerCase() == "canceled" ||
                            isCancelled)
                        ? Colors.grey
                        : const Color(0xFF2196F3),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isCancelled
                    ? null
                    : () {
                        ref
                            .read(contractsProvider.notifier)
                            .cancelHourlyContract(
                              booking["service_contract_id"].toString(),
                              isHourly: false,
                            );
                      },
                child: Text(
                  loc.cancel ?? "Cancel",
                  style: TextStyle(
                    color: isCancelled
                        ? Colors.grey
                        : const Color(0xFF2196F3), // Same blue color as Pay Now
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use SVG image from assets instead of icon
          SvgPicture.asset(
            'assets/images/empty_bookings.svg', // Update this path to match your SVG file location
            width: 200, // Adjust size as needed
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            "No bookings found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your bookings will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFilteredContracts(List<Map<String, dynamic>> permanent,
      List<Map<String, dynamic>> hourly, AppLocalizations loc) {
    List<Widget> contracts = [];

    if (_selectedTab == 'all' || _selectedTab == 'permanent') {
      contracts.addAll(
          permanent.map((permanent) => _buildPermanentContractCard(permanent)));
    }

    if (_selectedTab == 'all' || _selectedTab == 'hourly') {
      contracts.addAll(
          hourly.map((booking) => _buildHourlyContractCard(booking, loc)));
    }

    return contracts;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = ref.watch(contractsProvider);
    final notifier = ref.read(contractsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
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
                // Left back button
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFFFFA200), size: 20),
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                    ),
                  ),
                ),
                
                // Centered title
                const Center(
                  child: Text(
                    "My Booking",
                    style: TextStyle(
                      color: Color(0xFFFFA200),
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area with tab selector overlapping header
          Expanded(
  child: Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF8FAFC),
    ),
    child: Column(
      children: [
        // Tab selector
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0EAFF), // Light blue background
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
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 'all'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 'all'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _selectedTab == 'all'
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
                      'All',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 'all'
                            ? const Color(0xFF10295C)
                            : const Color(0xFF9CA3AF),
                        fontWeight: _selectedTab == 'all'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 'permanent'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 'permanent'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _selectedTab == 'permanent'
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
                      'Permanent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 'permanent'
                            ? const Color(0xFF10295C)
                            : const Color(0xFF9CA3AF),
                        fontWeight: _selectedTab == 'permanent'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 'hourly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 'hourly'
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _selectedTab == 'hourly'
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
                      'Hourly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 'hourly'
                            ? const Color(0xFF10295C)
                            : const Color(0xFF9CA3AF),
                        fontWeight: _selectedTab == 'hourly'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contracts list
        Expanded(
          child: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1A365D)))
              : RefreshIndicator(
                  onRefresh: notifier.fetchContracts,
                  color: const Color(0xFF1A365D),
                  child: Builder(
                    builder: (context) {
                      final filtered = _getFilteredContracts(
                          state.permanent, state.hourly, loc);
                      if (filtered.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: _buildEmptyState(),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                        children: filtered,
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  ),
),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.fetchContracts,
        tooltip: 'Refresh',
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
