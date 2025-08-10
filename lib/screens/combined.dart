import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/contractsProvider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/screens/laborerProfile.dart';
import 'package:fawran/services/api_service.dart';
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

  const CombinedOrderScreen({super.key, this.header});

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
  bool isLoading = false;
  int? minAge;
  int? minExperience;
  String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final nationalityAsync = ref.watch(nationalitiesProvider);
    final packagesAsync = ref.watch(packageProvider);
    final laborersAsync = ref.watch(laborersProvider);
    final _storage = FlutterSecureStorage();

    final selectedProfession = ref.watch(selectedProfessionProvider);

    Future<void> submitOrder() async {
      setState(() {
        isLoading = true;
      });

      final userId = await _storage.read(key: 'user_id') ?? '';

      // 🔍 Step 1: Check for "not confirmed" contracts
      try {
        final contracts =
            await ApiService.fetchPermanentContracts(userId: userId);

        final hasNotConfirmedContracts = contracts.any((contract) {
          final status = contract['status']?.toString().toLowerCase();
          return status == 'not confirmed';
        });

        if (hasNotConfirmedContracts) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "You have an unconfirmed contract. Please confirm or cancel it before creating a new one."),
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking existing contracts: $e")),
        );
        return;
      }

      // 🔧 Prepare form data
      final selectedPackage = ref.read(selectedPackageProvider);
      final selectedNationalityData = ref
          .read(nationalitiesProvider)
          .asData
          ?.value
          .firstWhere((n) => n?.id == selectedNationality);

      if (selectedPackage == null || selectedNationalityData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing required data.")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final double deliveryCharge = pickupOption == "delivery" ? 50.0 : 0.0;
      final double amountToPay = selectedPackage.vatAmount +
          selectedPackage.contractAmount +
          deliveryCharge;

      final requestBody = {
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
        "vat_amount": selectedPackage.vatAmount
      };

      // 🚀 Submit contract
      try {
        final response = await ref
            .read(contractsProvider.notifier)
            .createPermanentContract(requestBody);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order submitted successfully!")),
          );
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacementNamed(context, '/bookings');
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Submission failed: ${response.body}")),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
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
                loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator()),
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
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
                                    ref
                                        .read(selectedPackageProvider.notifier)
                                        .state = pkg;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _packageDetailRow(
                                "Duration (days)", "${pkg.contractDays}"),
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
            ],

            // STEP 3: LABOR SOURCE
            if (selectedPackageIndex != null) ...[
              sectionHeader("Step 3: Choose Labor Source"),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ref.read(selectedLaborerProvider.notifier).state =
                              null;
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
                          ref.read(selectedLaborerProvider.notifier).state =
                              null;
                        });
                        checkCarAvailability();
                      },
                    ),
                  ],
                ),
              ),
            ],

            // STEP 4: SELECT DRIVER (only if from App)
            if (selectedLaborSource == "app") ...[
              sectionHeader(
                  "Step 4: Choose ${selectedProfession?.positionName}"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ExpansionTile(
                  title: const Text("Filters",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Wrap(
                      runSpacing: 12,
                      spacing: 16,
                      children: [
                        // Age Filter
                        // Age Filter
                        DropdownButton<int?>(
                          value: minAge,
                          hint:
                              Text(minAge == null ? "Any Age" : "${minAge!}+"),
                          items: [null, 20, 25, 30, 35, 40].map((age) {
                            return DropdownMenuItem(
                              value: age,
                              child: Text(age == null ? 'Any Age' : '$age+'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => minAge = value),
                        ),

// Experience Filter
                        DropdownButton<int?>(
                          value: minExperience,
                          hint: Text(minExperience == null
                              ? "Any Experience"
                              : "${minExperience!}+ yrs"),
                          items: [null, 1, 2, 3, 5, 10].map((exp) {
                            return DropdownMenuItem(
                              value: exp,
                              child: Text(
                                  exp == null ? 'Any Experience' : '$exp+ yrs'),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => minExperience = value),
                        ),

// Social Status Filter
                        DropdownButton<String?>(
                          value: selectedStatus,
                          hint: Text(selectedStatus ?? "Any Status"),
                          items: [null, 'Single', 'Divorced', 'Widowed']
                              .map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status ?? 'Any Status'),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedStatus = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              laborersAsync.when(
                data: (drivers) {
                  final filtered = drivers.where((d) {
                    final ageOk =
                        minAge == null || (d.age != null && d.age! >= minAge!);
                    final expOk = minExperience == null ||
                        (d.experience != null &&
                            d.experience! >= minExperience!);
                    final statusOk = selectedStatus == null ||
                        (d.socialStatus != null &&
                            d.socialStatus == selectedStatus);
                    return ageOk && expOk && statusOk;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text("No laborers match your filters.",
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) {
                      final d = filtered[i];
                      final sel = selectedLaborId == d.personId;

                      return Card(
                        color: sel ? Colors.blue[50] : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    selectedProfession?.positionId == 7
                                        ? const AssetImage(
                                            'assets/images/default_maid.jpg')
                                        : const AssetImage(
                                            'assets/images/default_avatar.jpg'),
                              ),
                              const SizedBox(width: 16),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.employeeName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        infoChip(
                                            Icons.cake, "${d.age ?? '-'} yrs"),
                                        infoChip(Icons.work_outline,
                                            "${d.experience ?? '-'} yrs"),
                                        infoChip(Icons.people_outline,
                                            d.socialStatus ?? '-'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Employee #: ${d.employeeNumber}",
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ),

                            // Action Buttons
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LaborProfilePage(laborer: d),
                                        ),
                                      );
                                    },
                                  ),
                                  Radio<int>(
                                    value: d.personId,
                                    groupValue: selectedLaborId,
                                    onChanged: (v) {
                                      setState(() => selectedLaborId = v);
                                      ref
                                          .read(
                                              selectedLaborerProvider.notifier)
                                          .state = d;
                                      checkCarAvailability();
                                    },
                                  ),
                                ],
                              ),
                            ],
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
              sectionHeader(
                  "Step ${selectedLaborSource == "app" ? "5" : "4"}: Pickup or Delivery"),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: loadingDeliveryCheck
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("Pick up laborer yourself"),
                            value: "pickup",
                            groupValue: pickupOption,
                            onChanged: (val) =>
                                setState(() => pickupOption = val),
                          ),
                          RadioListTile<String>(
                            title: const Text("Deliver laborer to home"),
                            value: "delivery",
                            groupValue: pickupOption,
                            onChanged: deliveryAvailable
                                ? (val) => setState(() => pickupOption = val)
                                : null,
                            subtitle: !deliveryAvailable
                                ? const Text(
                                    "Delivery option is not available currently.",
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
              sectionHeader(
                  "Step ${selectedLaborSource == "app" ? "6" : "5"}: Agreement"),
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
                        _infoRow(
                            "${selectedProfession?.positionName}",
                            ref.read(selectedLaborerProvider)?.arabicName ??
                                ''),
                      if (selectedLaborSource == "app")
                        _infoRow(
                            "Nationality",
                            ref.read(selectedLaborerProvider)?.nationality ??
                                ''),
                      _infoRow("Package",
                          ref.read(selectedPackageProvider)?.packageName ?? ''),
                      _infoRow("Days",
                          '${ref.read(selectedPackageProvider)?.contractDays ?? ''}'),
                      _infoRow("Price",
                          '${ref.read(selectedPackageProvider)?.contractAmount.toStringAsFixed(2) ?? ''} Riyal'),
                      _infoRow(
                          "Pickup/Delivery",
                          pickupOption == "pickup"
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
                    (selectedLaborSource == "app" &&
                        selectedLaborId != null)) &&
                pickupOption != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null // Disable button if loading
                        : () {
                            setState(() {
                              isLoading = true;
                            });
                            submitOrder();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "SUBMIT ORDER",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget infoChip(IconData icon, String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      avatar: Icon(icon, size: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.grey[100],
    );
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
        Uri.parse(
            'http://fawran.ddns.net:8080/ords/emdad/fawran/available-cars'),
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
