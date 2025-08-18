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
import '../widgets/reusable_header_scaffold.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapSelectorDialog extends ConsumerStatefulWidget {
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

class _MapSelectorDialogState extends ConsumerState<MapSelectorDialog> {
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final loc = AppLocalizations.of(context)!;
          final currentLocale = ref.read(localeNotifierProvider);
          final isArabic = currentLocale.languageCode == 'ar';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.locationPermissionDenied, // Use localized string
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
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
        final loc = AppLocalizations.of(context)!;
        final currentLocale = ref.read(localeNotifierProvider);
        final isArabic = currentLocale.languageCode == 'ar';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.locationPermissionPermanentlyDenied, // Use localized string
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      final loc = AppLocalizations.of(context)!;
      final currentLocale = ref.read(localeNotifierProvider);
      final isArabic = currentLocale.languageCode == 'ar';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.failedToGetLocation, // Use localized string
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
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
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              // Header with RTL support
              Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Color(0xFF10295C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      GestureDetector(
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
                      Expanded(
                        child: Text(
                          loc.selectLocation, // Use localized string
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFA200),
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              
              // Map content with RTL adjustments
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // GoogleMap remains the same
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
                        // Center pin remains the same
                        Center(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Custom zoom controls with RTL positioning
                        Positioned(
                          top: 20,
                          left: isArabic ? 20 : null,
                          right: isArabic ? null : 20,
                          child: Column(
                            children: [
                              // Zoom controls remain the same structure
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
                        // Map type selector with RTL support
                        Positioned(
                          bottom: 100,
                          left: 20,
                          right: 20,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                children: [
                                  // MAP button
                                  GestureDetector(
                                    onTap: () => _changeMapType(MapType.normal),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _currentMapType == MapType.normal 
                                            ? Color(0xFF1E3A8A) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.only(
                                          topLeft: isArabic ? Radius.zero : Radius.circular(8),
                                          bottomLeft: isArabic ? Radius.zero : Radius.circular(8),
                                          topRight: isArabic ? Radius.circular(8) : Radius.zero,
                                          bottomRight: isArabic ? Radius.circular(8) : Radius.zero,
                                        ),
                                      ),
                                      child: Text(
                                        loc.map, // Use localized string
                                        style: TextStyle(
                                          color: _currentMapType == MapType.normal 
                                              ? Colors.white 
                                              : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // SATELLITE button
                                  GestureDetector(
                                    onTap: () => _changeMapType(MapType.hybrid),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _currentMapType == MapType.hybrid
                                            ? Color(0xFF1E3A8A) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.only(
                                          topRight: isArabic ? Radius.zero : Radius.circular(8),
                                          bottomRight: isArabic ? Radius.zero : Radius.circular(8),
                                          topLeft: isArabic ? Radius.circular(8) : Radius.zero,
                                          bottomLeft: isArabic ? Radius.circular(8) : Radius.zero,
                                        ),
                                      ),
                                      child: Text(
                                        loc.satellite, // Use localized string
                                        style: TextStyle(
                                          color: _currentMapType == MapType.hybrid
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
                        // Bottom button with RTL support
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: _buildMapActionButton(loc, isArabic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton(AppLocalizations loc, bool isArabic) {
    if (!_hasUserMovedMap) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            loc.moveMapToPosition, // Use localized string
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: _confirmLocationSelection,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              loc.confirmLocation, // Use localized string
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
    print('Camera idle at: ${_selectedLocation?.latitude}, ${_selectedLocation?.longitude}');
  }

  void _confirmLocationSelection() {
    if (_selectedLocation != null) {
      if (_isLocationWithinBoundary(_selectedLocation!)) {
        widget.onLocationSelected(_selectedLocation!);
        Navigator.of(context).pop();
      } else {
        final loc = AppLocalizations.of(context)!;
        final currentLocale = ref.read(localeNotifierProvider);
        final isArabic = currentLocale.languageCode == 'ar';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.selectLocationWithinBoundary, // Use localized string
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
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
    print('Proceeding to details with location: $_selectedLocation');
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      Navigator.of(context).pop();
    }
  }
}