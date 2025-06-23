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
  final _storage = FlutterSecureStorage();

  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  Future<void> _fetchContracts() async {
    try {
      final token = await _storage.read(key: 'token') ?? '';
      final userId = await _storage.read(key: 'user_id') ?? '';

      if (token == null || userId == null) {
        throw Exception("Missing token or customer ID in SharedPreferences");
      }

      final url = Uri.parse(
        "http://10.20.10.114:8080/ords/emdad/fawran/domestic/contracts/$userId",
      );

      final response = await http.get(
        url,
        headers: {
          "token": token,
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _contracts = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load contracts: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching contracts: $e");
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
              ? const Center(child: Text("No contracts found."))
              : ListView.builder(
                  itemCount: _contracts.length,
                  itemBuilder: (context, index) {
                    final booking = _contracts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                                "Contract ID", booking["contract_id"] ?? ""),
                            _infoRow("Nationality",
                                booking["nationality_name"] ?? ""),
                            _infoRow(
                                "Profession", booking["profession_name"] ?? ""),
                            _infoRow("Package", booking["package_name"] ?? ""),
                            _infoRow("Days", booking["period_days"].toString()),
                            _infoRow(
                                "Price", "${booking["final_price"]} Riyal"),
                            _infoRow("Delivery",
                                "${booking["delivery_charges"]} Riyal"),
                            _infoRow("Status", booking["status"] ?? ""),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
