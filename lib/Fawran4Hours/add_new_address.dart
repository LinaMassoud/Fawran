import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DistrictMapResponse {
  final double latitude;
  final double longitude;
  final String mapUrl;
  final String districtDays;
  final String districtsShift;
  final List<LatLng> polygonCoordinates;
  final Map<String, dynamic> geojson;
  final String specialPlace;

  DistrictMapResponse({
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
    required this.districtDays,
    required this.districtsShift,
    required this.polygonCoordinates,
    required this.geojson,
    required this.specialPlace,
  });

  factory DistrictMapResponse.fromJson(Map<String, dynamic> json) {
    // Parse polygon coordinates
    List<LatLng> coordinates = [];
    if (json['polygon_coordinates'] != null) {
      for (var coord in json['polygon_coordinates']) {
        coordinates.add(LatLng(coord['lat'], coord['lng']));
      }
    }

    return DistrictMapResponse(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      mapUrl: json['map_url'] ?? '',
      districtDays: json['district_days'] ?? '',
      districtsShift: json['districts_shift'] ?? '',
      polygonCoordinates: coordinates,
      geojson: json['geojson'] ?? {},
      specialPlace: json['special_place'] ?? '',
    );
  }
}

class City {
  final int cityId;
  final String cityName;

  City({required this.cityId, required this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['city_code'],
      cityName: json['city_name'],
    );
  }
}
class CitiesResponse {
  final List<City> cities;

  CitiesResponse({required this.cities});

