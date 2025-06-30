import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/nationality_provider.dart';
import '../providers/labour_provider.dart';
import '../providers/package_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CombinedOrderScreen extends ConsumerStatefulWidget {
  final String? header;

  const CombinedOrderScreen({super.key,  this.header});

  @override
  ConsumerState<CombinedOrderScreen> createState() =>
      _CombinedOrderScreenState();
}

class _CombinedOrderScreenState extends ConsumerState<CombinedOrderScreen> {
  int? selectedNationality;
  int? selectedPackageIndex;
  int? selectedLaborId;
  String? selectedLaborSource; // "company" or "app"
  String? pickupOption; // "pickup" or "delivery"
  bool deliveryAvailable = false;
  bool loadingDeliveryCheck = false;

  @override
  Widget build(BuildContext context) {
    final nationalityAsync = ref.watch(nationalitiesProvider);
    final packagesAsync = ref.watch(packageProvider);
    final laborersAsync = ref.watch(laborersProvider);
    final _storage = FlutterSecureStorage();

    final selectedProfession = ref.watch(selectedProfessionProvider);

    Future<void> submitOrder() async {
      final token = await _storage.read(key: 'token') ?? '';
      final userId = await _storage.read(key: 'user_id') ?? '';

      final selectedPackage = ref.read(selectedPackageProvider);
      final selectedNationalityData = ref
          .read(nationalitiesProvider)
          .asData
          ?.value
          .firstWhere((n) => n?.id == selectedNationality);
      final customerId = 1; // Replace with actual customer ID if available

      if (selectedPackage == null || selectedNationalityData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing required data.")),
        );
        return;
      }

      final double deliveryCharge = pickupOption == "delivery" ? 50.0 : 0.0;
      final double amountToPay =
          selectedPackage.vatAmount+ selectedPackage.contractAmount + deliveryCharge;

      final Map<String, dynamic> requestBody = {
        "customer_id": userId,
        "profession_id": selectedProfession?.positionId,
        "profession_name": selectedProfession?.positionName,
        "nationality_id": selectedNationalityData.id,
        "nationality": selectedNationalityData.name,
        "package_id": selectedPackage.packageId,
        "package_name": selectedPackage.packageName,
        "period_days": selectedPackage.contractDays,
        "tax_rate": 15.0,
        "final_price": selectedPackage.finalInvoice,
        "delivery_charge": deliveryCharge,
        "amount_to_pay": amountToPay,
      };

      try {
        final response = await http.post(
          Uri.parse(
              'http://fawran.ddns.net:8080/ords/emdad/fawran/domestic/contract/create'),
          headers: {"Content-Type": "application/json", 'token': token},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order submitted successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Submission failed: ${response.body}")),
          );
        }
        Navigator.pushReplacementNamed(context, '/bookings');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting order: $e")),
        );
      }
    }
    return Scaffold(
  appBar: AppBar(
    title: Text("${selectedProfession?.positionName}"),
    backgroundColor: Colors.blue[900],
  ),
  body: SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STEP 1: NATIONALITY
        sectionHeader("Step 1: Nationality"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: nationalityAsync.when(
            data: (list) => DropdownButtonFormField<int>(
              decoration: inputDecoration("Select nationality"),
              value: selectedNationality,
              onChanged: (v) {
                ref.read(selectedNationalityProvider.notifier).state = v;
                setState(() {
                  selectedNationality = v;
                  selectedPackageIndex = null;
                  selectedLaborSource = null;
                  selectedLaborId = null;
                  pickupOption = null;
                });
              },
              items: list
                  .map((n) => DropdownMenuItem<int>(
                        value: n?.id,
                        child: Text(n?.name ?? ''),
                      ))
                  .toList(),
            ),
            loading: () =>
                const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          ),
        ),

        // STEP 2: CHOOSE PACKAGE
        if (selectedNationality != null) ...[
          sectionHeader("Step 2: Choose Package"),
          packagesAsync.when(
            data: (packages) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              itemBuilder: (c, i) {
                final pkg = packages[i];
                final selected = selectedPackageIndex == i;

                return Card(
                  color: selected ? Colors.blue[50] : Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(pkg.packageName,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            Radio<int>(
                              value: i,
                              groupValue: selectedPackageIndex,
                              onChanged: (v) {
                                setState(() {
                                  selectedPackageIndex = v;
                                  selectedLaborSource = null;
                                  selectedLaborId = null;
                                  pickupOption = null;
                                });
                                ref.read(selectedPackageProvider.notifier).state = pkg;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _packageDetailRow("Duration (days)", "${pkg.contractDays}"),
                        _packageDetailRow("Price (Before VAT)",
                            "${pkg.contractAmount.toStringAsFixed(2)} Riyal"),
                        _packageDetailRow("VAT Amount",
                            "${pkg.vatAmount.toStringAsFixed(2)} Riyal"),
                        _packageDetailRow("Package Price",
                            "${(pkg.contractAmount + pkg.vatAmount).toString()} Riyal"),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          )
        ] ,

        // STEP 3: LABOR SOURCE
        if (selectedPackageIndex != null) ...[
          sectionHeader("Step 3: Choose Labor Source"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text("From Company"),
                  value: "company",
                  groupValue: selectedLaborSource,
                  onChanged: (v) {
                    setState(() {
                      selectedLaborSource = v;
                      selectedLaborId = null;
                      ref.read(selectedLaborerProvider.notifier).state = null;
                    });
                    checkCarAvailability();
                  },
                ),
                RadioListTile<String>(
                  title: const Text("From App"),
                  value: "app",
                  groupValue: selectedLaborSource,
                  onChanged: (v) {
                    setState(() {
                      selectedLaborSource = v;
                      selectedLaborId = null;
                      ref.read(selectedLaborerProvider.notifier).state = null;
                    });
                    checkCarAvailability();
                  },
                ),
              ],
            ),
          ),
        ] ,

        // STEP 4: SELECT DRIVER (only if from App)
        if (selectedLaborSource == "app") ...[
          sectionHeader("Step 4: Choose ${selectedProfession?.positionName}"),
          laborersAsync.when(
            data: (drivers) {
              if (drivers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text("No Available Laborers",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Text("There are currently no laborers available. Please check back later.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: drivers.length,
                itemBuilder: (c, i) {
                  final d = drivers[i];
                  final sel = selectedLaborId == d.personId;
                  return Card(
                    color: sel ? Colors.blue[50] : Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: selectedProfession?.positionId ==7 ? const AssetImage('assets/images/default_maid.jpg')
                            :  const AssetImage('assets/images/default_avatar.jpg')
                                as ImageProvider,
                      ),
                      title: Text(d.employeeName),
                      subtitle: Text("Employee Number: ${d.employeeNumber}"),
                      trailing: Radio<int>(
                        value: d.personId,
                        groupValue: selectedLaborId,
                        onChanged: (v) {
                          setState(() => selectedLaborId = v);
                          ref.read(selectedLaborerProvider.notifier).state = d;
                          checkCarAvailability();
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          )
        ],

        // STEP 5: PICKUP / DELIVERY (conditionally shown as Step 4 or 5)
        if ((selectedLaborSource == "company") ||
            (selectedLaborSource == "app" && selectedLaborId != null)) ...[
          sectionHeader("Step ${selectedLaborSource == "app" ? "5" : "4"}: Pickup or Delivery"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: loadingDeliveryCheck
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text("Pick up laborer yourself"),
                        value: "pickup",
                        groupValue: pickupOption,
                        onChanged: (val) => setState(() => pickupOption = val),
                      ),
                      RadioListTile<String>(
                        title: const Text("Deliver laborer to home"),
                        value: "delivery",
                        groupValue: pickupOption,
                        onChanged: deliveryAvailable
                            ? (val) => setState(() => pickupOption = val)
                            : null,
                        subtitle: !deliveryAvailable
                            ? const Text("Delivery option is not available currently.",
                                style: TextStyle(color: Colors.red))
                            : null,
                      ),
                    ],
                  ),
          ),
        ],

        // STEP 6: AGREEMENT
        if ((selectedLaborSource == "company") ||
            (selectedLaborSource == "app" && selectedLaborId != null)) ...[
          sectionHeader("Step ${selectedLaborSource == "app" ? "6" : "5"}: Agreement"),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedLaborSource == "company")
                    _infoRow("Labor Source", "From Company")
                  else
                    _infoRow("${selectedProfession?.positionName}",
                        ref.read(selectedLaborerProvider)?.arabicName ?? ''),
                  if (selectedLaborSource == "app")
                    _infoRow("Nationality",
                        ref.read(selectedLaborerProvider)?.nationality ?? ''),
                  _infoRow("Package",
                      ref.read(selectedPackageProvider)?.packageName ?? ''),
                  _infoRow("Days",
                      '${ref.read(selectedPackageProvider)?.contractDays ?? ''}'),
                  _infoRow("Price",
                      '${ref.read(selectedPackageProvider)?.contractAmount.toStringAsFixed(2) ?? ''} Riyal'),
                  _infoRow("Pickup/Delivery", pickupOption == "pickup"
                      ? "Pick up yourself"
                      : pickupOption == "delivery"
                          ? "50.0"
                          : "Not selected"),
                ],
              ),
            ),
          ),
        ],

        // SUBMIT BUTTON
        if (((selectedLaborSource == "company") ||
                (selectedLaborSource == "app" && selectedLaborId != null)) &&
            pickupOption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Order Submitted")));
                  submitOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("SUBMIT ORDER",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    ),
  ),
);


    }

  @override
  void didUpdateWidget(covariant CombinedOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Whenever labor source or labor selection changes, check delivery availability
    if ((selectedLaborSource == "company") ||
        (selectedLaborSource == "app" && selectedLaborId != null)) {
      checkCarAvailability();
    } else {
      setState(() {
        deliveryAvailable = false;
        pickupOption = null;
      });
    }
  }

  Future<void> checkCarAvailability() async {
    final selectedAddress = ref.watch(selectedAddressProvider);
    setState(() {
      loadingDeliveryCheck = true;
      deliveryAvailable = false;
      pickupOption = null;
    });

    try {
      // Example POST or GET depending on your API design
      final response = await http.post(
        Uri.parse('http://fawran.ddns.net:8080/ords/emdad/fawran/available-cars'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "city_code": selectedAddress?.cityCode,
          "num_of_workers": 2,
          "required_shift": "Morning",
          "required_days": "Sunday,Monday,Wednesday"
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming API returns: { "car_available": true/false }
        bool available = data.length > 0;
        setState(() {
          deliveryAvailable = available;
        });
      } else {
        setState(() {
          deliveryAvailable = false;
        });
      }
    } catch (e) {
      setState(() {
        deliveryAvailable = false;
      });
    } finally {
      setState(() {
        loadingDeliveryCheck = false;
      });
    }
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget disabledStepCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

Widget _packageDetailRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
            child: Text(title, style: const TextStyle(color: Colors.grey))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
