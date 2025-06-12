import 'package:fawran/Fawran4Hours/add_new_address.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/screens/service_provider.dart';
import 'package:fawran/steps/address_selection_step.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final String header;

  const AddressSelectionScreen({super.key, required this.header});
  
  @override
  ConsumerState<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends ConsumerState<AddressSelectionScreen> {
  final Color headerColor = Color(0xFF112A5C); // Dark blue
  bool _doorstepServiceSelected = false;
  
  // Address state management
  List<Address> addresses = [];
  bool isLoadingAddresses = true;
  String? addressError;

  @override
  void initState() {
    super.initState();
    // Fetch addresses from API
    _fetchAddresses();
  }

  // Fetch addresses from API
  Future<void> _fetchAddresses() async {
    try {
      setState(() {
        isLoadingAddresses = true;
        addressError = null;
      });

      // Updated API endpoint
      final response = await http.get(
        Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/customer_addresses/23'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          addresses = data.map((addressData) {
            return Address(
              cardText: addressData['card_text']?.toString() ?? 'Address',
              addressId: addressData['address_id'] ?? 0,
              cityCode: addressData['city_code']?.toString() ?? '',
              districtCode: addressData['district_code']?.toString() ?? '',
            );
          }).toList();
          
          // Set the first address as selected if no address is currently selected
          if (addresses.isNotEmpty && ref.read(selectedAddressProvider) == null) {
            ref.read(selectedAddressProvider.notifier).state = addresses.first;
          }
          
          isLoadingAddresses = false;
        });
      } else {
        setState(() {
          addressError = 'Failed to load addresses. Status: ${response.statusCode}';
          isLoadingAddresses = false;
        });
      }
    } catch (e) {
      setState(() {
        addressError = 'Error loading addresses: $e';
        isLoadingAddresses = false;
      });
    }
  }

  void _selectAddress(int addressId) {
    final selectedAddress = addresses.firstWhere(
      (address) => address.addressId == addressId,
      orElse: () => addresses.first,
    );
    ref.read(selectedAddressProvider.notifier).state = selectedAddress;
  }

  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewAddressScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final newAddress = Address(
        cardText: result['fullAddress'] ?? 
                  '${result['province'] ?? ''}, ${result['city'] ?? ''}, ${result['district'] ?? ''}',
        addressId: DateTime.now().millisecondsSinceEpoch,
        cityCode: result['cityCode'] ?? '',
        districtCode: result['districtCode'] ?? '',
      );
      
      setState(() {
        addresses.add(newAddress);
      });

      // Set the new address as selected
      ref.read(selectedAddressProvider.notifier).state = newAddress;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final selectedAddress = ref.watch(selectedAddressProvider);

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
                  selectedAddress: selectedAddress,
                  onAddressSelected: _selectAddress,
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
                  isLoading: isLoadingAddresses,
                  error: addressError,
                  onRetryPressed: _fetchAddresses,
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
                    onPressed: selectedAddress != null && !isLoadingAddresses && addressError == null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceProvidersScreen(header: widget.header),
                              ),
                            );
                          }
                        : null,
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
}