import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

// You'll need to add these dependencies to your pubspec.yaml:
// dependencies:
//   google_maps_flutter: ^2.5.0
//   geolocator: ^10.1.0
//   geocoding: ^2.1.1

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  final TextEditingController _notesController = TextEditingController();

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

  // Map related variables
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _showMapSelector = false;

  // Sample data for dropdowns with corresponding coordinates
  final Map<String, dynamic> _locationData = {
    'Riyadh Province': {
      'cities': {
        'Riyadh': {
          'districts': {
            'Al Malaz': LatLng(24.6877, 46.7219),
            'Al Olaya': LatLng(24.6951, 46.6859),
            'Al Futah': LatLng(24.6408, 46.7146),
            'As Salhiyah': LatLng(24.6693, 46.7357),
          }
        }
      }
    },
    'Makkah Province': {
      'cities': {
        'Jeddah': {
          'districts': {
            'Al Hamra': LatLng(21.5169, 39.2192),
            'Al Balad': LatLng(21.4858, 39.1925),
          }
        },
        'Makkah': {
          'districts': {
            'Ajyad': LatLng(21.4225, 39.8262),
            'Al Misfalah': LatLng(21.4167, 39.8167),
          }
        }
      }
    },
    'Al Madinah Province': {
      'cities': {
        'Medina': {
          'districts': {
            'Al Haram': LatLng(24.4686, 39.6142),
            'Quba': LatLng(24.4378, 39.6158),
          }
        }
      }
    }
  };

  @override
  void initState() {
    super.initState();
    _selectedProvince = 'Riyadh Province'; // Default selection
  }

  @override
  void dispose() {
    _addressTitleController.dispose();
    _streetNameController.dispose();
    _buildingNumberController.dispose();
    _fullAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _provinces => _locationData.keys.toList();

  List<String> get _cities {
    if (_selectedProvince == null) return [];
    return _locationData[_selectedProvince]?['cities']?.keys?.toList() ?? [];
  }

  List<String> get _districts {
    if (_selectedProvince == null || _selectedCity == null) return [];
    return _locationData[_selectedProvince]?['cities']?[_selectedCity]?['districts']?.keys?.toList() ?? [];
  }

  LatLng? get _districtLocation {
    if (_selectedProvince == null || _selectedCity == null || _selectedDistrict == null) return null;
    return _locationData[_selectedProvince]?['cities']?[_selectedCity]?['districts']?[_selectedDistrict];
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

  Future<void> _openMapSelector() async {
    if (!_isDistrictCompleted) return;

    setState(() {
      _showMapSelector = true;
    });

    // Show the map selection dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _buildMapDialog(),
    );
  }

  Widget _buildMapDialog() {
    LatLng initialLocation = _districtLocation ?? LatLng(24.6877, 46.7219);
    
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF1E3A8A),
          title: Text(
            'Select Location',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showMapSelector = false;
              });
            },
          ),
          elevation: 0,
        ),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: initialLocation,
                zoom: 15.0,
              ),
              onTap: _onMapTapped,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
            ),
            // Custom location pin in center
            if (_selectedLocation == null)
              Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            // Bottom button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.white,
                child: GestureDetector(
                  onTap: _selectedLocation != null ? _confirmLocation : null,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedLocation != null ? Color(0xFF1E3A8A) : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'ENTER DETAILS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
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

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: location,
          infoWindow: InfoWindow(title: 'Selected Location'),
        ),
      );
    });
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;

    try {
      // Reverse geocoding to get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          fullAddress += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          fullAddress += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          fullAddress += '${place.locality}, ';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          fullAddress += '${place.administrativeArea}, ';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          fullAddress += place.country!;
        }

        // Remove trailing comma and space
        if (fullAddress.endsWith(', ')) {
          fullAddress = fullAddress.substring(0, fullAddress.length - 2);
        }

        setState(() {
          _fullAddressController.text = fullAddress.isNotEmpty ? fullAddress : 
            '$_selectedDistrict, $_selectedCity, $_selectedProvince, Saudi Arabia';
          if (place.street != null && place.street!.isNotEmpty) {
            _streetNameController.text = place.street!;
          }
        });
      }
    } catch (e) {
      // Fallback to basic address format
      setState(() {
        _fullAddressController.text = '$_selectedDistrict, $_selectedCity, $_selectedProvince, Saudi Arabia';
      });
    }

    Navigator.of(context).pop();
    setState(() {
      _showMapSelector = false;
    });
    _onMapCompleted();
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
      'notes': _notesController.text,
      'province': _selectedProvince,
      'city': _selectedCity,
      'district': _selectedDistrict,
      'coordinates': _selectedLocation != null ? {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      } : null,
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
            color: isCompleted ? Colors.green : (isActive ? Color(0xFF1E3A8A) : Colors.grey[300]),
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
            color: isCompleted ? Colors.green : (isActive ? Color(0xFF1E3A8A) : Colors.grey[500]),
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
      onTap: enabled ? _openMapSelector : null,
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
                      'Province', 
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

                    // Step 2: Map
                    _buildStepIndicator(2, 'Map', _isMapCompleted, _currentStep >= 2),
                    SizedBox(height: 20),
                    _buildMapSelector(enabled: _isDistrictCompleted),

                    SizedBox(height: 30),
                    Container(height: 1, color: Colors.grey[300]),
                    SizedBox(height: 30),

                    // Step 3: Details
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
                    
                    SizedBox(height: 20),
                    
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField('Unit Number, Entrance code etc..', _notesController, maxLines: 2, enabled: _canProceedToDetails),
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
                      'SAVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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