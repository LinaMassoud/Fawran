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
import '../services/api_service.dart';
import '../steps/address_selection_step.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import '../widgets/reusable_header_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddNewAddressScreen extends ConsumerStatefulWidget {
  final PackageModel? package;
  final int? serviceId;
  final String? user_id;

  const AddNewAddressScreen({
    Key? key,
    this.package,
    this.user_id,
    this.serviceId,
  }) : super(key: key);

  @override
  _AddNewAddressScreenState createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends ConsumerState<AddNewAddressScreen> {
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

  bool _useCurrentLocation = false;
  bool _hasTriedCurrentLocation = false;
bool _currentLocationFailed = false;
bool _isGettingCurrentLocation = false;

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

    // Add listeners to text controllers
    _addressTitleController.addListener(_onFieldChanged);
    _streetNameController.addListener(_onFieldChanged);
    _houseNumberController.addListener(_onFieldChanged);
    _apartmentNumberController.addListener(_onFieldChanged);
    _fullAddressController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _addressTitleController.removeListener(_onFieldChanged);
    _streetNameController.removeListener(_onFieldChanged);
    _houseNumberController.removeListener(_onFieldChanged);
    _apartmentNumberController.removeListener(_onFieldChanged);
    _fullAddressController.removeListener(_onFieldChanged);
    _notesController.removeListener(_onFieldChanged);

    _addressTitleController.dispose();
    _streetNameController.dispose();
    _buildingNumberController.dispose();
    _houseNumberController.dispose();
    _apartmentNumberController.dispose();
    _fullAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<City> get _cities {
    return _availableCities;
  }




void _showFlushbar(String message, {Color backgroundColor = Colors.orange, IconData icon = Icons.info_outline}) {
  FlashyFlushbar(
    leadingWidget: Icon(
      icon,
      color: Colors.white,
      size: 24,
    ),
    message: message,
    duration: const Duration(seconds: 3),
    trailingWidget: IconButton(
      icon: const Icon(
        Icons.close,
        color: Colors.white,
        size: 20,
      ),
      onPressed: () {
        FlashyFlushbar.cancel();
      },
    ),
    isDismissible: true,
    backgroundColor: backgroundColor,
    messageStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ).show();
}
  List<District> get _districts {
    final seenCodes = <String>{};
    final uniqueDistricts = _availableDistricts.where((district) {
      return seenCodes.add(district.districtCode);
    }).toList();

    return uniqueDistricts;
  }

  LatLng? get _districtLocation {
    // Since we're using API data now, return a default location or use district map data
    if (_districtMapData != null) {
      return LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
    }
    return LatLng(24.6877, 46.7219); // Default Riyadh location
  }


List<String> _getLocalizedHouseTypes(AppLocalizations loc) {
  return [loc.villa, loc.appartment];
}
  void _onCityChanged(City? city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedDistrictCode = null;
      _availableDistricts.clear();

      // Clear map-related data when city changes
      _districtMapData = null;
      _selectedLocation = null;
      _isMapCompleted = false;
      _hasUserMovedPin = false;
      _isLocationConfirmed = false;

      if (city != null) {
        final selectedCityObj = _availableCities.firstWhere(
          (city) => city.cityName == city.cityName,
          orElse: () => City(cityCode: 0, cityName: ''),
        );
        _selectedCityCode = city.cityCode;

        if (_selectedCityCode != null && _selectedCityCode! > 0) {
          _fetchDistrictsFromAPI(city.cityCode!);
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

      // Clear map-related data when district changes
      _selectedLocation = null;
      _isMapCompleted = false;
      _hasUserMovedPin = false;
      _isLocationConfirmed = false;

      if (value != null) {
        _selectedDistrictCode = value;

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
      } else if (!_isDistrictCompleted && _currentStep > 1) {
        // Reset to step 1 if district is no longer completed
        _currentStep = 1;
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
      if (!_canProceedToDetails && _currentStep > 2) {
        // Reset to appropriate step if conditions are no longer met
        if (_isDistrictCompleted && !_isMapCompleted) {
          _currentStep = 2;
        } else if (!_isDistrictCompleted) {
          _currentStep = 1;
        }
      }
    });
  }

  Future<void> _createAddressAPI() async {
  final loc = AppLocalizations.of(context)!;
  
  if (_selectedLocation == null || _selectedDistrictCode == null) {
    _showFlushbar('Missing required location or district information', backgroundColor: Colors.red, icon: Icons.error_outline);
    return;
  }

  // Validate house type selection
  if (_selectedHouseType == null) {
    _showFlushbar('Please select a house type', backgroundColor: Colors.red, icon: Icons.error_outline);
    return;
  }

  // Validate apartment-specific fields if house type is Apartment
  if (_selectedHouseType == loc.appartment) {
    if (_selectedFloorNumber == null) {
      _showFlushbar('Floor number is required for apartments', backgroundColor: Colors.red, icon: Icons.error_outline);
      return;
    }
    if (_apartmentNumberController.text.isEmpty) {
      _showFlushbar('Apartment number is required for apartments', backgroundColor: Colors.red, icon: Icons.error_outline);
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
    int houseTypeValue = _selectedHouseType == loc.villa ? 1 : 2;

    // Parse building/house number
    int buildingNumber = int.tryParse(_houseNumberController.text) ?? 0;

    // Call API service
    final result = await ApiService.createAddress(
      buildingName: _addressTitleController.text.isNotEmpty
          ? _addressTitleController.text
          : '',
      buildingNumber: _houseNumberController.text, // Now passing string directly
      cityCode: _useCurrentLocation 
    ? _selectedCityCode?.toString() ?? ''  // Use validated city code
    : _selectedCityCode?.toString() ?? '',
districtId: _useCurrentLocation
    ? _selectedDistrictCode?.toString() ?? ''  // Use validated district code  
    : _selectedDistrictCode?.toString() ?? '',
      houseType: houseTypeValue,
      createdBy: 1,
      customerId: widget.user_id ?? '',
      mapUrl: mapUrl,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      apartmentNumber: _selectedHouseType == loc.appartment
          ? _apartmentNumberController.text // Now passing string directly
          : null,
      floorNumber: _selectedHouseType == loc.appartment
          ? _selectedFloorNumber
          : null,
    );

    // Create newAddress object with correct property names
    final newAddress = {
      'title': _addressTitleController.text,
      'streetName': _streetNameController.text,
      'houseNumber': _houseNumberController.text,
      'apartmentNumber': _apartmentNumberController.text,
      'floorNumber': _selectedFloorNumber?.toString() ?? '',
      'houseType': _selectedHouseType,
      'fullAddress': _fullAddressController.text,
      'notes': _notesController.text,
      'city': _selectedCityCode, // Changed from cityCode to city
      'districtCode': _selectedDistrictCode, // Added districtCode property
      'district': _selectedDistrict, // Keep this for backward compatibility
      'coordinates': {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      },
      'api_response': result['data'],
    };

    // Create displayAddress object
    final displayAddress = {
      'city': _selectedCity?.cityName,
      'district': _districts.firstWhere(
        (d) => d.districtCode == _selectedDistrictCode,
      ),
      'fullAddress': _fullAddressController.text,
    };

    // Hide loading indicator
    Navigator.of(context).pop();

    if (result['success']) {
      // Success - Return result to parent screen
      // _showFlushbar(result['message'], backgroundColor: Colors.green, icon: Icons.check_circle_outline);

      // Return success result to parent screen with newAddress included
      Navigator.of(context).pop({
        'success': true,
        'refresh_addresses': true,
        'message': result['message'],
        'newAddress': newAddress, // Added this line
        'displayAddress': displayAddress,
      });
      
    } else {
      // Error
      _showFlushbar(result['message'], backgroundColor: Colors.red, icon: Icons.error_outline);
    }
  } catch (e) {
    // Hide loading indicator if still showing
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    print('Exception creating address: $e');
    _showFlushbar('Network error. Please check your connection and try again.', backgroundColor: Colors.red, icon: Icons.wifi_off);
  }
}


////hene
  Future<void> _fetchDistrictMapData(String districtCode) async {
  setState(() {
    _isLoadingDistrictMap = true;
  });

  try {
    final districtMapResponse = await ApiService.fetchDistrictMapData(districtCode);
    setState(() {
      _districtMapData = districtMapResponse;
      _isLoadingDistrictMap = false;
    });
  } catch (e) {
    print('Error fetching district map data: $e');
    setState(() {
      _isLoadingDistrictMap = false;
    });
    _showFlushbar('Failed to load district map data. Please try again.', backgroundColor: Colors.red, icon: Icons.error_outline);
  }
}

  Future<void> _fetchCitiesFromAPI(int serviceId) async {
  setState(() {
    _isLoadingCities = true;
  });

  try {
    final cities = await ApiService.fetchCities(serviceId);
    setState(() {
      _availableCities = cities;
      _isLoadingCities = false;
    });
  } catch (e) {
    print('Error fetching cities: $e');
    setState(() {
      _isLoadingCities = false;
    });
    _showFlushbar('Failed to load cities. Please try again.', backgroundColor: Colors.red, icon: Icons.error_outline);
  }
}

  Future<void> _fetchDistrictsFromAPI(int cityCode) async {
  setState(() {
    _isLoadingDistricts = true;
  });

  try {
    final districts = await ApiService.fetchDistricts(cityCode);
    setState(() {
      _availableDistricts = districts;
      _isLoadingDistricts = false;
    });
  } catch (e) {
    print('Error fetching districts: $e');
    setState(() {
      _isLoadingDistricts = false;
    });
    _showFlushbar('Failed to load districts. Please try again.', backgroundColor: Colors.red, icon: Icons.error_outline);
  }
}

  // Now update your main widget's _openMapSelector method to use this new dialog:
  Future<void> _openMapSelector() async {
  if (!_isDistrictCompleted) return;
  
  // Don't open map if still loading district map data
  if (_isLoadingDistrictMap) {
    _showFlushbar('Please wait while map data is loading...', backgroundColor: Colors.blue, icon: Icons.hourglass_empty);
    return;
  }
  
  // Don't open map if district map data is not available yet
  if (_selectedDistrictCode != null && _districtMapData == null) {
    _showFlushbar('Map data not available. Please try again.', backgroundColor: Colors.red, icon: Icons.error_outline);
    return;
  }

  LatLng initialLocation;

  // First priority: Use previously selected location if exists
  if (_selectedLocation != null) {
    initialLocation = _selectedLocation!;
  }
  // Second priority: Use district map data if available
  else if (_districtMapData != null) {
    initialLocation =
        LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
  }
  // Fallback: Use default location
  else {
    initialLocation = _districtLocation ?? LatLng(24.6877, 46.7219);
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => MapSelectorDialog(
      initialLocation: initialLocation,
      boundaryCoordinates: _districtMapData?.polygonCoordinates,
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

  void _onFieldChanged() {
    setState(() {
      // This will trigger a rebuild and update the save button state
    });
  }

  bool _areAllFieldsValid() {
  final loc = AppLocalizations.of(context)!;
  
  // Check basic required fields
  if (_addressTitleController.text.trim().isEmpty ||
      _selectedHouseType == null ||
      _streetNameController.text.trim().isEmpty ||
      _houseNumberController.text.trim().isEmpty ||
      _fullAddressController.text.trim().isEmpty) {
    return false;
  }

  // If not using current location, check location-specific fields
  if (!_useCurrentLocation) {
    if (_selectedLocation == null ||
        _selectedCity == null ||
        _selectedDistrictCode == null ||
        _selectedDistrictCode!.isEmpty) {
      return false;
    }
  }

  // Check apartment-specific fields if house type is Apartment
  if (_selectedHouseType == loc.appartment) {
    if (_selectedFloorNumber == null ||
        _apartmentNumberController.text.trim().isEmpty) {
      return false;
    }
  }

  return true;
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


void _toggleCurrentLocation() {
  if (!_hasTriedCurrentLocation) {
    // First time clicking - try to get current location
    _getCurrentLocation();
  }
  // Remove the else conditions - don't allow toggling back
}

Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingCurrentLocation = true;
    _hasTriedCurrentLocation = true;
  });

  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Validate coordinates with API
    final validationResult = await ApiService.validateCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (validationResult['success'] && validationResult['data']['valid']) {
      // Coordinates are valid - proceed with current location
      final districtData = validationResult['data'];
      
      // Extract city code and district code from validation response
      final cityCode = int.tryParse(districtData['city_code']);
      final districtCode = districtData['district_code'];
      
      setState(() {
        _useCurrentLocation = true;
        _currentLocationFailed = false;
        _isGettingCurrentLocation = false;
        _selectedLocation = LatLng(position.latitude, position.longitude);
        
        // Set the validated district and city codes from API response
        _selectedDistrictCode = districtCode;
        _selectedCityCode = cityCode;
        
        // Mark steps as completed for current location
        _isDistrictCompleted = true;
        _isMapCompleted = true;
        _canProceedToDetails = true;
        _currentStep = 3;
      });

      // Load cities and districts for the validated location
      if (cityCode != null && cityCode > 0) {
        // Load cities first (if not already loaded)
        if (_availableCities.isEmpty) {
          await _fetchCitiesFromAPI(widget.serviceId ?? 1);
        }
        
        // Find and set the selected city
        final selectedCity = _availableCities.firstWhere(
          (city) => city.cityCode == cityCode,
          orElse: () => City(cityCode: cityCode, cityName: ''),
        );
        
        // Load districts for this city
        await _fetchDistrictsFromAPI(cityCode);
        
        // Update the selected city after districts are loaded
        setState(() {
          _selectedCity = selectedCity;
          // Find the district name for display
          final selectedDistrict = _availableDistricts.firstWhere(
            (district) => district.districtCode == districtCode,
            orElse: () => District(districtCode: districtCode, districtName: ''),
          );
          _selectedDistrict = selectedDistrict.districtName;
        });
      }

      // Get address from coordinates for display
      await _handleLocationSelection(LatLng(position.latitude, position.longitude));

      // Show success message
      _showFlushbar('Current location validated successfully', backgroundColor: Colors.green, icon: Icons.check_circle_outline);

    } else {
      // Coordinates are not valid - fall back to manual selection
      setState(() {
        _useCurrentLocation = false;
        _currentLocationFailed = true;
        _isGettingCurrentLocation = false;
        _isDistrictCompleted = false;
        _isMapCompleted = false;
        _canProceedToDetails = false;
        _currentStep = 1;
      });

      // Show error message about invalid location
      String errorMessage = validationResult['message'] ?? 'Location not in service area';
          
      _showFlushbar('$errorMessage. Please select address manually.', backgroundColor: Colors.orange, icon: Icons.location_off);
    }

  } catch (e) {
    // GPS/Permission error - allow manual selection
    setState(() {
      _useCurrentLocation = false;
      _currentLocationFailed = true;
      _isGettingCurrentLocation = false;
      _isDistrictCompleted = false;
      _isMapCompleted = false;
      _canProceedToDetails = false;
      _currentStep = 1;
    });

    // Show error message
    _showFlushbar('Failed to get current location: ${e.toString()}', backgroundColor: Colors.red, icon: Icons.location_disabled);
  }
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
    // All validations passed, proceed with API call
    _createAddressAPI();
  }

  Widget _buildStepIndicator(int stepNumber, String title, bool isCompleted, bool isActive) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    ],
  );
}

  Widget _buildCityDropdown(AppLocalizations loc) {
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
        loc.selectCity,
        _selectedCity, // This should now be a City object, not a String
        _cities, // This should now be a list of City objects
        _onCityChanged,
        enabled:
            !_isLoadingCities // Keep the condition for enabled/disabled state
        );
  }

  Widget _buildDistrictDropdown(AppLocalizations loc) {
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

    return _buildDropdown(loc.selectDistrict, _selectedDistrict,
        _districts, _onDistrictChanged,
        enabled: _selectedCity != null && !_isLoadingDistricts);
  }

  Widget _buildDropdown(String hint, String? value, List<District> items,
    Function(String?) onChanged,
    {bool enabled = true}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
        items: items.map((District item) {
          return DropdownMenuItem<String>(
            value: item.districtCode,
              child: Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  item.districtName,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? Colors.black : Colors.grey[400],
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        icon: Icon(Icons.keyboard_arrow_down,
            color: enabled ? Colors.grey[600] : Colors.grey[400]),
        isExpanded: true,
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    ),
  );
}

  Widget _buildaCityDropdown(
    String hint, City? value, List<City> items, Function(City?) onChanged,
    {bool enabled = true}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
            child: Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  city.cityName,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? Colors.black : Colors.grey[400],
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        icon: Icon(Icons.keyboard_arrow_down,
            color: enabled ? Colors.grey[600] : Colors.grey[400]),
        isExpanded: true,
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    ),
  );
}
  
  Widget _buildCurrentLocationButton({required AppLocalizations loc}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  if (_currentLocationFailed && _hasTriedCurrentLocation) {
    return SizedBox.shrink();
  }

  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: 20),
    child: Center(
      child: Container(
        width: 325,
        child: ElevatedButton.icon(
          onPressed: _isGettingCurrentLocation ? null : _toggleCurrentLocation,
          icon: _isGettingCurrentLocation
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.grey[600],
                    strokeWidth: 2,
                  ),
                )
              : _useCurrentLocation 
                  ? Icon(
                      Icons.location_on,
                      color: Colors.white,
                    )
                  : Padding(
                    padding: EdgeInsets.only(
                      right: isArabic ? 0 : 8, // Conditional padding for RTL
                      left: isArabic ? 8 : 0,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/my_location.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Color(0xFF1E3A8A),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
          label: Text(
            _isGettingCurrentLocation
                ? loc.gettingLocation
                : _useCurrentLocation
                    ? loc.currentLocationSelected
                    : loc.autoSelectLocation,
            style: TextStyle(
              color: _useCurrentLocation ? Colors.white : Color(0xFF1E3A8A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _useCurrentLocation ? Color(0xFF1E3A8A) : Colors.grey[100],
            foregroundColor: _useCurrentLocation ? Colors.white : Color(0xFF1E3A8A),
            side: BorderSide(
              color: Color(0xFF1E3A8A),
              width: 1,
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: _useCurrentLocation ? 2 : 0,
          ),
        ),
      ),
    ),
  );
}
  Widget _buildHouseTypeDropdown({bool enabled = true, required AppLocalizations loc}) {
  final localizedHouseTypes = _getLocalizedHouseTypes(loc);
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
          loc.selectHouseType,
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey[400],
            fontSize: 16,
          ),
        ),
        value: _selectedHouseType,
        items: localizedHouseTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
              child: Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? Colors.black : Colors.grey[400],
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          );
        }).toList(),
        onChanged: enabled
            ? (String? value) {
                setState(() {
                  _selectedHouseType = value;
                  // Clear apartment-specific fields when switching to Villa
                  if (value == loc.villa) {
                    _selectedFloorNumber = null;
                    _apartmentNumberController.clear();
                  }
                  // Trigger validation update
                  _onFieldChanged();
                });
              }
            : null,
        icon: Icon(Icons.keyboard_arrow_down,
            color: enabled ? Colors.grey[600] : Colors.grey[400]),
        isExpanded: true,
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    ),
  );
}

