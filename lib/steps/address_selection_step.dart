import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../Fawran4Hours/add_new_address.dart';
import '../widgets/booking_bottom_navigation.dart';

class AddressSelectionStep extends StatelessWidget {
  final List<AddressModel> addresses;
  final Function(String) onAddressSelected;
  final VoidCallback onAddNewAddress;
  final VoidCallback onNextPressed;
  final double price;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetryPressed;

  const AddressSelectionStep({
    Key? key,
    required this.addresses,
    required this.onAddressSelected,
    required this.onAddNewAddress,
    required this.onNextPressed,
    required this.price,
    this.isLoading = false,
    this.error,
    this.onRetryPressed,
  }) : super(key: key);

  bool get _hasSelectedAddress {
    return addresses.any((address) => address.isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add New Address Button
                GestureDetector(
                  onTap: onAddNewAddress,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'ADD NEW ADDRESS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 35),
                
                Text(
                  'Select Address',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Address List with Loading/Error States
                Expanded(
                  child: _buildAddressContent(),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Navigation
        BookingBottomNavigation(
          price: price,
          canProceed: _hasSelectedAddress && !isLoading && error == null,
          isLastStep: false,
          onNextPressed: onNextPressed,
        ),
      ],
    );
  }

  Widget _buildAddressContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            SizedBox(height: 16),
            Text(
              'Loading addresses...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            if (onRetryPressed != null)
              ElevatedButton.icon(
                onPressed: onRetryPressed,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Icon(
              Icons.location_off,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No addresses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please add a new address to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
          margin: EdgeInsets.only(bottom: 15),
          child: GestureDetector(
            onTap: () => onAddressSelected(address.id),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: address.isSelected ? Colors.black : Colors.grey[300]!,
                  width: address.isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(15),
                color: address.isSelected ? Colors.grey[50] : Colors.white,
              ),
              child: Row(
                children: [
                  // Radio Button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: address.isSelected 
                            ? Colors.black 
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: address.isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  
                  SizedBox(width: 15),
                  
                  // Address Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          address.fullAddress,
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
                  
                  // Edit Button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit address functionality')),
                      );
                    },
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}