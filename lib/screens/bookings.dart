import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  // Sample static bookings list
  final List<Map<String, dynamic>> bookings = const [
    {
      "laborSource": "company",
      "driver": "Ahmed Ali",
      "nationality": "Bangladeshi",
      "packageName": "Standard Package",
      "contractDays": 5,
      "packagePriceWithVat": 499.99,
      "pickupOption": "delivery",
      "date": "2025-06-23"
    },
    {
      "laborSource": "app",
      "driver": "Fatima Noor",
      "nationality": "Filipino",
      "packageName": "Premium Package",
      "contractDays": 10,
      "packagePriceWithVat": 899.50,
      "pickupOption": "pickup",
      "date": "2025-06-20"
    },
  ];

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      appBar: AppBar(
        title: const Text("My Bookings"),
      ),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booking["laborSource"] == "company")
                    _infoRow("Labor Source", "From Company")
                  else
                    _infoRow("Driver", booking["driver"] ?? ""),
                  if (booking["laborSource"] == "app")
                    _infoRow("Nationality", booking["nationality"] ?? ""),
                  _infoRow("Package", booking["packageName"] ?? ""),
                  _infoRow("Days", booking["contractDays"].toString()),
                  _infoRow("Price",
                      "${booking["packagePriceWithVat"].toStringAsFixed(2)} Riyal"),
                  _infoRow(
                      "Pickup/Delivery",
                      booking["pickupOption"] == "pickup"
                          ? "Pick up yourself"
                          : booking["pickupOption"] == "delivery"
                              ? "Delivery to home"
                              : "Not selected"),
                  _infoRow("Date", booking["date"]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