// 5. Update the floor dropdown onChanged to trigger validation
  Widget _buildFloorDropdown({bool enabled = true, required AppLocalizations loc}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
          '${loc.selectFloor} *',
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey[400],
            fontSize: 16,
          ),
        ),
        value: _selectedFloorNumber,
        items: _floorNumbers.map((int floor) {
          return DropdownMenuItem<int>(
            value: floor,
            child: Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  '${loc.floor} $floor',
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? Colors.black : Colors.grey[400],
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          );
        }).toList(),
        onChanged: enabled
            ? (int? value) {
                setState(() {
                  _selectedFloorNumber = value;
                  // Trigger validation update
                  _onFieldChanged();
                });
              }
            : null,
        icon: Icon(Icons.keyboard_arrow_down, color: enabled ? Colors.grey[600] : Colors.grey[400]),
        isExpanded: true,
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: 300,
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    ),
  );
}

  Widget _buildTextField(String hint, TextEditingController controller,
    {int maxLines = 1, bool enabled = true, int? maxLength}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
      maxLength: maxLength,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: enabled ? Colors.grey[600] : Colors.grey[400],
          fontSize: 16,
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


Widget _buildFormLabel(String text, {bool required = false}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  return Align(
    alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(
      required ? '$text *' : text,
      style: TextStyle(
        fontSize: 16,
        color: _canProceedToDetails ? Colors.grey[600] : Colors.grey[400],
        fontWeight: FontWeight.w500,
      ),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    ),
  );
}

  Widget _buildMapSelector({bool enabled = true, required AppLocalizations loc}) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
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
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          SizedBox(width: 16),
          if (_isLoadingDistrictMap && _selectedDistrictCode != null) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading map data...',
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                _isMapCompleted ? loc.mapSelected : loc.selectMap,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled
                      ? (_isMapCompleted ? Colors.black : Colors.grey[600])
                      : Colors.grey[400],
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
            Text(
              loc.edit,
              style: TextStyle(
                color: enabled ? Colors.grey[700] : Colors.grey[400],
                fontSize: 16,
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
          SizedBox(width: 16),
        ],
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  return Directionality(
    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
    backgroundColor: Colors.grey[100],
    body: Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Sticky Header with same style as cleaning service
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              toolbarHeight: 65,
              backgroundColor: Color(0xFF10295C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFFFFA200),
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                loc.insertAddress,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFA200),
                ),
              ),
              centerTitle: true,
              elevation: 0,
              floating: false,
              snap: false,
            ),
            
            // Main content without overlap
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(top: 8), // Reduced from 20 to 8
                child: Column(
                  children: [
                    // Main Content
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), // Reduced top padding from 32 to 16
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentLocationButton(loc: loc),

                          if (!_useCurrentLocation) ...[
                            // Step 1: District
                            _buildStepIndicator(
                                1, '${loc.district} *', _isDistrictCompleted, _currentStep >= 1),
                            const SizedBox(height: 20),
                            _buildCityDropdown(loc),
                            const SizedBox(height: 15),
                            _buildDistrictDropdown(loc),

                            const SizedBox(height: 30),
                            Container(height: 1, color: Colors.grey[300]),
                            const SizedBox(height: 30),

                            // Step 2: Map
                            _buildStepIndicator(
                                2, '${loc.map} *', _isMapCompleted, _currentStep >= 2),
                            const SizedBox(height: 20),
                            _buildMapSelector(enabled: _isDistrictCompleted, loc: loc),

                            const SizedBox(height: 30),
                            Container(height: 1, color: Colors.grey[300]),
                            const SizedBox(height: 30),
                          ],

                          // Step 3: Details
                          _buildStepIndicator(
                            _useCurrentLocation ? 1 : 3, 
                            '${loc.details}', 
                            false, 
                            _currentStep >= (_useCurrentLocation ? 1 : 3)
                          ),
                          const SizedBox(height: 25),

                          _buildFormLabel(loc.fullAddress, required: true),
                          const SizedBox(height: 8),
                          _buildTextField('${loc.selectAddress}',
                              _addressTitleController,
                              enabled: _useCurrentLocation || _canProceedToDetails, maxLength: 50),

                          const SizedBox(height: 20),

                          Text(
                            '${loc.houseType} *',
                            style: TextStyle(
                              fontSize: 16,
                              color: _canProceedToDetails
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildHouseTypeDropdown(enabled: _useCurrentLocation || _canProceedToDetails, loc: loc),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${loc.streetName} *',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _canProceedToDetails
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                        loc.streetName, _streetNameController,
                                        enabled: _useCurrentLocation || _canProceedToDetails, maxLength: 50),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedHouseType == loc.villa
                                          ? '${loc.houseNum} *'
                                          : '${loc.buildingNum} *',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _canProceedToDetails
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                        _selectedHouseType == loc.villa
                                            ? loc.houseNum
                                            : loc.buildingNum,
                                        _houseNumberController,
                                        maxLength: 10,
                                        enabled: _useCurrentLocation || _canProceedToDetails),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Conditional apartment fields
                          if (_selectedHouseType == loc.appartment) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${loc.flooeNumber} *',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _canProceedToDetails
                                              ? Colors.grey[600]
                                              : Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildFloorDropdown(
                                          enabled: _useCurrentLocation || _canProceedToDetails, loc: loc),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${loc.appartmentNumber} *',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _canProceedToDetails
                                              ? Colors.grey[600]
                                              : Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTextField(loc.appartmentNumber,
                                          _apartmentNumberController,
                                          enabled: _useCurrentLocation || _canProceedToDetails, maxLength: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          Text(
                            '${loc.fullAddress} *',
                            style: TextStyle(
                              fontSize: 16,
                              color: _canProceedToDetails
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField('${loc.fullAddress}', _fullAddressController,
                              maxLines: 3, enabled: _useCurrentLocation || _canProceedToDetails, maxLength: 100),

                          const SizedBox(height: 20),

                          Text(
                            loc.notes,
                            style: TextStyle(
                              fontSize: 16,
                              color: _canProceedToDetails
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                              '${loc.selectNote}', _notesController,
                              maxLines: 2, enabled: _useCurrentLocation || _canProceedToDetails, maxLength: 100),
                          
                          // Add bottom padding to account for fixed button
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom Button - Fixed at bottom
        Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.of(context).padding.bottom > 0 
        ? MediaQuery.of(context).padding.bottom + 10  // For devices with home indicator (iOS)
        : 25, // For devices without home indicator (most Android)
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF1E49A0).withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, -5),
        ),
        BoxShadow(
          color: Color(0xFF1E49A0).withOpacity(0.08),
          blurRadius: 40,
          spreadRadius: 5,
          offset: const Offset(0, -10),
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ElevatedButton(
          onPressed: (_canProceedToDetails && _areAllFieldsValid())
              ? _saveAddress
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: (_canProceedToDetails && _areAllFieldsValid())
                ? Color(0xFF10295C)
                : null,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Color(0xFF768090),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: (_canProceedToDetails && _areAllFieldsValid()) ? 2 : 0,
          ),
          child: Text(
            loc.save,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
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
}

