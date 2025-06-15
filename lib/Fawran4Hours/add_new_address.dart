import 'package:fawran/screens/newAddressDalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/package_model.dart';
import '../models/address_model.dart';

class AddNewAddressScreen extends StatefulWidget {
  final PackageModel? package;
  final int? serviceId; // Add serviceId parameter

  const AddNewAddressScreen({
    Key? key,
    this.package,
    this.serviceId, // Add serviceId parameter
  }) : super(key: key);

  @override
  _AddNewAddressScreenState createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  // Controllers for form fields
  final TextEditingController _addressTitleController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _buildingNumberController =
      TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _apartmentNumberController =
      TextEditingController();
  String? _selectedHouseType;
  int? _selectedFloorNumber;

  // Dropdown values
  City? _selectedCity;
  String? _selectedDistrict;

  final List<String> _houseTypes = ['Villa', 'Apartment'];
  final List<int> _floorNumbers = List.generate(20, (index) => index + 1);
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
  int? _selectedCityCode; // Store the selected city ID

  DistrictMapResponse? _districtMapData;
  bool _isLoadingDistrictMap = false;

  PackageModel? get package => widget.package;
// Add district-related variables
  List<District> _availableDistricts = [];
  bool _isLoadingDistricts = false;
  String? _selectedDistrictCode;

  @override
  void initState() {
    super.initState();
    // Get serviceId from package, with fallback to default value
    int serviceId = widget.serviceId ?? 1;
    _fetchCitiesFromAPI(serviceId);
  }

