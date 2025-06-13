import 'package:fawran/screens/agreement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/package_provider.dart';

class PackageSelectionScreen extends ConsumerStatefulWidget {
  final String header;
  const PackageSelectionScreen({super.key, required this.header});

  @override
  ConsumerState<PackageSelectionScreen> createState() => _PackageSelectionScreenState();
}

class _PackageSelectionScreenState extends ConsumerState<PackageSelectionScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packageProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildTitleRow(),
          const SizedBox(height: 12),
          Expanded(
            child: packagesAsync.when(
              data: (packages) => ListView.builder(
                itemCount: packages.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final isSelected = selectedIndex == index;

                  return Card(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text('${package.packagePriceWithVat.toStringAsFixed(2)} Riyal',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(package.packageName),
                      children: [
                        _packageDetail('Package Type', package.packageType),
                        _packageDetail('Contract Days', '${package.contractDays}'),
                        _packageDetail('Contract Amount', '${package.contractAmount.toStringAsFixed(2)} Riyal'),
                        _packageDetail('Total With VAT', '${package.packagePriceWithVat.toStringAsFixed(2)} Riyal'),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                          onPressed: () {
  setState(() {
    selectedIndex = index;
  });

  // Update selected package
  ref.read(selectedPackageProvider.notifier).state = package;

  // Optional: show feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Selected: ${package.packageName}')),
  );

  // Navigate to agreement screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ContractScreen(header: widget.header),
    ),
  );
},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                            ),
                            child: const Text('Choose Package'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load packages: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 10),
                Text(widget.header,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Package', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Next - Agreement', style: TextStyle(color: Colors.grey)),
              Text('Choose suitable package', style: TextStyle(fontSize: 12)),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: 3 / 5,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              const Text('3 of 5',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packageDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}
