import 'package:fawran/screens/agreement.dart';
import 'package:flutter/material.dart';



class PackageSelectionScreen extends StatefulWidget {
   final String header;
  const PackageSelectionScreen({super.key, required this.header});

  @override
  _PackageSelectionScreenState createState() =>
      _PackageSelectionScreenState();
}

class _PackageSelectionScreenState extends State<PackageSelectionScreen> {
  final List<Map<String, dynamic>> packages = [
    {
      'price': '600 Riyal',
      'title': 'Bangladesh Weekly Package',
      'details': {
        'Profession': 'Driver',
        'Nationality': 'Bangladesh',
        'VAT Info': 'Package Price with VAT 600.00 Riyal'
      },
    },
    {
      'price': '2199 Riyal',
      'title': 'Bangladesh 30 Day Package',
      'details': {
        'Profession': 'HouseMaids',
        'Nationality': 'Bangladesh',
        'VAT Info': 'Package Price with VAT 2199.01 Riyal'
      },
    },
    {
      'price': '4200 Riyal',
      'title': 'Bangladesh 60 Day Package',
      'details': {
        'Profession': 'Driver',
        'Nationality': 'Bangladesh',
        'VAT Info': 'Package Price with VAT 4200.00 Riyal'
      },
    },
    {
      'price': '6000 Riyal',
      'title': 'Bangladesh 90 Day Package',
      'details': {
        'Profession': 'Driver',
        'Nationality': 'Bangladesh',
        'VAT Info': 'Package Price with VAT 6000.00 Riyal'
      },
    },
  ];

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom AppBar with rounded corners
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
                // Back arrow + title aligned
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        widget.header,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Title + Progress Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title and subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Package',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Next - Agreement', style: TextStyle(color: Colors.grey)),
                    Text('Choose suitable package',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),

                // Circular progress (3 of 5)
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    Text(
                      '3 of 5',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Package List
          Expanded(
            child: ListView.builder(
              itemCount: packages.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final package = packages[index];
                final isSelected = selectedIndex == index;

                return Card(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: Colors.blue, width: 1.5)
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(package['price'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(package['title']),
                    children: [
                      ...package['details'].entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('${entry.key}: ${entry.value}'),
                          )),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = index;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Selected: ${package['title']}'),
                            ));

                              Navigator.push(
            context,
           
        MaterialPageRoute(
                              builder: (context) =>  ContractScreen(header:widget.header),
                            ),
          );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                          ),
                          child: Text('Choose Package'),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
