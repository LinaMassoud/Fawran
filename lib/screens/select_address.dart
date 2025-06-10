import 'package:fawran/Fawran4Hours/add_new_address.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/screens/service_provider.dart';
import 'package:flutter/material.dart';

class AddressSelectionScreen extends StatefulWidget {
  final String header;

  const AddressSelectionScreen({super.key,required this.header});
  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final Color headerColor = Color(0xFF112A5C); // Dark blue
  int _selectedAddress = 0;
  bool _doorstepServiceSelected = false;
  List<AddressModel> addresses = [
  AddressModel(id:'1', name: "Al rashidiya", fullAddress: "Riyadh Province, Riyadh Principality",isSelected: true),
    AddressModel(id:'2', name: "Al Abha", fullAddress: "Riyadh Province, Riyadh Principality",isSelected: false),

];

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                height: statusBarHeight + 100,
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        widget.header,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Sub-header: "Address - Next: Service Providers" with step circle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("Next - Service Providers", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator(
                            value: 0.2,
                            strokeWidth: 4,
                            color: Colors.green,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        Text("1 of 5", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add New Address Button
                      GestureDetector(
                        onTap: () {
                          // Handle add address
                          _addNewAddress();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                "ADD NEW ADDRESS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Address Options
                      Text("Select Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),

                    ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: addresses.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: _buildAddressTile(addresses[index].name, addresses[index].fullAddress,index),
    );
  },
),

                      SizedBox(height: 24),

                      // Doorstep Service Option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _doorstepServiceSelected = !_doorstepServiceSelected;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _doorstepServiceSelected ? headerColor : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _doorstepServiceSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _doorstepServiceSelected ? headerColor : Colors.grey,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Doorstep Service", style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text(
                                      "Deliver the labor to your doorstep for just SR 150!",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text("SAR 150", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Handle continue

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  ServiceProvidersScreen(header:widget.header),
                            ),
                          );
                    },
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(String title, String subtitle, int value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: () {
            // Handle edit
          },
          child: Text("Edit"),
        ),
        leading: Radio(
          value: value,
          groupValue: _selectedAddress,
          onChanged: (int? val) {
            setState(() {
              _selectedAddress = val!;
            });
          },
          activeColor: headerColor,
        ),
        onTap: () {
          setState(() {
            _selectedAddress = value;
          });
        },
      ),
    );
  }

 void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewAddressScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        addresses = addresses.map((address) {
          return address.copyWith(isSelected: false);
        }).toList();

        final newAddress = AddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['title'] ?? 'New Address',
          fullAddress: result['fullAddress'] ?? 
                      '${result['province'] ?? ''}, ${result['city'] ?? ''}, ${result['district'] ?? ''}',
          isSelected: true,
        );
        
        addresses.add(newAddress);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


}
