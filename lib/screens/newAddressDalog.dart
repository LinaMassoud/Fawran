import 'package:flutter/material.dart';

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

