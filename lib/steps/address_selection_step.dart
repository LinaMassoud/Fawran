import 'package:fawran/models/address_model.dart';
import 'package:flutter/material.dart';
import '../Fawran4Hours/add_new_address.dart';
import '../widgets/booking_bottom_navigation.dart';

class AddressSelectionStep extends StatefulWidget {
  final List<Address> addresses;
  final Function(int) onAddressSelected;
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

  @override
  State<AddressSelectionStep> createState() => _AddressSelectionStepState();
}

class _AddressSelectionStepState extends State<AddressSelectionStep> {
  int? _selectedAddressId;

  bool get _hasSelectedAddress => _selectedAddressId != null;

  void _selectAddress(int addressId) {
    setState(() {
      _selectedAddressId = addressId;
    });
    widget.onAddressSelected(addressId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onAddNewAddress,
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
                Expanded(
                  child: _buildAddressContent(context),
                ),
              ],
            ),
          ),
        ),
        BookingBottomNavigation(
          price: widget.price,
          canProceed: _hasSelectedAddress && !widget.isLoading && widget.error == null,
          isLastStep: false,
          onNextPressed: widget.onNextPressed,
        ),
      ],
    );
  }

  Widget _buildAddressContent(BuildContext context) {
    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            SizedBox(height: 16),
            Text('Loading addresses...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            SizedBox(height: 16),
            Text('Failed to load addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(widget.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 20),
            if (widget.onRetryPressed != null)
              ElevatedButton.icon(
                onPressed: widget.onRetryPressed,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      );
    }

    if (widget.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No addresses found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Please add a new address to continue', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.addresses.length,
      itemBuilder: (context, index) {
        final address = widget.addresses[index];
        final isSelected = address.addressId == _selectedAddressId;

        return Container(
          margin: EdgeInsets.only(bottom: 15),
          child: GestureDetector(
            onTap: () => _selectAddress(address.addressId),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(15),
                color: isSelected ? Colors.grey[50] : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      address.cardText,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
