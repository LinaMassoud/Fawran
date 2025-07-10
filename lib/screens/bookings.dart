import 'package:fawran/providers/contractsProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
    ref.read(contractsProvider.notifier).fetchContracts();
  });
    _selectedTab = widget.initialTab ?? 'all';
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
    String status = booking["status"] ?? "success";

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
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                ),
              ],
            ),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Placeholder for payment logic
                  },
                  child: const Text("Pay Now"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: status == "cancelled" || status == "canceled"
                      ? null // Disable the button if status is "canceled"
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
    String getStatusText(String status) {
      final statusInt = int.parse(status);
        switch (statusInt) {
          case 0:
            return loc.notConfirmed ?? "Not confirmed";
          case 1:
            return loc.confirmed ?? "Confirmed";
          case 2:
            return loc.cancelled ?? "Cancelled";
          case 3:
            return loc.paid ?? "Paid";
           default:
           return  "Unknown";  
        }
      }
    

    Color getStatusColor(dynamic status) {
      
      if (status == null) return Colors.grey;
      final statusInt = int.parse(status);
        switch (statusInt) {
          case 0:
            return Colors.orange;
          case 1:
            return Colors.blue;
          case 2:
            return Colors.red;
          case 3:
            return Colors.green;
        
      }
      return Colors.grey;
    }

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
            // Header with status
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
                  child: Text(
                    loc.hourlyService ?? "Hourly Service",
                    style: const TextStyle(
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
            _infoRow(loc.serviceContractId ?? "Service Contract ID",
                booking["service_contract_id"]?.toString() ?? ""),
            _infoRow(loc.contractId ?? "Contract ID", booking["contract_id"]?.toString() ?? ""),
            _infoRow(loc.customer ?? "Customer", booking["customer_display"] ?? ""),
            _infoRow(loc.service ?? "Service", booking["service_id"]?.toString() ?? ""),
            _infoRow(loc.totalPrice ?? "Total Price", "${booking["total_price"] ?? 0} Riyal"),
            _infoRow(loc.vat ?? "VAT", "${booking["vat_price"] ?? 0}  Riyal"),
            _infoRow(loc.startDate ?? "Start Date", formatDate(booking["contract_start_date"])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Placeholder
                  },
                  child: Text(loc.payNow ?? "Pay Now"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: booking["status"] == "2"
                      ? null // Disable the button if status is "canceled"
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // reduced from 16
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
                final filtered =
                    _getFilteredContracts(state.permanent, state.hourly,loc);
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
