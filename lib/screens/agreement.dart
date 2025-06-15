import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // Import Riverpod
import '../providers/package_provider.dart';  // Import the selected package provider
import '../providers/labour_provider.dart';  // Import the selected laborer provider

class ContractScreen extends ConsumerWidget {  // Use ConsumerWidget to access providers
  final String header;

  const ContractScreen({super.key, required this.header});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the selected package from the provider
    final selectedPackage = ref.watch(selectedPackageProvider);
    // Access the selected laborer (driver) from the provider
    final selectedLaborer = ref.watch(selectedLaborerProvider);

    // Provide fallback values in case the provider is null
    final driverName = selectedLaborer?.arabicName ?? "Unknown Driver";
    final packageName = selectedPackage?.packageName ?? "Unknown Package";
    final periodInDays = selectedPackage?.contractDays ?? 0;
    final priceWithVAT = selectedPackage?.packagePriceWithVat ?? 0.0;
    final finalPrice = selectedPackage?.contractAmount ?? 0.0;
    final discountPrice = selectedPackage?.packagePriceWithVat ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom Header with Back Arrow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Agreement",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Title and CircularProgress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Agreement',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Next - Payment',
                          style: TextStyle(color: Colors.grey)),
                    ]),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: 4 / 5,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const Text('4 of 5',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Driver Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue[900]),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text("Private Driver"),
                        const Text("Age 37"),  // Can be updated if available
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Contract Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text("Contract details",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    _contractItem("Package Name", packageName),
                    _contractItem("Period in days", "$periodInDays"),
                    _contractItem("Package Price with VAT",
                        "${priceWithVAT.toStringAsFixed(2)} Riyal"),
                    _contractItem("Final Package Price",
                        "${finalPrice.toStringAsFixed(2)} Riyal"),
                    _contractItem("Price After Discount",
                        "${discountPrice.toStringAsFixed(2)} Riyal"),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Agreed contract statement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text.rich(
              TextSpan(
                text: 'Agreed contract ',
                style: TextStyle(fontSize: 14),
                children: const [
                  TextSpan(
                    text: 'Contract',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Agree Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle agreement action
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Contract Agreed")));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("AGREE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _contractItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.blue),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
