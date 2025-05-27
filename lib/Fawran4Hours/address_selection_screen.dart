import 'package:flutter/material.dart';
import 'add_new_address.dart'; // Import the AddNewAddressScreen
import 'service_details_screen.dart';
import 'cleaning_service_screen.dart'; // Import to access PackageModel

class AddressModel {
  final String id;
  final String name;
  final String fullAddress;
  final bool isSelected;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.isSelected,
  });

  AddressModel copyWith({
    String? id,
    String? name,
    String? fullAddress,
    bool? isSelected,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class AddressSelectionScreen extends StatefulWidget {
  final PackageModel package;

  const AddressSelectionScreen({
    Key? key,
    required this.package,
  }) : super(key: key);

  @override
  _AddressSelectionScreenState createState() => _AddressSelectionScreenState();

  // Static method to show as overlay
  static void showAsOverlay(
    BuildContext context, {
    required PackageModel package,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionScreen(
        package: package,
      ),
    );
  }
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  List<AddressModel> addresses = [
    AddressModel(
      id: '1',
      name: 'Al rashidiya',
      fullAddress: 'Riyadh Province, Riyadh Principality',
      isSelected: true,
    ),
    AddressModel(
      id: '2',
      name: 'Al Abha',
      fullAddress: 'Riyadh Province, Riyadh Principality',
      isSelected: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectAddress(String addressId) {
    setState(() {
      addresses = addresses.map((address) {
        return address.copyWith(
          isSelected: address.id == addressId,
        );
      }).toList();
    });
  }

  void _addNewAddress() async {
    // Navigate to AddNewAddressScreen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewAddressScreen(),
      ),
    );

    // If a new address was returned, add it to the list
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // Deselect all current addresses
        addresses = addresses.map((address) {
          return address.copyWith(isSelected: false);
        }).toList();

        // Add the new address as selected
        final newAddress = AddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate unique ID
          name: result['title'] ?? 'New Address',
          fullAddress: result['fullAddress'] ?? 
                      '${result['province'] ?? ''}, ${result['city'] ?? ''}, ${result['district'] ?? ''}',
          isSelected: true,
        );
        
        addresses.add(newAddress);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New address added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editAddress(String addressId) {
    // Navigate to edit address screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit address functionality would be implemented here')),
    );
  }

  void _proceedToNext() {
    final selectedAddress = addresses.firstWhere((address) => address.isSelected);
    
    // Close the current overlay first
    Navigator.pop(context);
    
    // Show the service details overlay with complete package data
    ServiceDetailsScreen.showAsOverlay(
      context,
      package: widget.package,
      selectedAddress: selectedAddress.name,
      selectedAddressId: selectedAddress.id,
      selectedAddressFullAddress: selectedAddress.fullAddress,
    );
  }

  void _closeOverlay() async {
    await _animationController.reverse();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Semi-transparent background
              GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              
              // Close button positioned outside the white modal
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: _closeOverlay,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Sliding content from bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        
                        // Main Content
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10), // Top spacing
                                
                                // Address Title
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    'Address',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 25),
                                
                                // Add New Address Button
                                GestureDetector(
                                  onTap: _addNewAddress,
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
                                        Icon(
                                          Icons.add,
                                          color: Colors.black,
                                          size: 20,
                                        ),
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
                                
                                // Select Address Section
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(
                                    'Select Address',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
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
                                          onTap: () => _selectAddress(address.id),
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
                                                  onTap: () => _editAddress(address.id),
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
                        
                        // Bottom Section with Total Amount and Next Button
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Price Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Starting From',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'SAR ${widget.package.finalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(width: 20),
                              
                              // Next Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: _proceedToNext,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1E3A8A), // Dark blue color
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Next',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}