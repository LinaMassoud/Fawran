import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nationality_provider.dart';
import '../providers/labour_provider.dart';
import '../providers/package_provider.dart';

class CombinedOrderScreen extends ConsumerStatefulWidget {
  final String header;

  const CombinedOrderScreen({super.key, required this.header});

  @override
  ConsumerState<CombinedOrderScreen> createState() =>
      _CombinedOrderScreenState();
}

class _CombinedOrderScreenState extends ConsumerState<CombinedOrderScreen> {
  int? selectedNationality;
  int? selectedPackageIndex;
  int? selectedLaborId;

  @override
  Widget build(BuildContext context) {
    final nationalityAsync = ref.watch(nationalitiesProvider);
    final packagesAsync = ref.watch(packageProvider);
    final laborersAsync = ref.watch(laborersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.header),
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
                    setState(() => selectedNationality = v);
                  },
                  items: list
                      .map((n) => DropdownMenuItem<int>(
                            value: n.id,
                            child: Text(n.name),
                          ))
                      .toList(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              ),
            ),
            // STEP 2: PACKAGE
            sectionHeader("Step 2: Choose Package"),
            if (selectedNationality != null)
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
                                  child: Text(
                                    pkg.packageName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Radio<int>(
                                  value: i,
                                  groupValue: selectedPackageIndex,
                                  onChanged: (v) {
                                    setState(() => selectedPackageIndex = v);
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
                            _packageDetailRow("Price (with VAT)",
                                "${pkg.packagePriceWithVat.toStringAsFixed(2)} Riyal"),
                            _packageDetailRow("Final Contract Price",
                                "${pkg.contractAmount.toStringAsFixed(2)} Riyal"),
                            _packageDetailRow("Discounted Price",
                                "${pkg.packagePriceWithVat.toStringAsFixed(2)} Riyal"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              )
            else
              disabledStepCard("Please select a nationality first"),

            // STEP 3: LABOR
            sectionHeader("Step 3: Choose Driver"),
            if (selectedPackageIndex != null)
            laborersAsync.when(
  data: (drivers) {
    if (drivers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No Available Laborers",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "There are currently no laborers available. Please check back later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
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
              backgroundImage: (d.imageUrl != null && d.imageUrl!.isNotEmpty)
                  ? NetworkImage(d.imageUrl!)
                  : const AssetImage('assets/images/default_avatar.jpg')
                      as ImageProvider,
            ),
            title: Text(d.employeeName),
            subtitle: Text("Nationality: ${d.nationality}"),
            trailing: Radio<int>(
              value: d.personId,
              groupValue: selectedLaborId,
              onChanged: (v) {
                setState(() => selectedLaborId = v);
                ref.read(selectedLaborerProvider.notifier).state = d;
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

            else
              disabledStepCard("Please select a package first"),

            // STEP 4: AGREEMENT
            sectionHeader("Step 4: Agreement"),
            if (selectedLaborId != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Driver',
                          ref.read(selectedLaborerProvider)?.arabicName ?? ''),
                      const SizedBox(height: 8),
                      _infoRow('Nationality',
                          ref.read(selectedLaborerProvider)?.nationality ?? ''),
                      _infoRow('Package',
                          ref.read(selectedPackageProvider)?.packageName ?? ''),
                      _infoRow('Days',
                          '${ref.read(selectedPackageProvider)?.contractDays ?? ''}'),
                      _infoRow('Price',
                          '${ref.read(selectedPackageProvider)?.packagePriceWithVat.toStringAsFixed(2) ?? ''} Riyal'),
                    ],
                  ),
                ),
              )
            else
              disabledStepCard("Please select a driver first"),

            if (selectedLaborId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order Submitted")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("SUBMIT ORDER",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    ),
  );
}
