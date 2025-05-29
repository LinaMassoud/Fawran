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

  const AddressSelectionStep({
    Key? key,
    required this.addresses,
    required this.onAddressSelected,
    required this.onAddNewAddress,
    required this.onNextPressed,
    required this.price,
  }) : super(key: key);

  bool get _hasSelectedAddress {
    return addresses.any((address) => address.isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content
        Expanded(
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
                
                // Address List
                Expanded(
                  child: ListView.builder(
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
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(15),
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
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Navigation
        BookingBottomNavigation(
          price: price,
          canProceed: _hasSelectedAddress,
          isLastStep: false,
          onNextPressed: onNextPressed,
        ),
      ],
    );
  }
}