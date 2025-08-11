import 'dart:convert';

import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/Nationality.dart';
import 'package:fawran/models/domestic_package_model.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/contractsProvider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/labour_provider.dart';
import 'package:fawran/providers/nationality_provider.dart';
import 'package:fawran/providers/package_provider.dart';
import 'package:fawran/screens/laborerProfile.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class PrivateDriverScreen extends ConsumerStatefulWidget {
  const PrivateDriverScreen({super.key});

  @override
  ConsumerState<PrivateDriverScreen> createState() =>
      _PrivateDriverScreenState();
}

class _PrivateDriverScreenState extends ConsumerState<PrivateDriverScreen> {
  int currentStep = 0;
  final int totalSteps = 6;

  int? selectedNationality;
  String? selectedPackage;
  String? selectedLaborSource;
  String? selectedDriver;
  String? selectedDelivery;
  int? filterAge;
  String? filterSocialStatus;
  int? filterExperience;

  int? selectedPackageIndex;
  int? selectedLaborId;
  String? pickupOption; // "pickup" or "delivery"
  bool deliveryAvailable = false;
  bool loadingDeliveryCheck = false;
  bool isLoading = false;
  int? minAge;
  int? minExperience;
  String? selectedStatus;
  final _storage = FlutterSecureStorage();
  Widget _buildHeader(BuildContext context) {
    final selectedProfession = ref.watch(selectedProfessionProvider);

    return Container(
      height: 124,
      decoration: const BoxDecoration(
        color: Color(0xFF10295C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(
          top: 70, bottom: 20), // remove left/right padding
      child: Stack(
        children: [
          // Back arrow flush left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Centered title
          Align(
            alignment: Alignment.center,
            child: Text(
              "${selectedProfession?.positionName}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitOrder() async {
    setState(() {
      isLoading = true;
    });

    final userId = await _storage.read(key: 'user_id') ?? '';
    final selectedProfession = ref.watch(selectedProfessionProvider);
    final selectedLabor = ref.watch(selectedLaborerProvider);

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
      "vat_amount": selectedPackage.vatAmount,
      "worker_id": selectedLabor?.personId
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

  Widget _buildSteps() {
    final loc = AppLocalizations.of(context)!;
    final nationalityAsync = ref.watch(nationalitiesProvider);
    final packagesAsync = ref.watch(packageProvider);
    final selectedProfession = ref.watch(selectedProfessionProvider);
    final selectedPackage = ref.watch(
        selectedPackageProvider); // assuming this is how you track selection
    final laborersAsync = ref.watch(laborersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1: Nationality
        if (currentStep >= 0)
          // Assuming you have:

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nationality",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              nationalityAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading nationalities'),
                data: (nationalities) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<int>(
                      value: selectedNationality,
                      hint: const Text("Select nationality"),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      items: nationalities.map<DropdownMenuItem<int>>((nat) {
                        return DropdownMenuItem(
                          value: nat?.id,
                          child: Text(nat != null ? nat.name : ""),
                        );
                      }).toList(),
                      onChanged: (val) {
                        ref.read(selectedNationalityProvider.notifier).state =
                            val;
                        checkCarAvailability();
                        setState(() {
                          selectedNationality = val;
                        });
                        if (currentStep == 0) goToNextStep();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        // Step 2: Package
        if (currentStep >= 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Package",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              packagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text("Failed to load packages"),
                data: (packages) {
                  return Column(
                    children:
                        packages.map<Widget>((DomesticPackageModel package) {
                      final title =
                          "${package.packageName} - ${(package.contractAmount + package.vatAmount).toStringAsFixed(2)} Riyal";

                      final subtitle = [
                        "${loc.contract_amount}: ${package.contractAmount.toStringAsFixed(2)} Riyal",
                        "${loc.vat}: ${package.vatAmount.toStringAsFixed(2)} Riyal",
                        "${loc.duration}: ${package.contractDays} days",
                      ].join(" • ");

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildPackageCard(
                          title: title,
                          subtitle: subtitle,
                          isSelected:
                              selectedPackage?.packageId == package.packageId,
                          onTap: () {
                            ref.read(selectedPackageProvider.notifier).state =
                                package;
                            if (currentStep == 1) goToNextStep();
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        // Step 3: Labor Source
        if (currentStep >= 2)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.chooselabor,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // From Company
              _buildMinimalRadio(
                label: loc.from_company, // ✅ required
                value: "company", // ✅ required
              ),

              _buildMinimalRadio(
                label: loc.from_app,
                value: "app",
              ),
              const SizedBox(height: 24),
            ],
          ),

        if (currentStep >= 3 && selectedLaborSource == 'app')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Choose ${selectedProfession?.positionName}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  GestureDetector(
                    onTap: _openFilterDialog, // your filter method
                    child: SvgPicture.asset(
                      "assets/images/filter.svg",
                      height: 24,
                      width: 24,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Handle async states
              laborersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err',
                    style: const TextStyle(color: Colors.red)),
                data: (laborers) {
                  if (laborers.isEmpty) {
                    return const Text("No drivers found");
                  }

                  final isRTL = Directionality.of(context) == TextDirection.rtl;

                  return ListView.builder(
                    shrinkWrap: true, // makes list take only needed height
                    physics:
                        const NeverScrollableScrollPhysics(), // disables inner scrolling
                    itemCount: laborers.length,
                    itemBuilder: (context, index) {
                      final laborer = laborers[index];
                      final driverValue =
                          "${laborer.employeeName} - ${laborer.employeeNumber}";
                      final isSelected = selectedDriver == driverValue;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            ref.read(selectedLaborerProvider.notifier).state =
                                laborer;
                            selectedDriver = driverValue;
                            if (currentStep == 3) goToNextStep();
                          });
                        },
                        child: Container(
                          // remove fixed height to allow flexible height
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(
                              12), // add padding instead of fixed height
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.blue.shade50 : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: isRTL
                                ? _buildDriverCardContent(
                                    context: context,
                                    isSelected: isSelected,
                                    name: laborer.employeeName,
                                    employeeNumber:
                                        laborer.employeeNumber.toString(),
                                    imageOnRight: true,
                                    onInfoPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LaborProfilePage(
                                                  laborer: laborer),
                                        ),
                                      );
                                    },
                                  )
                                : _buildDriverCardContent(
                                    context: context,
                                    isSelected: isSelected,
                                    name: laborer.employeeName,
                                    employeeNumber:
                                        laborer.employeeNumber.toString(),
                                    imageOnRight: false,
                                    onInfoPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LaborProfilePage(
                                                  laborer: laborer),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        // Step 5: Delivery
        if (currentStep >= 4)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.pickup_or_delivey,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              RadioListTile<String>(
                title: Text(loc.pickup),
                value: "pickup",
                groupValue: pickupOption,
                onChanged: (val) {
                  setState(() => pickupOption = val);
                  if (currentStep == 4) {
                    goToNextStep();
                  } // extra statement
                  // anotherAction();
                },
              ),
              RadioListTile<String>(
                title: Text(loc.delivery),
                value: "delivery",
                groupValue: pickupOption,
                onChanged: deliveryAvailable
                    ? (val) {
                        setState(() => pickupOption = val);
                        if (currentStep == 4)
                          goToNextStep(); // another statement
                      }
                    : null,
                subtitle: !deliveryAvailable
                    ? Text(loc.delivery_not_available,
                        style: TextStyle(color: Colors.red))
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),

        // Step 6: Agreement
        if (currentStep == 5)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.agreement,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show driver only if labor source is app
                    if (selectedLaborSource == 'app')
                      _textRow(selectedProfession?.positionName ?? '',
                          selectedDriver ?? "Not selected"),

                    // Nationality: (show actual selectedNationality if available)
                    _textRow("${loc.nationality}: ",
                        ref.read(selectedLaborerProvider)?.nationality ?? ''),

                    // Package name
                    _textRow("${loc.package}: ",
                        selectedPackage?.packageName ?? "Not selected"),

                    // Price = contractAmount + vatAmount + delivery fee if delivery
                    _textRow(
                      "${loc.price}: ",
                      () {
                        if (selectedPackage == null) return "N/A";

                        double basePrice = selectedPackage.contractAmount +
                            selectedPackage.vatAmount;
                        if (pickupOption == "delivery") {
                          basePrice += 100; // Add delivery fee
                        }
                        return "${basePrice.toStringAsFixed(2)} SR";
                      }(),
                    ),

                    // Delivery method text
                    _textRow(
                      "${loc.delivery}: ",
                      pickupOption == "pickup"
                          ? loc.pickup
                          : pickupOption == "delivery"
                              ? loc.delivery_fee
                              : "Not selected",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    submitOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(loc.submit_order),
                ),
              )
            ],
          ),
      ],
    );
  }

  Widget _buildMinimalRadio({
    required String label,
    required String value,
  }) {
    final isSelected = selectedLaborSource == value;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.only(
        left: isRTL ? 0 : 10, // push right in LTR
        right: 8, // push left in RTL
        bottom: 8, // optional vertical spacing between radios
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30, // fixed width for radio button alignment
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedLaborSource = value;
                  if (value == "company") {
                    currentStep = 4;
                  } else if (value == "app") {
                    currentStep = 3;
                  }
                });
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1.5),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 5,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: isRTL
                  ? const EdgeInsets.only(right: 24, left: 12)
                  : const EdgeInsets.only(left: 12, right: 12),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color.fromRGBO(118, 128, 144, 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStepNavigation(String value) {
    if (value == "company") {
      // Skip to step 5 only if we're on step 4
      if (currentStep == 3) {
        setState(() {
          currentStep = 4; // step 5 index if zero-based
        });
      }
    } else if (value == "app") {
      // Go back to step 5 only if we're past it
      if (currentStep >= 4) {
        setState(() {
          currentStep = 3; // step 4 index if zero-based
        });
      }
    }
  }

  final List<Map<String, String>> packages = [
    {
      "title": "1 Month - 1000 SR",
      "subtitle":
          "Start your 30 days with your Private driver with 10% discount."
    },
    {
      "title": "2 Months - 1800 SR",
      "subtitle": "Enjoy 2 months with your Private driver with 15% discount."
    },
    {
      "title": "3 Months - 2500 SR",
      "subtitle": "Best deal! 3 months with 20% discount."
    },
  ];

  void goToNextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  Widget _buildFooterStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 3, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(totalSteps, (index) {
          Color color;
          if (index < currentStep) {
            color = Colors.blue[900]!;
          } else if (index == currentStep) {
            color = Colors.lightBlue;
          } else {
            color = Colors.grey.shade300;
          }

          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        int? selectedAge = filterAge;
        String? selectedSocialStatus = filterSocialStatus;
        int? selectedExperience = filterExperience;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Filter Drivers",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),

                  // Age filter
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: "Age"),
                    value: selectedAge,
                    items: [20, 30, 40, 50, 60]
                        .map((age) =>
                            DropdownMenuItem(value: age, child: Text("$age+")))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => selectedAge = value);
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),

                  // Social status filter
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Social Status"),
                    value: selectedSocialStatus,
                    items: ["Single", "Married", "Divorced", "Widowed"]
                        .map((status) => DropdownMenuItem(
                            value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => selectedSocialStatus = value);
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),

                  // Experience filter
                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(labelText: "Experience (years)"),
                    value: selectedExperience,
                    items: [1, 3, 5, 10]
                        .map((exp) => DropdownMenuItem(
                            value: exp, child: Text("$exp+ years")))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => selectedExperience = value);
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            filterAge = null;
                            filterSocialStatus = null;
                            filterExperience = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Clear"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            filterAge = selectedAge;
                            filterSocialStatus = selectedSocialStatus;
                            filterExperience = selectedExperience;
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Apply"),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDriverCardContent({
    required BuildContext context,
    required bool isSelected,
    required String name,
    required String employeeNumber,
    required bool imageOnRight,
    required VoidCallback onInfoPressed,
  }) {
    final profileImage = Container(
      margin: const EdgeInsets.all(2), // 2px gap on all sides
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage("assets/images/default_avatar.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );

    final textAndRadio = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Employee Number: $employeeNumber",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF768090),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: onInfoPressed,
              tooltip: 'View Profile',
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );

    return imageOnRight
        ? [textAndRadio, profileImage]
        : [profileImage, textAndRadio];
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: value, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
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
      final available =
          await ApiService.checkCarAvailability(selectedAddress?.cityCode);
      setState(() {
        deliveryAvailable = available;
      });
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

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final nationalityAsync = ref.watch(nationalitiesProvider);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _buildHeader(context),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildSteps(),
              ),
            ),
            _buildFooterStepper(),
          ],
        ),
      ),
    );
  }
}

Widget buildPackageCard({
  required String title,
  required String subtitle,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Builder(
    builder: (context) {
      final isRTL = Directionality.of(context) == TextDirection.rtl;

      return GestureDetector(
        onTap: onTap,
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF003366) : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
            ),
            child: Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: IntrinsicHeight(
                // <<<<< Wrap the Row with IntrinsicHeight
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSelectionIndicator(isSelected, isRTL),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: isRTL
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              textAlign:
                                  isRTL ? TextAlign.right : TextAlign.left,
                              textDirection:
                                  isRTL ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      );
    },
  );
}

Widget _buildSelectionIndicator(bool isSelected, bool isRTL) {
  return Container(
    width: 48,
    decoration: BoxDecoration(
      color: isSelected ? const Color(0xFF003366) : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        right: isRTL ? Radius.circular(10) : Radius.zero,
        left: isRTL ? Radius.zero : Radius.circular(10),
      ),
    ),
    child: Center(
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white)
          : Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 2,
                ),
              ),
            ),
    ),
  );
}
