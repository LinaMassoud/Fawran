import 'package:fawran/Fawran4Hours/add_new_address.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/screens/service_provider.dart';
import 'package:fawran/steps/address_selection_step.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final String header;

  const AddressSelectionScreen({super.key, required this.header});

  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();
}


class _AddressSelectionScreenState extends ConsumerState<AddressSelectionScreen> {
  final Color headerColor = Color(0xFF112A5C); // Dark blue
  int _selectedAddress = 0;
  bool _doorstepServiceSelected = false;
  List<Address> addresses = [];
    @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

    Future<void> fetchAddresses() async {
    final url = Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/customer_addresses/1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        final List<Address> fetchedAddresses = jsonData
            .map((item) => Address.fromJson(item))
            .toList();

        setState(() {
          addresses = fetchedAddresses;
          if (addresses.isNotEmpty) {
            ref.read(selectedAddressProvider.notifier).state = addresses.first;
            _selectedAddress = 0;
          }
        });
      } else {
        print('Failed to load addresses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

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
  child: AddressSelectionStep(
    addresses: addresses,
    onAddressSelected: (id) {
      setState(() {
        addresses = addresses.map((address) {
          return address.copyWith(isSelected: address.addressId == id);
        }).toList();
      });
    },
    onAddNewAddress: _addNewAddress,
    onNextPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceProvidersScreen(header: widget.header),
        ),
      );
    },
    price: _doorstepServiceSelected ? 150.0 : 0.0,
    isLoading: false,
    error: null,
    onRetryPressed: null,
  ),
),

            ],
          ),

          // Fixed Footer
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

       final newAddress = Address(
  addressId: DateTime.now().millisecondsSinceEpoch,
  cardText: result['title'] ?? 'New Address',
  cityCode: result['city'] ?? '',
  districtCode: result['district'] ?? '',
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
