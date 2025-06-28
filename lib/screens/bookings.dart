import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

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
    _fetchAllContracts();
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (refreshToken == null) {
        print('❌ [REFRESH_TOKEN] No refresh token found');
        return false;
      }

      print('🔄 [REFRESH_TOKEN] Attempting to refresh token...');
      
      final url = Uri.parse('$_baseUrl/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refresh_token': refreshToken,
        }),
      );

      print('📡 [REFRESH_TOKEN] Response status: ${response.statusCode}');
      print('📡 [REFRESH_TOKEN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Save new tokens
        await _secureStorage.write(key: 'token', value: responseData['token']);
        await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);
        
        print('✅ [REFRESH_TOKEN] Token refreshed successfully');
        return true;
      } else {
        print('❌ [REFRESH_TOKEN] Failed to refresh token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 [REFRESH_TOKEN] Error refreshing token: $e');
      return false;
    }
  }

  // Enhanced HTTP request method with automatic token refresh
  static Future<http.Response> makeAuthenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
    int retryCount = 0,
  }) async {
    final token = await _secureStorage.read(key: 'token');
    
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'token': token,
      ...?headers,
    };

    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(Uri.parse(url), headers: requestHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(Uri.parse(url), headers: requestHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If we get a 401 (unauthorized) and haven't already retried
    if (response.statusCode == 401 && retryCount == 0) {
      print('🔄 [AUTH_REQUEST] Received 401, attempting token refresh...');
      
      final refreshSuccess = await refreshToken();
      if (refreshSuccess) {
        print('✅ [AUTH_REQUEST] Token refreshed, retrying original request...');
        // Retry the original request with the new token
        return makeAuthenticatedRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          retryCount: 1, // Prevent infinite retry loop
        );
      } else {
        print('❌ [AUTH_REQUEST] Token refresh failed, clearing storage...');
        // Clear all stored tokens if refresh fails
        await _secureStorage.deleteAll();
      }
    }

    return response;
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
      final userId = await _secureStorage.read(key: 'user_id') ?? '';

      if (userId.isEmpty) {
        throw Exception("Missing customer ID in storage");
      }

      print('🔍 [PERMANENT_CONTRACTS] Fetching contracts for user: $userId');

      final url = "$_baseUrl/domestic/contracts/$userId";
      
      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
      );

      print('📡 [PERMANENT_CONTRACTS] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        String rawJson = response.body;
        print('📦 [PERMANENT_CONTRACTS] Raw response length: ${rawJson.length}');

        // Fix missing price_before_vat fields (e.g. "price_before_vat":,)
        rawJson = rawJson.replaceAllMapped(
          RegExp(r'"price_before_vat"\s*:\s*,'),
          (match) => '"price_before_vat": null,',
        );

        final List<dynamic> data = json.decode(rawJson);
        print('✅ [PERMANENT_CONTRACTS] Successfully fetched ${data.length} contracts');

        setState(() {
          _permanentContracts = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('❌ [PERMANENT_CONTRACTS] Failed with status: ${response.statusCode}');
        throw Exception("Failed to load permanent contracts: ${response.statusCode}");
      }
    } catch (e) {
      print("💥 [PERMANENT_CONTRACTS] Error fetching permanent contracts: $e");
      // Don't set empty list, keep existing data
    }
  }

  Future<void> _fetchHourlyContracts() async {
    try {
      final userId = await _secureStorage.read(key: 'user_id') ?? '';

      print("=== HOURLY CONTRACTS DEBUG ===");
      print("User ID: $userId");

      if (userId.isEmpty) {
        throw Exception("Missing customer ID in storage");
      }

      final url = "$_baseUrl/hourly/contracts/$userId";
      print("Request URL: $url");

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Headers: ${response.headers}");
      print("Response Body Length: ${response.body.length}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print("Parsed Data Type: ${data.runtimeType}");
          print("Number of hourly contracts: ${data.length}");

          // Print each contract with its structure
          for (int i = 0; i < data.length; i++) {
            print("--- Hourly Contract $i ---");
            print("Contract Type: ${data[i].runtimeType}");
            if (data[i] is Map) {
              final contract = data[i] as Map<String, dynamic>;
              print("Contract Keys: ${contract.keys.toList()}");
              contract.forEach((key, value) {
                print("  $key: $value (${value.runtimeType})");
              });
            } else {
              print("Contract Data: ${data[i]}");
            }
          }

          setState(() {
            _hourlyContracts = data.cast<Map<String, dynamic>>();
          });
          print("✅ [HOURLY_CONTRACTS] Successfully stored ${_hourlyContracts.length} hourly contracts");
        } catch (jsonError) {
          print("JSON Parsing Error: $jsonError");
          print("Attempting to parse as single object...");
          try {
            final Map<String, dynamic> singleData = json.decode(response.body);
            print("Single Object Keys: ${singleData.keys.toList()}");
            singleData.forEach((key, value) {
              print("  $key: $value (${value.runtimeType})");
            });
          } catch (e) {
            print("Failed to parse as single object: $e");
          }
        }
      } else {
        print("HTTP Error Details:");
        print("Status Code: ${response.statusCode}");
        print("Reason Phrase: ${response.reasonPhrase}");
        print("Error Response Body: ${response.body}");
        throw Exception("Failed to load hourly contracts: ${response.statusCode}");
      }
    } catch (e) {
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
            _infoRow("Service ID", booking["service_id"]?.toString() ?? ""),
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