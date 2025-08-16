import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/address_model.dart';
import 'package:fawran/services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: const Color(0xFF10295C),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: const Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          loc.myAddresses,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: _buildAddressContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressContent(BuildContext context) {
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
            // Display the custom illustration SVG
            SizedBox(
              width: 280,
              height: 200,
              child: SvgPicture.asset(
                'assets/images/no_addresses_found.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 8),
            Text(
              'No addresses found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E49A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1E49A0),
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
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.normal,
                          color: Color(0xFF10295C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.cardText,
                        style: const TextStyle(
                          fontFamily: 'poppins',
                          fontSize: 14,
                          color: Color(0xFF768090),
                          fontWeight: FontWeight.w500,
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