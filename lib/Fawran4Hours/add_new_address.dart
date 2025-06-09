import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class City {
  final int cityId;
  final String cityName;

  City({required this.cityId, required this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['city_id'],
      cityName: json['city_name'],
    );
  }
}

class CitiesResponse {
  final List<City> cities;

  CitiesResponse({required this.cities});

  factory CitiesResponse.fromJson(Map<String, dynamic> json) {
    var cityList = json['cities'] as List;
    List<City> cities = cityList.map((city) => City.fromJson(city)).toList();
    return CitiesResponse(cities: cities);
  }
}

// Add District model classes
class District {
  final int districtId;
  final String districtName;

  District({required this.districtId, required this.districtName});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtId: json['district_id'],
      districtName: json['district_name'],
    );
  }
}

class DistrictsResponse {
  final List<District> districts;

  DistrictsResponse({required this.districts});

  factory DistrictsResponse.fromJson(Map<String, dynamic> json) {
    var districtList = json['districts'] as List;
    List<District> districts = districtList.map((district) => District.fromJson(district)).toList();
    return DistrictsResponse(districts: districts);
  }
}

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({Key? key}) : super(key: key);

  @override
  _AddNewAddressScreenState createState() => _AddNewAddressScreenState();
}
class MapSelectorDialog extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapSelectorDialog({
    Key? key,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _MapSelectorDialogState createState() => _MapSelectorDialogState();
}

class _MapSelectorDialogState extends State<MapSelectorDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _hasUserMovedMap = false;
  bool _isLocationConfirmed = false;
   MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    // Initialize with the initial location
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.of(context).pop(),
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
                target: widget.initialLocation,
                zoom: 15.0,
              ),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: _currentMapType,
              zoomControlsEnabled: false,
            ),
            // Fixed center pin - always visible
            Center(
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            // Custom zoom controls (top right)
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                children: [
                  // Zoom in button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.black54, size: 24),
                      onPressed: _zoomIn,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Zoom out button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.remove, color: Colors.black54, size: 24),
                      onPressed: _zoomOut,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            // In the MapSelectorDialog's build method, replace the map type selector Positioned widget:

// Map type selector (positioned properly above the confirm button)
Positioned(
  bottom: 100, // Increased from 80 to give more space above the button
  left: 20,    // Added left margin
  right: 20,   // Added right margin
  child: Center(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Reduced shadow opacity
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MAP button
          GestureDetector(
            onTap: () => _changeMapType(MapType.normal),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding
              decoration: BoxDecoration(
                color: _currentMapType == MapType.normal 
                    ? Color(0xFF1E3A8A) 
                    : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                'MAP',
                style: TextStyle(
                  color: _currentMapType == MapType.normal 
                      ? Colors.white 
                      : Colors.black87, // Changed from black54 to black87
                  fontSize: 14, // Increased font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // SATELLITE button
          GestureDetector(
            onTap: () => _changeMapType(MapType.satellite),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding
              decoration: BoxDecoration(
                color: _currentMapType == MapType.satellite 
                    ? Color(0xFF1E3A8A) 
                    : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'SATELLITE',
                style: TextStyle(
                  color: _currentMapType == MapType.satellite 
                      ? Colors.white 
                      : Colors.black87, // Changed from black54 to black87
                  fontSize: 14, // Increased font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
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
                child: _buildMapActionButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton() {
    if (!_hasUserMovedMap) {
      // Initial state - show instruction text
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'MOVE MAP TO POSITION PIN ON YOUR LOCATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // User has moved map - show confirm button (ENABLED)
      return GestureDetector(
        onTap: _confirmLocationSelection,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Color(0xFF1E3A8A), // Blue color to show it's active
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'CONFIRM LOCATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Update the selected location as the user moves the map
    _selectedLocation = position.target;
    
    // Mark that user has moved the map (but don't trigger setState here for performance)
    if (!_hasUserMovedMap) {
      setState(() {
        _hasUserMovedMap = true;
      });
    }
  }

  void _onCameraIdle() {
    // This is called when the user stops moving the map
    // The _selectedLocation is already updated in _onCameraMove
    print('Camera idle at: ${_selectedLocation?.latitude}, ${_selectedLocation?.longitude}'); // Debug print
  }

  void _confirmLocationSelection() {
    print('Confirming location selection'); // Debug print
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      Navigator.of(context).pop();
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _changeMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
    });
  }

  void _proceedToDetails() {
    print('Proceeding to details with location: $_selectedLocation'); // Debug print
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      Navigator.of(context).pop();
    }
  }
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
  bool _hasUserMovedPin = false; // Track if user has moved the pin
  bool _isLocationConfirmed = false; // Track if location is confirmed

List<City> _availableCities = [];
bool _isLoadingCities = false;
int? _selectedCityId; // Store the selected city ID

// Add district-related variables
List<District> _availableDistricts = [];
bool _isLoadingDistricts = false;
int? _selectedDistrictId;
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
  return _availableCities.map((city) => city.cityName).toList();
}

  List<String> get _districts {
  return _availableDistricts.map((district) => district.districtName).toList();
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
    _selectedCityId = null;
    _selectedDistrictId = null;
    _availableCities.clear(); // Clear previous cities
    _availableDistricts.clear(); // Clear previous districts
    _checkDistrictCompletion();
  });
  
  // Fetch cities from API when province is selected
  if (value != null) {
    _fetchCitiesFromAPI();
  }
}

  void _onCityChanged(String? value) {
  setState(() {
    _selectedCity = value;
    _selectedDistrict = null;
    _selectedDistrictId = null;
    _availableDistricts.clear(); // Clear previous districts
    
    // Find and store the selected city ID
    if (value != null) {
      final selectedCityObj = _availableCities.firstWhere(
        (city) => city.cityName == value,
        orElse: () => City(cityId: 0, cityName: ''),
      );
      _selectedCityId = selectedCityObj.cityId;
      
      // Fetch districts for the selected city
      if (_selectedCityId != null && _selectedCityId! > 0) {
        _fetchDistrictsFromAPI(_selectedCityId!);
      }
    } else {
      _selectedCityId = null;
    }
    
    _checkDistrictCompletion();
  });
}

  void _onDistrictChanged(String? value) {
  setState(() {
    _selectedDistrict = value;
    
    // Find and store the selected district ID
    if (value != null) {
      final selectedDistrictObj = _availableDistricts.firstWhere(
        (district) => district.districtName == value,
        orElse: () => District(districtId: 0, districtName: ''),
      );
      _selectedDistrictId = selectedDistrictObj.districtId;
    } else {
      _selectedDistrictId = null;
    }
    
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

Future<void> _fetchCitiesFromAPI() async {
  setState(() {
    _isLoadingCities = true;
  });

  try {
    final response = await http.get(
      Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/address/cities?service_id=1'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final citiesResponse = CitiesResponse.fromJson(json.decode(response.body));
      setState(() {
        _availableCities = citiesResponse.cities;
        _isLoadingCities = false;
      });
    } else {
      throw Exception('Failed to load cities');
    }
  } catch (e) {
    print('Error fetching cities: $e');
    setState(() {
      _isLoadingCities = false;
    });
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load cities. Please try again.')),
    );
  }
}
Future<void> _fetchDistrictsFromAPI(int cityId) async {
  setState(() {
    _isLoadingDistricts = true;
  });

  try {
    final response = await http.get(
      Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/address/districts?service_id=1&city_id=$cityId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final districtsResponse = DistrictsResponse.fromJson(json.decode(response.body));
      setState(() {
        _availableDistricts = districtsResponse.districts;
        _isLoadingDistricts = false;
      });
    } else {
      throw Exception('Failed to load districts');
    }
  } catch (e) {
    print('Error fetching districts: $e');
    setState(() {
      _isLoadingDistricts = false;
    });
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load districts. Please try again.')),
    );
  }
}
  // Now update your main widget's _openMapSelector method to use this new dialog:
Future<void> _openMapSelector() async {
  if (!_isDistrictCompleted) return;

  LatLng initialLocation = _districtLocation ?? LatLng(24.6877, 46.7219);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => MapSelectorDialog(
      initialLocation: initialLocation,
      onLocationSelected: (LatLng selectedLocation) async {
        // Handle the selected location here
        setState(() {
          _selectedLocation = selectedLocation;
          _hasUserMovedPin = true;
          _isLocationConfirmed = false;
        });

        await _handleLocationSelection(selectedLocation);
      },
    ),
  );
}
// Add this new method to handle location selection and geocoding:
Future<void> _handleLocationSelection(LatLng selectedLocation) async {
  try {
    // Reverse geocoding to get address from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
      selectedLocation.latitude,
      selectedLocation.longitude,
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

  _onMapCompleted();
}





  Future<void> _proceedToDetails() async {
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
      _hasUserMovedPin = false;
      _isLocationConfirmed = false;
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
Widget _buildCityDropdown() {
  if (_isLoadingCities) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading cities...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  return _buildDropdown(
    'Please select your city', 
    _selectedCity, 
    _cities, 
    _onCityChanged,
    enabled: _selectedProvince != null && !_isLoadingCities
  );
}
Widget _buildDistrictDropdown() {
  if (_isLoadingDistricts) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading districts...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  return _buildDropdown(
    'Please select your District', 
    _selectedDistrict, 
    _districts, 
    _onDistrictChanged,
    enabled: _selectedCity != null && !_isLoadingDistricts
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
                    _buildCityDropdown(),
                    SizedBox(height: 15),
                    _buildDistrictDropdown(),

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