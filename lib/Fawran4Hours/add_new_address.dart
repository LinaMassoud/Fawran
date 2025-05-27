import 'package:flutter/material.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({Key? key}) : super(key: key);

  @override
  _AddNewAddressScreenState createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  // Controllers for form fields
  final TextEditingController _addressTitleController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _buildingNumberController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  // Dropdown values
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedDistrict;

  // Step completion states
  bool _isDistrictCompleted = false;
  bool _isMapCompleted = false;
  bool _canProceedToDetails = false;

  // Current step
  int _currentStep = 1;

  // Sample data for dropdowns
  final List<String> _provinces = ['Riyadh Province', 'Makkah Province', 'Al Madinah Province'];
  final List<String> _cities = ['Riyadh', 'Jeddah', 'Makkah', 'Medina'];
  final List<String> _districts = ['Al Fath', 'Al Rashidiya', 'Al Abha', 'Al Olaya'];

  @override
  void initState() {
    super.initState();
    _selectedProvince = 'Riyadh Province'; // Default selection
    _fullAddressController.text = 'Al Madinah Province,Madinah Principality, Madinah,7421';
  }

  @override
  void dispose() {
    _addressTitleController.dispose();
    _streetNameController.dispose();
    _buildingNumberController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _selectedProvince = value;
      _selectedCity = null;
      _selectedDistrict = null;
      _checkDistrictCompletion();
    });
  }

  void _onCityChanged(String? value) {
    setState(() {
      _selectedCity = value;
      _selectedDistrict = null;
      _checkDistrictCompletion();
    });
  }

  void _onDistrictChanged(String? value) {
    setState(() {
      _selectedDistrict = value;
      _checkDistrictCompletion();
    });
  }

  void _checkDistrictCompletion() {
    setState(() {
      _isDistrictCompleted = _selectedProvince != null && 
                           _selectedCity != null && 
                           _selectedDistrict != null;
      if (_isDistrictCompleted && _currentStep == 1) {
        _currentStep = 2;
      }
      _updateCanProceedToDetails();
    });
  }

  void _onMapCompleted() {
    setState(() {
      _isMapCompleted = true;
      if (_currentStep == 2) {
        _currentStep = 3;
      }
      _updateCanProceedToDetails();
    });
  }

  void _updateCanProceedToDetails() {
    setState(() {
      _canProceedToDetails = _isDistrictCompleted && _isMapCompleted;
    });
  }

  void _saveAddress() {
    if (_addressTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide an address title')),
      );
      return;
    }

    // Create new address and return to previous screen
    final newAddress = {
      'title': _addressTitleController.text,
      'streetName': _streetNameController.text,
      'buildingNumber': _buildingNumberController.text,
      'fullAddress': _fullAddressController.text,
      'province': _selectedProvince,
      'city': _selectedCity,
      'district': _selectedDistrict,
    };

    Navigator.pop(context, newAddress);
  }

  Widget _buildStepIndicator(int stepNumber, String title, bool isCompleted, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : (isActive ? Colors.black : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.green : (isActive ? Colors.black : Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged, {bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? Colors.white : Colors.grey[100],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.black : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          icon: Icon(Icons.keyboard_arrow_down, color: enabled ? Colors.grey[600] : Colors.grey[400]),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1, bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? Colors.white : Colors.grey[100],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey[400], 
            fontSize: 16
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 16,
          color: enabled ? Colors.black : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildMapSelector({bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? _onMapCompleted : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey[100],
        ),
        child: Row(
          children: [
            SizedBox(width: 16),
            Expanded(
              child: Text(
                _isMapCompleted ? 'Map selected' : 'Select on map',
                style: TextStyle(
                  fontSize: 16,
                  color: enabled 
                    ? (_isMapCompleted ? Colors.black : Colors.grey[600])
                    : Colors.grey[400],
                ),
              ),
            ),
            Text(
              'Edit',
              style: TextStyle(
                color: enabled ? Colors.grey[700] : Colors.grey[400],
                fontSize: 16,
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back arrow
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back, size: 24),
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Insert Address',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    // Step 1: District
                    _buildStepIndicator(1, 'District', _isDistrictCompleted, _currentStep >= 1),
                    SizedBox(height: 20),
                    _buildDropdown(
                      'Riyadh Province', 
                      _selectedProvince, 
                      _provinces, 
                      _onProvinceChanged
                    ),
                    SizedBox(height: 15),
                    _buildDropdown(
                      'Please select your city', 
                      _selectedCity, 
                      _cities, 
                      _onCityChanged,
                      enabled: _selectedProvince != null
                    ),
                    SizedBox(height: 15),
                    _buildDropdown(
                      'Please select your District', 
                      _selectedDistrict, 
                      _districts, 
                      _onDistrictChanged,
                      enabled: _selectedCity != null
                    ),

                    SizedBox(height: 30),
                    Container(height: 1, color: Colors.grey[300]),
                    SizedBox(height: 30),

                    // Step 2: Map (Always visible, but disabled until district is completed)
                    _buildStepIndicator(2, 'Map', _isMapCompleted, _currentStep >= 2),
                    SizedBox(height: 20),
                    _buildMapSelector(enabled: _isDistrictCompleted),

                    SizedBox(height: 30),
                    Container(height: 1, color: Colors.grey[300]),
                    SizedBox(height: 30),

                    // Step 3: Details (Always visible, but disabled until map is completed)
                    _buildStepIndicator(3, 'Details', false, _currentStep >= 3),
                    SizedBox(height: 25),
                    
                    Text(
                      'Address Title',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField('Please give the address a name', _addressTitleController, enabled: _canProceedToDetails),
                    
                    SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Street Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField('Street name', _streetNameController, enabled: _canProceedToDetails),
                            ],
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Building Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField('Building Number', _buildingNumberController, enabled: _canProceedToDetails),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    Text(
                      'Full Address',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField('Full Address', _fullAddressController, maxLines: 3, enabled: _canProceedToDetails),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: GestureDetector(
                onTap: _canProceedToDetails ? _saveAddress : null,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _canProceedToDetails ? Color(0xFF1E3A8A) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _canProceedToDetails ? 'SAVE' : 'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _canProceedToDetails ? 0.5 : 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}