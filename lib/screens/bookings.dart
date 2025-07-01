import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  final String? initialTab;
  const BookingsScreen({
    super.key,
    this.initialTab, // Add this parameter
  });

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static const String _baseUrl = 'http://fawran.ddns.net:8080/ords/emdad/fawran';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  List<Map<String, dynamic>> _permanentContracts = [];
  List<Map<String, dynamic>> _hourlyContracts = [];
  bool _isLoading = true;
  String _selectedTab = 'all'; // 'all', 'permanent', 'hourly'

   @override
  void initState() {
    super.initState();
    // Set initial tab based on parameter, default to 'all'
    _selectedTab = widget.initialTab ?? 'all';
    _fetchAllContracts();
  }


  Future<void> _fetchAllContracts() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _fetchPermanentContracts(),
      _fetchHourlyContracts(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPermanentContracts() async {
    try {
      final contracts = await ApiService.fetchPermanentContracts();
      setState(() {
        _permanentContracts = contracts;
      });
    } catch (e) {
      print("💥 [PERMANENT_CONTRACTS] Error fetching permanent contracts: $e");
      // Don't set empty list, keep existing data
    }
  }

  Future<void> _fetchHourlyContracts() async {
    try {
      final contracts = await ApiService.fetchHourlyContracts();
      setState(() {
        _hourlyContracts = contracts;
      });
    }  catch (e) {
      print("💥 [HOURLY_CONTRACTS] Error fetching hourly contracts: $e");
      print("Error Type: ${e.runtimeType}");
      if (e is http.ClientException) {
        print("Network Error Details: ${e.message}");
      }
    }
    print("=== END HOURLY CONTRACTS DEBUG ===\n");
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

  Widget _buildPermanentContractCard(Map<String, dynamic> booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Permanent Service",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _infoRow("Contract ID", booking["contract_id"] ?? ""),
            _infoRow("Nationality", booking["nationality_name"] ?? ""),
            _infoRow("Profession", booking["profession_name"] ?? ""),
            _infoRow("Package", booking["package_name"] ?? ""),
            _infoRow("Days", booking["period_days"].toString()),
            _infoRow("Price", "${booking["amount_to_pay"]} Riyal"),
            if(booking["delivery_charges"] > 0 )  _infoRow("Delivery", booking["delivery_charges"].toString()),
            _infoRow("Status", booking["status"] ?? "success"),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyContractCard(Map<String, dynamic> booking) {
    // Helper function to format status
    String getStatusText(dynamic status) {
      if (status == null) return "Unknown";
      if (status is int) {
        switch (status) {
          case 0:
            return "Not confirmed";
          case 1:
            return "Confirmed";
          case 2:
            return "paid";
          case 3:
            return "Cancelled";
          default:
            return "Status $status";
        }
      }
      return status.toString();
    }

    // Helper function to get status color
    Color getStatusColor(dynamic status) {
      if (status == null) return Colors.grey;
      if (status is int) {
        switch (status) {
          case 0:
            return Colors.orange;
          case 1:
            return Colors.blue;
          case 2:
            return Colors.green;
          case 3:
            return Colors.red;
          default:
            return Colors.grey;
        }
      }
      return Colors.grey;
    }

    // Helper function to format date
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return "Not specified";
      try {
        final date = DateTime.parse(dateStr);
        return "${date.day}/${date.month}/${date.year}";
      } catch (e) {
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
            // Service type indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Hourly Service",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(booking["status"]).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getStatusText(booking["status"]),
                    style: TextStyle(
                      color: getStatusColor(booking["status"]),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow("Service Contract ID",
                booking["service_contract_id"]?.toString() ?? ""),
            _infoRow("Contract ID", booking["contract_id"]?.toString() ?? ""),
            _infoRow("Customer", booking["customer_display"] ?? ""),
            _infoRow("Service", booking["service_id"]?.toString() ?? ""),
            _infoRow("Total Price", "${booking["total_price"] ?? 0} Riyal"),
            _infoRow("VAT", "${booking["vat_price"] ?? 0} Riyal"),
            _infoRow("Start Date", formatDate(booking["contract_start_date"])),
            _infoRow("Status", getStatusText(booking["status"])),
          ],
        ),
      ),
    );
  }

  List<Widget> _getFilteredContracts() {
    List<Widget> contracts = [];

    if (_selectedTab == 'all' || _selectedTab == 'permanent') {
      contracts.addAll(_permanentContracts
          .map((booking) => _buildPermanentContractCard(booking))
          .toList());
    }

    if (_selectedTab == 'all' || _selectedTab == 'hourly') {
      contracts.addAll(_hourlyContracts
          .map((booking) => _buildHourlyContractCard(booking))
          .toList());
    }

    return contracts;
  }

  @override
  Widget build(BuildContext context) {
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: 'permanent',
                        label: Text('Permanent'),
                      ),
                      ButtonSegment(
                        value: 'hourly',
                        label: Text('Hourly'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllContracts,
              child: Builder(
                builder: (context) {
                  final filteredContracts = _getFilteredContracts();

                  if (filteredContracts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No bookings found",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: filteredContracts,
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAllContracts,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}