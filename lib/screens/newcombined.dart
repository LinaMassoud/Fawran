import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivateDriverScreen extends StatefulWidget {
  const PrivateDriverScreen({super.key});

  @override
  State<PrivateDriverScreen> createState() => _PrivateDriverScreenState();
}

class _PrivateDriverScreenState extends State<PrivateDriverScreen> {
  int currentStep = 0;
  final int totalSteps = 6;

  String? selectedNationality;
  String? selectedPackage;
  String? selectedLaborSource;
  String? selectedDriver;
  String? selectedDelivery;
  Widget _buildMinimalRadio(String label, String value) {
    final isSelected = selectedLaborSource == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLaborSource = value;
          if (currentStep == 2) goToNextStep();
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12), // distance from text
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey, // gray border
                width: 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black87, // selected inner dot
                      ),
                    ),
                  )
                : null,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color.fromRGBO(118, 128, 144, 1),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Private Driver"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
    );
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

  Widget _buildSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1: Nationality
        if (currentStep >= 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Nationality",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: selectedNationality,
                  hint: const Text("Select nationality"),
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: const [
                    DropdownMenuItem(value: "Indian", child: Text("Indian")),
                    DropdownMenuItem(value: "Nepali", child: Text("Nepali")),
                  ],
                  onChanged: (val) {
                    selectedNationality = val;
                    if (currentStep == 0) goToNextStep();
                  },
                ),
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
              Column(
                children: packages.map((package) {
                  final title = package['title']!;
                  final subtitle = package['subtitle']!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildPackageCard(
                      title: title,
                      subtitle: subtitle,
                      isSelected: selectedPackage == title,
                      onTap: () {
                        setState(() {
                          selectedPackage = title;
                        });
                        if (currentStep == 1) goToNextStep();
                      },
                    ),
                  );
                }).toList(),
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
                "Choose Labor Source",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildMinimalRadio("From Company", "company"),
              const SizedBox(height: 12),
              _buildMinimalRadio("From App", "app"),
            ],
          ),
        if (currentStep >= 3)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Choose Private Driver",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...List.generate(3, (index) {
                String name = "Mr. Mohammad Yusuf";
                String employeeNumber = "500735$index";
                String driverValue = "$name - $employeeNumber";

                final isSelected = selectedDriver == driverValue;
                final isRTL = Directionality.of(context) == TextDirection.rtl;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDriver = driverValue;
                      if (currentStep == 3) goToNextStep();
                    });
                  },
                  child: Container(
                    height: 90,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: isRTL
                          ? _buildDriverCardContent(
                              isSelected: isSelected,
                              name: name,
                              employeeNumber: employeeNumber,
                              imageOnRight: true)
                          : _buildDriverCardContent(
                              isSelected: isSelected,
                              name: name,
                              employeeNumber: employeeNumber,
                              imageOnRight: false),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),

        // Step 5: Delivery
        if (currentStep >= 4)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pickup or Delivery",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              RadioListTile<String>(
                value: "pickup",
                groupValue: selectedDelivery,
                onChanged: (val) {
                  selectedDelivery = val;
                  if (currentStep == 4) goToNextStep();
                },
                title: const Text("Pick up Laborer yourself"),
              ),
              RadioListTile<String>(
                value: "delivery",
                groupValue: selectedDelivery,
                onChanged: null,
                subtitle: const Text(
                  "Delivery option is not available currently",
                  style: TextStyle(color: Colors.red),
                ),
                title: const Text("Deliver Laborer to Home"),
              ),
              const SizedBox(height: 24),
            ],
          ),

        // Step 6: Agreement
        if (currentStep == 5)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Agreement",
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
                    _textRow("Private driver: ", selectedDriver ?? ""),
                    _textRow("Nationality: ", selectedNationality ?? ""),
                    _textRow("Package: ", selectedPackage ?? ""),
                    _textRow("Price: ", "1000 SR"),
                    _textRow("Delivery: ", selectedDelivery ?? ""),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Submit action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text("Submit Order"),
                ),
              )
            ],
          ),
      ],
    );
  }

  List<Widget> _buildDriverCardContent({
    required bool isSelected,
    required String name,
    required String employeeNumber,
    required bool imageOnRight,
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
                      fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildHeader(),
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
              child: Row(
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
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
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
            )),
      );
    },
  );
}

Widget _buildSelectionIndicator(bool isSelected, bool isRTL) {
  return Container(
    width: 48,
    height: 100,
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