  factory CitiesResponse.fromJson(List<dynamic> jsonList) {
    List<City> cities = jsonList.map((city) => City.fromJson(city)).toList();
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
  final List<LatLng>? boundaryCoordinates;

  const MapSelectorDialog({
    Key? key,
    required this.initialLocation,
    required this.onLocationSelected,
    this.boundaryCoordinates,
  }) : super(key: key);

  @override
  _MapSelectorDialogState createState() => _MapSelectorDialogState();
}

class _MapSelectorDialogState extends State<MapSelectorDialog> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _hasUserMovedMap = false;
  bool _isLocationConfirmed = false;
  bool _isGettingLocation = false;
  MapType _currentMapType = MapType.normal;
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    
    // Create boundary polygon if coordinates are provided
    if (widget.boundaryCoordinates != null && widget.boundaryCoordinates!.isNotEmpty) {
      _polygons.add(
        Polygon(
          polygonId: PolygonId('district_boundary'),
          points: widget.boundaryCoordinates!,
          strokeColor: Colors.red,
          strokeWidth: 4,
          fillColor: Colors.red.withOpacity(0.15),
        ),
      );
    }
  }
Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingLocation = true;
  });

  try {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission permanently denied. Please enable in settings.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isGettingLocation = false;
      });
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Move camera to current location
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }

    setState(() {
      _isGettingLocation = false;
    });
  } catch (e) {
    print('Error getting current location: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to get current location'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      _isGettingLocation = false;
    });
  }
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
              polygons: _polygons,
              buildingsEnabled: true,
              trafficEnabled: false,
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
                  SizedBox(height: 8),
                  // Current location button
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
                      icon: _isGettingLocation 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                              ),
                            )
                          : Icon(Icons.my_location, color: Colors.black54, size: 24),
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

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
                        onTap: () => _changeMapType(MapType.hybrid), // Changed from MapType.satellite
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _currentMapType == MapType.hybrid  // Changed condition
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
                              color: _currentMapType == MapType.hybrid  // Changed condition
                                  ? Colors.white 
                                  : Colors.black87,
                              fontSize: 14,
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
    bool _isLocationWithinBoundary(LatLng location) {
        if (widget.boundaryCoordinates == null || widget.boundaryCoordinates!.isEmpty) {
          return true; // If no boundary, allow any location
        }
        
        // Simple point-in-polygon algorithm
        List<LatLng> polygon = widget.boundaryCoordinates!;
        int intersectCount = 0;
        
        for (int i = 0; i < polygon.length; i++) {
          int next = (i + 1) % polygon.length;
          
          if (((polygon[i].latitude <= location.latitude && location.latitude < polygon[next].latitude) ||
              (polygon[next].latitude <= location.latitude && location.latitude < polygon[i].latitude)) &&
              (location.longitude < (polygon[next].longitude - polygon[i].longitude) * 
              (location.latitude - polygon[i].latitude) / 
              (polygon[next].latitude - polygon[i].latitude) + polygon[i].longitude)) {
            intersectCount++;
          }
        }
        
        return (intersectCount % 2) == 1;
      }
  void _onCameraIdle() {
    // This is called when the user stops moving the map
    // The _selectedLocation is already updated in _onCameraMove
    print('Camera idle at: ${_selectedLocation?.latitude}, ${_selectedLocation?.longitude}'); // Debug print
  }

  void _confirmLocationSelection() {
    if (_selectedLocation != null) {
      if (_isLocationWithinBoundary(_selectedLocation!)) {
        widget.onLocationSelected(_selectedLocation!);
        Navigator.of(context).pop();
      } else {
        // Show error message if location is outside boundary
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a location within the district boundary'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

DistrictMapResponse? _districtMapData;
bool _isLoadingDistrictMap = false;

// Add district-related variables
List<District> _availableDistricts = [];
bool _isLoadingDistricts = false;
int? _selectedDistrictId;


  @override
  void initState() {
    super.initState();
    _fetchCitiesFromAPI();
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

  List<String> get _cities {
  return _availableCities.map((city) => city.cityName).toList();
}

  List<String> get _districts {
  return _availableDistricts.map((district) => district.districtName).toList();
}

  LatLng? get _districtLocation {
  // Since we're using API data now, return a default location or use district map data
  if (_districtMapData != null) {
    return LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
  }
  return LatLng(24.6877, 46.7219); // Default Riyadh location
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
      
      // Fetch district map data when district is selected
      if (_selectedDistrictId != null && _selectedDistrictId! > 0) {
        _fetchDistrictMapData(_selectedDistrictId!);
      }
    } else {
      _selectedDistrictId = null;
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
  if (_selectedLocation == null || _selectedDistrictId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Missing required location or district information')),
    );
    return;
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
    String mapUrl = 'https://maps.google.com/?q=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
    
    // Parse building number and apartment number from notes or building number field
    int? floorNumber;
    int? apartmentNumber;
    int? buildingNumberInt;
    
    // Try to parse building number as integer
    if (_buildingNumberController.text.isNotEmpty) {
      buildingNumberInt = int.tryParse(_buildingNumberController.text);
    }
    
    // Extract floor and apartment from notes if available
    String notes = _notesController.text.toLowerCase();
    RegExp floorRegex = RegExp(r'floor\s*(\d+)|level\s*(\d+)|\bfl\s*(\d+)');
    RegExp aptRegex = RegExp(r'apartment\s*(\d+)|apt\s*(\d+)|unit\s*(\d+)');
    
    Match? floorMatch = floorRegex.firstMatch(notes);
    if (floorMatch != null) {
      floorNumber = int.tryParse(floorMatch.group(1) ?? floorMatch.group(2) ?? floorMatch.group(3) ?? '');
    }
    
    Match? aptMatch = aptRegex.firstMatch(notes);
    if (aptMatch != null) {
      apartmentNumber = int.tryParse(aptMatch.group(1) ?? aptMatch.group(2) ?? aptMatch.group(3) ?? '');
    }

    // Prepare request body
    Map<String, dynamic> requestBody = {
      'longitude': _selectedLocation!.longitude,
      'latitude': _selectedLocation!.latitude,
      'map_url': mapUrl,
      'customer_id': "428", // Fixed customer ID as per requirement
      'floor_number': floorNumber ?? 0,
      'apartment_number': apartmentNumber ?? 0,
      'created_by': 1, // You might want to make this dynamic based on current user
      'house_type': 1, // Default house type, you might want to add this as a dropdown
      'district_id': _selectedDistrictId!.toString(),
      'city_code': _selectedCityId?.toString() ?? '', 
      'building_number': buildingNumberInt ?? 0,
      'building_name': _addressTitleController.text.isNotEmpty ? _addressTitleController.text : '',
    };

    print('Sending POST request with body: ${json.encode(requestBody)}'); // Debug print

    final response = await http.post(
      Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/address?customer_id=428'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    // Hide loading indicator
    Navigator.of(context).pop();

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
        'buildingNumber': _buildingNumberController.text,
        'fullAddress': _fullAddressController.text,
        'notes': _notesController.text,
        'city': _selectedCity,
        'district': _selectedDistrict,
        'coordinates': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'api_response': json.decode(response.body), // Include API response
      };

      Navigator.pop(context, newAddress);
    } else {
      // Error
      print('API Error: ${response.statusCode} - ${response.body}'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create address. Please try again. (${response.statusCode})'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Hide loading indicator if still showing
    Navigator.of(context).pop();
    
    print('Exception creating address: $e'); // Debug print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error. Please check your connection and try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
Future<void> _fetchDistrictMapData(int districtId) async {
  setState(() {
    _isLoadingDistrictMap = true;
  });

  try {
    final response = await http.get(
      Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/address/districts/map?district_id=$districtId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final districtMapResponse = DistrictMapResponse.fromJson(json.decode(response.body));
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
      SnackBar(content: Text('Failed to load district map data. Please try again.')),
    );
  }
}

Future<void> _fetchCitiesFromAPI() async {
  setState(() {
    _isLoadingCities = true;
  });

  try {
    final response = await http.get(
      Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/service_cities/1'),
      headers: {'Content-Type': 'application/json'},
    );

if (response.statusCode == 200) {
  final decoded = json.decode(response.body) as List<dynamic>;
  final citiesResponse = CitiesResponse.fromJson(decoded);
  setState(() {
    _availableCities = citiesResponse.cities;
    _isLoadingCities = false;
  });
}
    
    
    else {
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

  LatLng initialLocation;
  
  // Use district map data if available, otherwise fallback to default
  if (_districtMapData != null) {
    initialLocation = LatLng(_districtMapData!.latitude, _districtMapData!.longitude);
  } else {
    initialLocation = _districtLocation ?? LatLng(24.6877, 46.7219);
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => MapSelectorDialog(
      initialLocation: initialLocation,
      boundaryCoordinates: _districtMapData?.polygonCoordinates, // Pass boundary coordinates
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
          '$_selectedDistrict, $_selectedCity, Saudi Arabia';
        if (place.street != null && place.street!.isNotEmpty) {
          _streetNameController.text = place.street!;
        }
      });
    }
  } catch (e) {
    // Fallback to basic address format
    setState(() {
      _fullAddressController.text = '$_selectedDistrict, $_selectedCity, Saudi Arabia';
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
  '$_selectedDistrict, $_selectedCity, Saudi Arabia';
          if (place.street != null && place.street!.isNotEmpty) {
            _streetNameController.text = place.street!;
          }
        });
      }
    } catch (e) {
      // Fallback to basic address format
      setState(() {
        _fullAddressController.text = '$_selectedDistrict, $_selectedCity Saudi Arabia';
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

  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select a location on the map')),
    );
    return;
  }

  if (_selectedDistrictId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select a district')),
    );
    return;
  }

  // Call the API to create the address
  _createAddressAPI();
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
    enabled: !_isLoadingCities // Remove dependency on _selectedProvince
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