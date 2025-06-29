import 'package:fawran/models/address_model.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/screens/combined.dart';
import 'package:fawran/steps/address_selection_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fawran/Fawran4Hours/add_new_address.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  final String? header;

  const AddressSelectionScreen({super.key, this.header});

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
  bool isLoading = false;
  String? addressError;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');

    if (userId == null) {
      setState(() {
        addressError = 'User not authenticated. Please log in again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      addressError = null;
    });

    try {
      final url = Uri.parse(
          'http://fawran.ddns.net:8080/ords/emdad/fawran/customer_addresses/$userId');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Address> fetchedAddresses =
            jsonData.map((item) => Address.fromJson(item)).toList();

        final currentSelected = ref.read(selectedAddressProvider);
        String? currentText = currentSelected?.cardText;
        int? currentId = currentSelected?.addressId;

        Address? addressToSelect;

        if (currentId != null) {
          addressToSelect = fetchedAddresses
              .firstWhere((addr) => addr.addressId == currentId);
        }

        if (addressToSelect == null && currentText != null) {
          addressToSelect = fetchedAddresses.firstWhere(
            (addr) => addr.cardText.toLowerCase() == currentText.toLowerCase(),
          );
        }

        addressToSelect ??=
            fetchedAddresses.isNotEmpty ? fetchedAddresses.first : null;

        setState(() {
          addresses = fetchedAddresses
              .map((a) => a.copyWith(
                  isSelected: a.addressId == addressToSelect?.addressId))
              .toList();
          _selectedAddress = addressToSelect?.addressId;
          isLoading = false;
        });

        if (addressToSelect != null) {
          ref.read(selectedAddressProvider.notifier).state = addressToSelect;
        }
      } else {
        setState(() {
          addressError = 'Failed to load addresses: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        addressError = 'Error fetching addresses: $e';
        isLoading = false;
      });
    }
  }

  void _addNewAddress() async {
    final userId = ref.watch(userIdProvider);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewAddressScreen(user_id: userId),
      ),
    );

    if (result == null) return;

    if (result is Map<String, dynamic> &&
        result['success'] == true &&
        result['refresh_addresses'] == true) {
      await fetchAddresses();

      final add = result["newAddress"];
      final displayAdd = result["displayAddress"];

      if (add != null && displayAdd != null) {
        final expectedCardText =
            '${displayAdd['city'] ?? ''} - ${displayAdd['district']?.districtName ?? ''}';

        final newAddress = addresses.firstWhere(
          (address) =>
              address.cardText
                  .toLowerCase()
                  .contains(expectedCardText.toLowerCase()) ||
              (address.cityCode.toString() == add['city'].toString() &&
                  address.districtCode == add['districtCode']),
          orElse: () => addresses.last,
        );

        ref.read(selectedAddressProvider.notifier).state = newAddress;

        setState(() {
          _selectedAddress = newAddress.addressId;
          addresses = addresses
              .map((a) =>
                  a.copyWith(isSelected: a.addressId == newAddress.addressId))
              .toList();
        });

        if (result['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selectedProfession = ref.watch(selectedProfessionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
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
                        "${selectedProfession?.positionName}",
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
                  ],
                ),
              ),
              Expanded(
                child: AddressSelectionStep(
                  selectedAddress: selectedAddress,
                  addresses: addresses,
                  onAddressSelected: (id) {
                    setState(() {
                      _selectedAddress = id;
                      addresses = addresses
                          .map((a) => a.copyWith(isSelected: a.addressId == id))
                          .toList();
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
                  isLoading: isLoading,
                  error: addressError,
                  onRetryPressed: fetchAddresses,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
