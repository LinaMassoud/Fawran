import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/services/api_service.dart';
import 'package:fawran/Fawran4Hours/add_new_address.dart';
import 'package:fawran/screens/address_display_screen.dart';

class AddressDisplayScreen extends ConsumerStatefulWidget {
  const AddressDisplayScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddressDisplayScreen> createState() => _AddressDisplayScreenState();
}

class _AddressDisplayScreenState extends ConsumerState<AddressDisplayScreen> {
  final _storage = const FlutterSecureStorage();
  List<Address> addresses = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Get userId from secure storage
      final userId = await _storage.read(key: 'user_id') ?? '';
      
      if (userId.isEmpty) {
        setState(() {
          error = 'User not authenticated. Please log in again.';
          isLoading = false;
        });
        return;
      }

      // Fetch addresses using the API service
      final data = await ApiService.fetchCustomerAddresses(userId: userId);

      setState(() {
        addresses = data.map((addressData) {
          return Address(
            cardText: addressData['card_text']?.toString() ?? 'Address',
            addressId: addressData['address_id'] ?? 0,
            cityCode: int.parse(addressData['city_code'].toString()),
            districtCode: addressData['district_code']?.toString() ?? '',
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading addresses: $e';
        isLoading = false;
      });
    }
  }

  // Extract a readable location name from the CARD_TEXT
  String _extractLocationName(String? cardText) {
    if (cardText == null || cardText.isEmpty) {
      return 'Address';
    }
    
    try {
      List<String> parts = cardText.split('-');
      
      if (parts.length >= 2) {
        String city = parts[0].trim();
        String area = parts[1].trim();
        
        if (area.isEmpty) {
          return city.isNotEmpty ? city : 'Address';
        }
        
        return '$area, $city';
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].trim();
      }
    } catch (e) {
      print('Error parsing address: $e');
    }
    
    return 'Address';
  }

  void _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewAddressScreen(),
      ),
    );
    
    // If an address was added, refresh the list
    if (result == true) {
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          loc.myAddresses,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content Section
          Expanded(
            child: _buildContent(context, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations loc) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            SizedBox(height: 16),
            Text(
              'Loading addresses...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Failed to load addresses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchAddresses,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No addresses found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add a new address to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.orange[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _extractLocationName(address.cardText),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.cardText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}