  @override
  void dispose() {
    _addressTitleController.dispose();
    _streetNameController.dispose();
    _buildingNumberController.dispose();
    _houseNumberController.dispose(); // Add this
    _apartmentNumberController.dispose(); // Add this
    _fullAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<City> get _cities {
    return _availableCities;
  }

  List<String> get _districts {
    return _availableDistricts
        .map((district) => district.districtName)
        .toList();
  }

  LatLng? get _districtLocation {
    // Since we're using API data now, return a default location or use district map data
    if (_districtMapData != null) {
      return LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
    }
    return LatLng(24.6877, 46.7219); // Default Riyadh location
  }

  void _onCityChanged(City? city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedDistrictCode = null;
      _availableDistricts.clear();

      if (city != null) {
        final selectedCityObj = _availableCities.firstWhere(
          (city) => city.cityName == city.cityName,
          orElse: () => City(cityCode: 0, cityName: ''),
        );
        _selectedCityCode = selectedCityObj.cityCode;

        if (_selectedCityCode != null && _selectedCityCode! > 0) {
          _fetchDistrictsFromAPI(_selectedCityCode!);
        }
      } else {
        _selectedCityCode = null;
      }

      _checkDistrictCompletion();
    });
  }

  void _onDistrictChanged(String? value) {
    setState(() {
      _selectedDistrict = value;

      if (value != null) {
        final selectedDistrictObj = _availableDistricts.firstWhere(
          (district) => district.districtName == value,
          orElse: () => District(districtCode: '', districtName: ''),
        );
        _selectedDistrictCode = selectedDistrictObj.districtCode;

        if (_selectedDistrictCode != null &&
            _selectedDistrictCode!.isNotEmpty) {
          _fetchDistrictMapData(_selectedDistrictCode!);
        }
      } else {
        _selectedDistrictCode = null;
        _districtMapData = null;
      }

      _checkDistrictCompletion();
    });
  }

  void _checkDistrictCompletion() {
    setState(() {
      _isDistrictCompleted = _selectedCity != null && _selectedDistrict != null;
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

  Future<void> _createAddressAPI() async {
    if (_selectedLocation == null || _selectedDistrictCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Missing required location or district information')),
      );
      return;
    }

    // Validate house type selection
    if (_selectedHouseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a house type')),
      );
      return;
    }

    // Validate apartment-specific fields if house type is Apartment
    if (_selectedHouseType == 'Apartment') {
      if (_selectedFloorNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Floor number is required for apartments')),
        );
        return;
      }
      if (_apartmentNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Apartment number is required for apartments')),
        );
        return;
      }
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Create map URL
      String mapUrl =
          'https://maps.google.com/?q=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';

      // Determine house type value (1 for Villa, 2 for Apartment)
      int houseTypeValue = _selectedHouseType == 'Villa' ? 1 : 2;

      // Parse building/house number
      int? buildingNumber;
      if (_houseNumberController.text.isNotEmpty) {
        buildingNumber = int.tryParse(_houseNumberController.text);
      }

      // Prepare request body - Fix data types to match API expectations
      Map<String, dynamic> requestBody = {
        'building_name': _addressTitleController.text.isNotEmpty
            ? _addressTitleController.text
            : '',
        'building_number': buildingNumber ?? 0,
        'city_code': _selectedCityCode?.toString() ?? '', // Keep as string
        'district_id':
            _selectedDistrictCode?.toString() ?? '', // Keep as string
        'house_type': houseTypeValue,
        'created_by': 1, // Keep as int
        'customer_id': 23, // Change from string to int
        'map_url': mapUrl,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      };

      // Add apartment-specific fields only if house type is Apartment
      if (_selectedHouseType == 'Apartment') {
        requestBody['apartment_number'] =
            int.tryParse(_apartmentNumberController.text) ?? 0;
        requestBody['floor_number'] = _selectedFloorNumber ?? 0;
      }
      // Note: Don't add apartment_number and floor_number for Villa type at all

      print(
          'Sending POST request with body: ${json.encode(requestBody)}'); // Debug print

      final response = await http.post(
        Uri.parse(
            'http://10.20.10.114:8080/ords/emdad/fawran/customer_addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Add Accept header
        },
        body: json.encode(requestBody),
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return the created address data to previous screen
        final newAddress = {
          'title': _addressTitleController.text,
          'streetName': _streetNameController.text,
          'houseNumber': _houseNumberController.text,
          'apartmentNumber': _apartmentNumberController.text,
          'floorNumber': _selectedFloorNumber?.toString() ?? '',
          'houseType': _selectedHouseType,
          'fullAddress': _fullAddressController.text,
          'notes': _notesController.text,
          'city': _selectedCity?.cityCode,
          'district': _selectedDistrict,
          'coordinates': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'api_response': json.decode(response.body), // Include API response
        };

        Navigator.pop(context, newAddress);
      } else {
        // Error - Handle HTML error responses
        String errorMessage = 'Failed to create address. Please try again.';

        // Check if response is HTML (like the 555 error you're getting)
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          errorMessage =
              'Server error occurred. Please check your network connection and try again.';
        } else {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            // Keep default error message
          }
        }

        print(
            'API Error: ${response.statusCode} - ${response.body}'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Exception creating address: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Network error. Please check your connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

////hene
  Future<void> _fetchDistrictMapData(String districtCode) async {
    setState(() {
      _isLoadingDistrictMap = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.20.10.114:8080/ords/emdad/fawran/districts/info/$districtCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final districtMapResponse =
            DistrictMapResponse.fromJson(json.decode(response.body));
        setState(() {
          _districtMapData = districtMapResponse;
          _isLoadingDistrictMap = false;
        });
      } else {
        throw Exception('Failed to load district map data');
      }
    } catch (e) {
      print('Error fetching district map data: $e');
      setState(() {
        _isLoadingDistrictMap = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to load district map data. Please try again.')),
      );
    }
  }

  Future<void> _fetchCitiesFromAPI(int serviceId) async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.20.10.114:8080/ords/emdad/fawran/service_cities/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Parse the direct array response
        List<dynamic> citiesJson = json.decode(response.body);
        List<City> cities =
            citiesJson.map((city) => City.fromJson(city)).toList();

        setState(() {
          _availableCities = cities;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cities. Please try again.')),
      );
    }
  }

  Future<void> _fetchDistrictsFromAPI(int cityCode) async {
    setState(() {
      _isLoadingDistricts = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.20.10.114:8080/ords/emdad/fawran/districts/$cityCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Parse the direct array response
        List<dynamic> districtsJson = json.decode(response.body);
        List<District> districts = districtsJson
            .map((district) => District.fromJson(district))
            .toList();

        setState(() {
          _availableDistricts = districts;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load districts. Please try again.')),
      );
    }
  }

  // Now update your main widget's _openMapSelector method to use this new dialog:
  Future<void> _openMapSelector() async {
    if (!_isDistrictCompleted) return;

    LatLng initialLocation;

    // Use district map data if available, otherwise fallback to default
    if (_districtMapData != null) {
      initialLocation =
          LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
    } else {
      initialLocation = _districtLocation ?? LatLng(24.6877, 46.7219);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => MapSelectorDialog(
        initialLocation: initialLocation,
        boundaryCoordinates:
            _districtMapData?.polygonCoordinates, // Pass boundary coordinates
        onLocationSelected: (LatLng selectedLocation) async {
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
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
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
          _fullAddressController.text = fullAddress.isNotEmpty
              ? fullAddress
              : '$_selectedDistrict, $_selectedCity, Saudi Arabia';
          if (place.street != null && place.street!.isNotEmpty) {
            _streetNameController.text = place.street!;
          }
        });
      }
    } catch (e) {
      // Fallback to basic address format
      setState(() {
        _fullAddressController.text =
            '$_selectedDistrict, $_selectedCity, Saudi Arabia';
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
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
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
          _fullAddressController.text = fullAddress.isNotEmpty
              ? fullAddress
              : '$_selectedDistrict, $_selectedCity, Saudi Arabia';
          if (place.street != null && place.street!.isNotEmpty) {
            _streetNameController.text = place.street!;
          }
        });
      }
    } catch (e) {
      // Fallback to basic address format
      setState(() {
        _fullAddressController.text =
            '$_selectedDistrict, $_selectedCity Saudi Arabia';
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

    if (_selectedHouseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a house type')),
      );
      return;
    }

    // Validate house number
    if (_houseNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_selectedHouseType == 'Villa'
                ? 'Please enter house number'
                : 'Please enter building number')),
      );
      return;
    }

    // Validate apartment-specific fields
    if (_selectedHouseType == 'Apartment') {
      if (_selectedFloorNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select floor number for apartment')),
        );
        return;
      }
      if (_apartmentNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter apartment number')),
        );
        return;
      }
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    if (_selectedDistrictCode == null || _selectedDistrictCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a district')),
      );
      return;
    }

    _createAddressAPI();
  }

  Widget _buildStepIndicator(
      int stepNumber, String title, bool isCompleted, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : (isActive ? Color(0xFF1E3A8A) : Colors.grey[300]),
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
            color: isCompleted
                ? Colors.green
                : (isActive ? Color(0xFF1E3A8A) : Colors.grey[500]),
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

    return _buildaCityDropdown(
        'Please select your city',
        _selectedCity, // This should now be a City object, not a String
        _cities, // This should now be a list of City objects
        _onCityChanged,
        enabled:
            !_isLoadingCities // Keep the condition for enabled/disabled state
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

    return _buildDropdown('Please select your District', _selectedDistrict,
        _districts, _onDistrictChanged,
        enabled: _selectedCity != null && !_isLoadingDistricts);
  }

  Widget _buildDropdown(String hint, String? value, List<String> items,
      Function(String?) onChanged,
      {bool enabled = true}) {
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
          icon: Icon(Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[400]),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildaCityDropdown(
      String hint, City? value, List<City> items, Function(City?) onChanged,
      {bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? Colors.white : Colors.grey[100],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<City>(
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
          value: value,
          items: items.map((City city) {
            return DropdownMenuItem<City>(
              value: city,
              child: Text(
                city.cityName, // Display city name in the dropdown
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.black : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          icon: Icon(Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[400]),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildHouseTypeDropdown({bool enabled = true}) {
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
            'Select house type',
            style: TextStyle(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
          value: _selectedHouseType,
          items: _houseTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.black : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled
              ? (String? value) {
                  setState(() {
                    _selectedHouseType = value;
                    // Clear apartment-specific fields when switching to Villa
                    if (value == 'Villa') {
                      _selectedFloorNumber = null;
                      _apartmentNumberController.clear();
                    }
                  });
                }
              : null,
          icon: Icon(Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[400]),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildFloorDropdown({bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? Colors.white : Colors.grey[100],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          hint: Text(
            'Select floor',
            style: TextStyle(
              color: enabled ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
          value: _selectedFloorNumber,
          items: _floorNumbers.map((int floor) {
            return DropdownMenuItem<int>(
              value: floor,
              child: Text(
                'Floor $floor',
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.black : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
          onChanged: enabled
              ? (int? value) {
                  setState(() {
                    _selectedFloorNumber = value;
                  });
                }
              : null,
          icon: Icon(Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[400]),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {int maxLines = 1, bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 4),
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
              fontSize: 16),
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
                    _buildStepIndicator(
                        1, 'District', _isDistrictCompleted, _currentStep >= 1),
                    SizedBox(height: 20),
                    _buildCityDropdown(),
                    SizedBox(height: 15),
                    _buildDistrictDropdown(),

                    SizedBox(height: 30),
                    Container(height: 1, color: Colors.grey[300]),
                    SizedBox(height: 30),

                    // Step 2: Map
                    _buildStepIndicator(
                        2, 'Map', _isMapCompleted, _currentStep >= 2),
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
                        color: _canProceedToDetails
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField('Please give the address a name',
                        _addressTitleController,
                        enabled: _canProceedToDetails),

                    SizedBox(height: 20),

                    Text(
                      'House Type',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildHouseTypeDropdown(enabled: _canProceedToDetails),

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
                                  color: _canProceedToDetails
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField(
                                  'Street name', _streetNameController,
                                  enabled: _canProceedToDetails),
                            ],
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedHouseType == 'Villa'
                                    ? 'House Number'
                                    : 'Building Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _canProceedToDetails
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField(
                                  _selectedHouseType == 'Villa'
                                      ? 'House Number'
                                      : 'Building Number',
                                  _houseNumberController,
                                  enabled: _canProceedToDetails),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Conditional apartment fields
                    if (_selectedHouseType == 'Apartment') ...[
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Floor Number',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _canProceedToDetails
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildFloorDropdown(
                                    enabled: _canProceedToDetails),
                              ],
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apartment Number',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _canProceedToDetails
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildTextField('Apartment Number',
                                    _apartmentNumberController,
                                    enabled: _canProceedToDetails),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 20),

                    Text(
                      'Full Address',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField('Full Address', _fullAddressController,
                        maxLines: 3, enabled: _canProceedToDetails),

                    SizedBox(height: 20),

                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        color: _canProceedToDetails
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTextField(
                        'Unit Number, Entrance code etc..', _notesController,
                        maxLines: 2, enabled: _canProceedToDetails),
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
                    color: _canProceedToDetails
                        ? Color(0xFF1E3A8A)
                        : Colors.grey[400],
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
