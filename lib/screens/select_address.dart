import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/screens/combined.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:fawran/Fawran4Hours/add_new_address.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/screens/service_provider.dart';
import 'package:fawran/steps/address_selection_step.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final String header;

  const AddressSelectionScreen({super.key, required this.header});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  final Color headerColor = const Color(0xFF112A5C);
  bool _doorstepServiceSelected = false;
  List<Address> addresses = [];
  int? _selectedAddress;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final userId = ref.read(userIdProvider);
    if (userId != null) {}
    final url = Uri.parse(
        'http://10.20.10.114:8080/ords/emdad/fawran/customer_addresses/' +
            userId.toString());

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        final List<Address> fetchedAddresses =
            jsonData.map((item) => Address.fromJson(item)).toList();

        setState(() {
          addresses = fetchedAddresses;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.first.addressId;
            ref.read(selectedAddressProvider.notifier).state = addresses.first;
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
                  borderRadius: const BorderRadius.only(
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Step Info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Address",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("Next - Service Providers",
                            style: TextStyle(color: Colors.grey.shade600)),
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
                        const Text("1 of 5",
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Address Selection Step
              Expanded(
                child: AddressSelectionStep(
                  selectedAddress: selectedAddress,
                  addresses: addresses,
                  onAddressSelected: (id) {
                    setState(() {
                      _selectedAddress = id;
                      addresses = addresses.map((address) {
                        return address.copyWith(
                            isSelected: address.addressId == id);
                      }).toList();
                    });

                    final selected =
                        addresses.firstWhere((addr) => addr.addressId == id);
                    ref.read(selectedAddressProvider.notifier).state = selected;
                  },
                  onAddNewAddress: _addNewAddress,
                  onNextPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CombinedOrderScreen(header: widget.header),
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
        ],
      ),
    );
  }

  void _addNewAddress() async {
    final userId = ref.watch(userIdProvider);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddNewAddressScreen(user_id: userId)),
    );

    if (result != null && result is Map<String, dynamic>) {
      final newAddress = Address(
        addressId: DateTime.now().millisecondsSinceEpoch,
        cardText: result['title'] ?? 'New Address',
        cityCode: result['city'] ?? '',
        districtCode: result['district'] ?? '',
        isSelected: true,
      );

      setState(() {
        addresses =
            addresses.map((a) => a.copyWith(isSelected: false)).toList();
        addresses.add(newAddress);
        _selectedAddress = newAddress.addressId;
      });

      ref.read(selectedAddressProvider.notifier).state = newAddress;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
