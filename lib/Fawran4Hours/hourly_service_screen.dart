//cleaning_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../services/api_service.dart';
import 'continuous_booking_overlay.dart';
import 'order_summary_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Service {
  final int id;
  final String name;

  Service({required this.id, required this.name});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
    );
  }
}

class HourlyServiceScreen extends StatefulWidget {
  final PackageModel? autoOpenPackage;
  final int? autoOpenShift;
  final String serviceType; // Keep this parameter but make it dynamic
  final String serviceCode;
  final int serviceId;
  final int professionId;

  const HourlyServiceScreen({
    Key? key,
    this.autoOpenPackage,
    this.autoOpenShift,
    this.serviceType = '', // Remove default, will be set dynamically
    this.serviceCode = '',
    this.serviceId = 1,
    this.professionId = 7,
  }) : super(key: key);

  @override
  _HourlyServiceScreenState createState() => _HourlyServiceScreenState();
}

class _HourlyServiceScreenState extends State<HourlyServiceScreen> {
  // Global keys for navigation to specific sections
  final _storage = FlutterSecureStorage();
  // Package lists for different groups and shifts
  // Shift selection state

  // Booking state management
  BookingData? completedBooking;
  double totalSavings = 375.0; // This can be calculated based on discounts
  double originalPrice = 1497.0; // This can be calculated from package prices

  String dynamicServiceTitle = '';
  List<String> servicePackTitles = [];
  bool isLoadingPackTitles = true;

  List<Service> availableServices = [];
  int? selectedServiceId;
  String selectedServiceName = '';
  bool isLoadingServices = true;
// NEW: Dynamic data from API
  List<dynamic> availableShifts = [];
  bool isLoadingShifts = true;
  bool isLoadingGroups = true;

  Map<String, List<PackageModel>> packagesByGroup = {};
  Map<String, bool> loadingStatesByGroup = {};
  Map<String, String?> errorMessagesByGroup = {};
  Map<String, List<PackageModel>> filteredPackagesByGroup = {};
  Map<String, int> selectedShiftsByGroup = {};
  List<dynamic> countryGroups = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> fetchServices() async {
  try {
    setState(() => isLoadingServices = true);

    final List<dynamic> servicesList = await ApiService.fetchServices(
      professionId: widget.professionId,
    );

    setState(() {
      availableServices = servicesList.map((service) => Service.fromJson(service)).toList();
      
      // Always ensure a service is selected
      if (availableServices.isNotEmpty) {
        // If serviceId is provided, try to find it; otherwise use first available
        if (widget.serviceId != null) {
          final matchingService = availableServices.firstWhere(
            (service) => service.id == widget.serviceId,
            orElse: () => availableServices.first,
          );
          selectedServiceId = matchingService.id;
          selectedServiceName = matchingService.name;
        } else {
          // No serviceId provided, use first available service
          selectedServiceId = availableServices.first.id;
          selectedServiceName = availableServices.first.name;
        }
        
        _setServiceTitle();
      }
      
      isLoadingServices = false;
    });
  } catch (e) {
    setState(() {
      isLoadingServices = false;
      
      // If API fails, create fallback services only as last resort
      if (availableServices.isEmpty) {
        availableServices = [
          Service(
            id: widget.serviceId ?? 1, // Use provided serviceId or default to 1
            name: widget.serviceType.isNotEmpty ? widget.serviceType : 'FAWRAN Service'
          ),
        ];
        
        selectedServiceId = widget.serviceId ?? 1;
        selectedServiceName = availableServices.first.name;
        _setServiceTitle();
      }
    });
    print('Error fetching services: $e');
  }
}
  Future<void> _initializeData() async {
  _setServiceTitle();
  await fetchServices();
  
  await Future.wait([
    _loadServiceShifts(),
    _loadCountryGroups(),
    _loadServicePackTitles(),
  ]);

  // Fetch packages for all groups dynamically
  for (var group in countryGroups) {
    final groupCode = group['group_code'].toString();
    fetchPackagesForGroup(groupCode);
  }

  _checkAndShowAutoOverlay();
}


Future<void> fetchPackagesForGroup(String groupCode) async {
  try {
    print('Fetching packages for group $groupCode with professionId: ${widget.professionId}, serviceId: ${selectedServiceId ?? widget.serviceId}');

    setState(() {
      loadingStatesByGroup[groupCode] = true;
      errorMessagesByGroup[groupCode] = null;
    });

    final packages = await ApiService.fetchPackagesByGroup(
      professionId: widget.professionId,
      serviceId: selectedServiceId ?? widget.serviceId,
      groupCode: groupCode,
      // Always pass the shift parameter for all services
      serviceShift: selectedShiftsByGroup[groupCode],
    );

    setState(() {
      packagesByGroup[groupCode] = packages;
      filteredPackagesByGroup[groupCode] = packages;
      loadingStatesByGroup[groupCode] = false;
    });
  } catch (e) {
    print('Error fetching packages for group $groupCode: $e');
    setState(() {
      errorMessagesByGroup[groupCode] = e.toString();
      loadingStatesByGroup[groupCode] = false;
    });
  }
}

  void _setServiceTitle() {
  if (selectedServiceId != null && availableServices.isNotEmpty) {
    final selectedService = availableServices.firstWhere(
      (service) => service.id == selectedServiceId,
      orElse: () => availableServices.first,
    );
    setState(() {
      dynamicServiceTitle = selectedService.name;
    });
  } else {
    // Fallback logic when no services available
    String fallbackTitle;
    if (widget.serviceId != null) {
      switch (widget.serviceId) {
        case 1:
          fallbackTitle = 'FAWRAN 4 Hours';
          break;
        case 21:
          fallbackTitle = 'FAWRAN 8 Hours';
          break;
        case 62:
          fallbackTitle = 'MaintenanceService';
          break;
        default:
          fallbackTitle = widget.serviceType.isNotEmpty
              ? widget.serviceType
              : 'Service';
      }
    } else {
      fallbackTitle = widget.serviceType.isNotEmpty
          ? widget.serviceType
          : 'Service';
    }
    
    setState(() {
      dynamicServiceTitle = fallbackTitle;
    });
    
    if (selectedServiceId == null) {
      selectedServiceId = widget.serviceId ?? 1;
    }
  }
}

// 5. ADD NEW METHOD TO LOAD SERVICE PACK TITLES
  Future<void> _loadServicePackTitles() async {
    try {
      setState(() => isLoadingPackTitles = true);

      final groups =
          await ApiService.fetchCountryGroups(serviceId: widget.serviceId);

      setState(() {
        servicePackTitles = groups
            .map<String>((group) => group['group_name'].toString())
            .toList();
        isLoadingPackTitles = false;
      });
    } catch (e) {
      setState(() {
        // Fallback to default titles if API fails
        servicePackTitles = ['East Asia Pack', 'African Pack'];
        isLoadingPackTitles = false;
      });
      print('Error loading service pack titles: $e');
    }
  }

  Future<void> _loadServiceShifts() async {
    try {
      setState(() => isLoadingShifts = true);

      final shifts = await ApiService.fetchServiceShifts(
          serviceId: selectedServiceId ?? widget.serviceId);

      setState(() {
        availableShifts = shifts;
        isLoadingShifts = false;

        // Set default shift to first available shift for all groups
        if (shifts.isNotEmpty) {
          for (var group in countryGroups) {
            final groupCode = group['group_code'].toString();
            selectedShiftsByGroup[groupCode] = shifts.first['id'];
          }
        }
      });
    } catch (e) {
      setState(() => isLoadingShifts = false);
      print('Error loading service shifts: $e');
    }
  }

  // NEW: Load country groups dynamically
  Future<void> _loadCountryGroups() async {
  try {
    setState(() => isLoadingGroups = true);

    final groups = await ApiService.fetchCountryGroups(serviceId: widget.serviceId);

    setState(() {
      countryGroups = groups;
      isLoadingGroups = false;

      // Initialize dynamic data structures for each group
      for (var group in groups) {
        final groupCode = group['group_code'].toString();
        final groupName = group['group_name'].toString();
        
        // Initialize package lists and states
        packagesByGroup[groupCode] = [];
        loadingStatesByGroup[groupCode] = true;
        errorMessagesByGroup[groupCode] = null;
        filteredPackagesByGroup[groupCode] = [];
        selectedShiftsByGroup[groupCode] = 1; // Default shift
      }
    });
  } catch (e) {
    setState(() => isLoadingGroups = false);
    print('Error loading country groups: $e');
  }
}

  void _checkAndShowAutoOverlay() {
    if (widget.autoOpenPackage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ContinuousBookingOverlay.showAsOverlay(
          context,
          package: widget.autoOpenPackage!,
          selectedShift: widget.autoOpenShift ?? 1,
          serviceId: selectedServiceId ?? widget.serviceId,
          professionId: widget.professionId,
          onBookingCompleted: _onBookingCompleted,
        );
      });
    }
  }

  void _onServiceChanged(int serviceId) {
  final selectedService = availableServices.firstWhere(
    (service) => service.id == serviceId,
    orElse: () => availableServices.isNotEmpty ? availableServices.first : Service(id: widget.serviceId, name: widget.serviceType),
  );

  setState(() {
    selectedServiceId = serviceId;
    selectedServiceName = selectedService.name;
    _setServiceTitle();
  });
  
  _loadServiceShifts().then((_) {
    setState(() {
      // Reset shift selections for all groups
      for (var group in countryGroups) {
        final groupCode = group['group_code'].toString();
        selectedShiftsByGroup[groupCode] = availableShifts.isNotEmpty ? availableShifts.first['id'] : 1;
      }
    });
    
    // Fetch packages for all groups
    for (var group in countryGroups) {
      final groupCode = group['group_code'].toString();
      fetchPackagesForGroup(groupCode);
    }
  });
}

void _onShiftChangedForGroup(String groupCode, int shift) {
  setState(() {
    selectedShiftsByGroup[groupCode] = shift;
  });
  fetchPackagesForGroup(groupCode);
}

  void _onPaymentSuccess() {
    setState(() {
      completedBooking = null; // This will hide the bottom order view
    });
  }

  // Handle booking completion
  void _onBookingCompleted(BookingData bookingData) {
    setState(() {
      completedBooking = bookingData;
      // Calculate original price and savings based on the booking
      originalPrice = bookingData.totalPrice + totalSavings;
    });
  }

  // Handle view order button
  void _viewOrder() {
    if (completedBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSummaryScreen(
            bookingData: completedBooking!,
            totalSavings: totalSavings,
            originalPrice: originalPrice,
            onPaymentSuccess: _onPaymentSuccess, // Add this callback
            customBooking: false,
          ),
        ),
      );
    }
  }

Widget _buildServiceSelector(AppLocalizations loc) {
  // Show loading while fetching services
  if (isLoadingServices) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.selectService,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Color(0xFF091735),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Show service selector if services are available
  if (availableServices.isNotEmpty) {
    // Ensure selectedServiceId is set
    if (selectedServiceId == null) {
      selectedServiceId = availableServices.first.id;
      selectedServiceName = availableServices.first.name;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setServiceTitle());
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.selectService,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF091735),
            ),
          ),
          SizedBox(height: 10),

          // HORIZONTAL ROW FOR RADIO BUTTONS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableServices
                  .map(
                    (service) => Container(
                      child: GestureDetector(
                        onTap: () => _onServiceChanged(service.id),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<int>(
                              value: service.id,
                              groupValue: selectedServiceId ?? service.id,
                              onChanged: (int? value) {
                                if (value != null) {
                                  _onServiceChanged(value);
                                }
                              },
                              activeColor: Color(0xFF1E49A0),
                            ),
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                color: Color(0xFF768090),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          

          SizedBox(height: 5),
        ],
      ),
    );
  }

  // No services available - show error state with retry
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 1, vertical: 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.selectService,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                'No services available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Spacer(),
              TextButton(
                onPressed: fetchServices,
                child: Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: Color(0xFF10295C)),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
      ],
    ),
  );
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Fetch fresh services when screen becomes active
  if (ModalRoute.of(context)?.isCurrent == true && availableServices.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchServices();
    });
  }
}

 @override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return Scaffold(
    backgroundColor: Colors.grey[100],
    body: Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Sticky Header with overlap
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
                    size: 22,
                  ),
                ),
              ),
              title: Text(
                loc.hourlyServices,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Color(0xFFFFA200),
                ),
              ),
              centerTitle: true,
              elevation: 0,
              // Add floating behavior for overlap effect
              floating: false,
              snap: false,
            ),
            
            // Add negative margin to create overlap
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: Offset(0, -40), // Negative offset to create overlap
                child: Column(
                  children: [
                    // Header Section with Video/Image
                    Container(
                      height: 300,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24), // Add top border radius
                                topRight: Radius.circular(24),
                              ),
                              child: Image.asset(
                                'assets/images/cleaning_hero1.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[300]!,
                                          Colors.grey[500]!,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.cleaning_services,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 40,
                            child: Text(
                              'Scrub Away\ntough Stains',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main content with consistent padding
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service selector (only shows when multiple services)
                          _buildServiceSelector(loc),

                          // Divider line
                          Container(
                            width: double.infinity,
                            height: 2,
                            color: Colors.grey[300],
                            margin: EdgeInsets.symmetric(vertical: 10),
                          ),

                          // Service title - only show if professionId is not 61
                          if (widget.serviceId != 62)
                            Text(
                              dynamicServiceTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF091735),
                              ),
                            ),
                          if (widget.serviceId != 62)
                            SizedBox(height: 16),
                          SizedBox(height: 1),

                          // Design your card button - only show if professionId is not 61
                          if (widget.serviceId != 62) ...[
                            _buildDesignCardButton(loc),
                            SizedBox(height: 22),
                          ] else
                            SizedBox(height: 16),

                          // Dynamic package sections
                          ...countryGroups.map((group) {
                            final groupCode = group['group_code'].toString();
                            final groupName = group['group_name'].toString();
                            
                            return Column(
                              children: [
                                _buildPackageSection(
                                  sectionTitle: groupName,
                                  packages: packagesByGroup[groupCode] ?? [],
                                  filteredPackages: filteredPackagesByGroup[groupCode] ?? [],
                                  isLoading: loadingStatesByGroup[groupCode] ?? false,
                                  errorMessage: errorMessagesByGroup[groupCode],
                                  onRetry: () => fetchPackagesForGroup(groupCode),
                                  groupCode: groupCode,
                                  loc: loc,
                                ),
                                SizedBox(height: 40),
                              ],
                            );
                          }).toList(),
                          SizedBox(height: completedBooking != null ? 120 : 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom Order View - Show when booking is completed
        if (completedBooking != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Congratulations banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.green,
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${loc.congratulations} SAR${completedBooking!.discountAmount.toStringAsFixed(1)} ${loc.saved} ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price and View Order section
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'SAR ${completedBooking!.totalPrice}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF091735),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'SAR ${completedBooking!.originalPrice}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF768090),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _viewOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10295C),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            loc.viewOrder,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      ],
    ),
  );
}


void _showPackageDetailsOverlay(PackageModel package, AppLocalizations loc) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 60), // Reduced horizontal margin for more width
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.packageDetails,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // Package image with discount badge - Made smaller
              Container(
                height: 140, // Reduced from 200 to 140
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/cleaning_service_card.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.brown[100],
                              child: Center(
                                child: Icon(
                                  Icons.cleaning_services,
                                  size: 50, // Reduced from 60 to 50
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${loc.get} ${package.discountPercentage}% ${loc.off}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Package details
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Package name
                    Text(
                      package.packageName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Package details grid
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(loc.noOfEmployee, package.noOfEmployee.toString()),
                          SizedBox(height: 8),
                          _buildDetailRow(loc.duration, '${package.duration} ${loc.hours}'),
                          SizedBox(height: 8),
                          _buildDetailRow(loc.weeklyVisits, '${package.visitsWeekly}'),
                          SizedBox(height: 8),
                          _buildDetailRow(loc.contractDuration, '${package.noOfWeeks.toString()} ${loc.weeks}'),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Price section - outside of grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${loc.totalPrice}:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'SAR ${package.finalPrice.round()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SAR ${package.packagePrice.round()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close overlay first
                          ContinuousBookingOverlay.showAsOverlay(
                            context,
                            package: package,
                            selectedShift: selectedShiftsByGroup.values.isNotEmpty ? selectedShiftsByGroup.values.first : 1,
                            serviceId: selectedServiceId ?? widget.serviceId,
                            professionId: widget.professionId,
                            onBookingCompleted: _onBookingCompleted,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10295C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          loc.add,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
      );
    },
  );
}

// Helper method for detail rows - improved alignment
Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label + ':',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
  Widget _buildShiftSelector(String groupCode) {
  if (isLoadingShifts || availableShifts.isEmpty) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16), // Reduced from 25 to 12
      ),
      child: Center(
        child: isLoadingShifts
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'No shifts available',
                style: TextStyle(color: Colors.grey[600]),
              ),
      ),
    );
  }

  // Helper function to check if text contains Arabic characters
  bool _isArabicText(String text) {
    return text.runes.any((rune) => rune >= 0x0600 && rune <= 0x06FF);
  }

  // Helper function to get delivery time based on shift name (supports Arabic)
  String _getDeliveryTime(String shiftName) {
    final lowerShiftName = shiftName.toLowerCase();
    
    // Check English shift names
    if (lowerShiftName.contains('morning')) {
      return '7:30-10:00 AM';
    } else if (lowerShiftName.contains('evening')) {
      return '3:30-6:00 PM';
    } else if (lowerShiftName.contains('full day') || lowerShiftName.contains('fullday')) {
      return '7:30 AM-10:00 PM';
    }
    
    // Check Arabic shift names
    if (lowerShiftName.contains('صباح') || lowerShiftName.contains('الصباح')) {
      return '7:30-10:00 صباحاً';
    } else if (lowerShiftName.contains('مسائي') || lowerShiftName.contains('مساني') || 
               lowerShiftName.contains('مساء') || lowerShiftName.contains('المساء')) {
      return '3:30-6:00 مساءً';
    } else if (lowerShiftName.contains('يوم كامل') || lowerShiftName.contains('كامل')) {
      return '7:30 صباحاً-10:00 مساءً';
    }
    
    return '';
  }

  // If only one shift available, show it as a static display
  if (availableShifts.length == 1) {
    final shift = availableShifts.first;
    final shiftName = shift['service_shifts'];
    final deliveryTime = _getDeliveryTime(shiftName);
    final isArabic = _isArabicText(shiftName);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Reduced from 25 to 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getShiftIcon(shiftName, true), // Updated to use the new method
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  shiftName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                    color: Color(0xFF091735),
                  ),
                  textAlign: TextAlign.center,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
            ],
          ),
          if (deliveryTime.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              deliveryTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textDirection: _isArabicText(deliveryTime) ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }

  // Multiple shifts available - show selector
  int selectedShift = selectedShiftsByGroup[groupCode] ?? 1;
  Function(int) onShiftChanged = (int shift) => _onShiftChangedForGroup(groupCode, shift);
  
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(16), // Reduced from 25 to 12
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
    ),
    child: Row(
      children: availableShifts.map<Widget>((shift) {
        final shiftId = shift['id'];
        final shiftName = shift['service_shifts'];
        final isSelected = selectedShift == shiftId;
        final deliveryTime = _getDeliveryTime(shiftName);
        final isArabic = _isArabicText(shiftName);

        return Expanded(
          child: GestureDetector(
            onTap: () => onShiftChanged(shiftId),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16), // Reduced from 25 to 12
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getShiftIcon(shiftName, isSelected), // Updated to use the new method
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          shiftName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (deliveryTime.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      deliveryTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.grey[700] : Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: _isArabicText(deliveryTime) ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
Widget _getShiftIcon(String shiftName, bool isSelected) {
  final lowerShiftName = shiftName.toLowerCase();
  final iconColor = _getShiftIconColor(shiftName, isSelected);
  
  // Check for morning shifts (English and Arabic)
  if (lowerShiftName.contains('morning') || 
      lowerShiftName.contains('صباح') || 
      lowerShiftName.contains('الصباح')) {
    return SvgPicture.asset(
      'assets/icons/sun.svg', // Replace with your actual SVG path
      width: 20,
      height: 20,
      color: iconColor,
    );
  }
  
  // Check for evening shifts (English and Arabic)
  if (lowerShiftName.contains('evening') || 
      lowerShiftName.contains('مسائي') || 
      lowerShiftName.contains('مساني') ||
      lowerShiftName.contains('مساء') || 
      lowerShiftName.contains('المساء')) {
    return SvgPicture.asset(
      'assets/icons/moon.svg', // Replace with your actual SVG path
      width: 20,
      height: 20,
      color: iconColor,
    );
  }
  
  // Check for full day shifts (English and Arabic) - Keep Icons.access_time
  if (lowerShiftName.contains('full day') || 
      lowerShiftName.contains('fullday') ||
      lowerShiftName.contains('يوم كامل') || 
      lowerShiftName.contains('كامل')) {
    return Icon(
      Icons.access_time,
      color: iconColor,
      size: 20,
    );
  }
  
  // Default icon
  return Icon(
    Icons.access_time,
    color: iconColor,
    size: 20,
  );
}
Color _getShiftIconColor(String shiftName, bool isSelected) {
  if (!isSelected) return Colors.grey;
  
  final lowerShiftName = shiftName.toLowerCase();
  
  // Morning shifts - orange
  if (lowerShiftName.contains('morning') || 
      lowerShiftName.contains('صباح') || 
      lowerShiftName.contains('الصباح')) {
    return Colors.orange;
  }
  
  // Evening shifts - indigo
  if (lowerShiftName.contains('evening') || 
      lowerShiftName.contains('مسائي') || 
      lowerShiftName.contains('مساني') ||
      lowerShiftName.contains('مساء') || 
      lowerShiftName.contains('المساء')) {
    return Colors.indigo;
  }
  
  // Full day shifts - blue
  if (lowerShiftName.contains('full day') || 
      lowerShiftName.contains('fullday') ||
      lowerShiftName.contains('يوم كامل') || 
      lowerShiftName.contains('كامل')) {
    return Colors.blue;
  }
  
  // Default color
  return Colors.grey[700]!;
}

  Widget _buildServicePack(String title, String imagePath, Color color) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.flag,
                    color: color,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePackWithIcon(String title, IconData icon, Color color) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSection({
  required String sectionTitle,
  required List<PackageModel> packages,
  required List<PackageModel> filteredPackages,
  required bool isLoading,
  required String? errorMessage,
  required VoidCallback onRetry,
  required String groupCode,
  required AppLocalizations loc,
}) {
  return Container(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show section title if not loading and no error
        if (!isLoading && errorMessage == null)
          Text(
            sectionTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF091735),
            ),
          ),

        // Always show shift selector if not loading and no error (regardless of filteredPackages)
        if (!isLoading && errorMessage == null)
          Column(
            children: [
              SizedBox(height: 16),
              _buildShiftSelector(groupCode),
              SizedBox(height: 20),
            ],
          ),

        // Show loading, error, or packages
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else if (filteredPackages.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            child: Text(
              'No ${sectionTitle.toLowerCase()} packages available for selected shift',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else if (filteredPackages.isNotEmpty)
          // HORIZONTAL SCROLLING CONTAINER
          Container(
            height: 320, // Fixed height for horizontal scroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4),
              itemCount: filteredPackages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280, // Fixed width for each card
                  margin: EdgeInsets.only(right: 16),
                  child: _buildCompactServiceCard(filteredPackages[index], loc),
                );
              },
            ),
          ),
      ],
    ),
  );
}

  Widget _buildDesignCardButton(AppLocalizations loc) {
  return GestureDetector(
    onTap: () {
      // Show custom booking overlay when tapped
      ContinuousBookingOverlay.showAsCustomOverlay(
        context,
        serviceId: selectedServiceId ??
            widget
                .serviceId, // Use selectedServiceId instead of widget.serviceId
        professionId: widget.professionId,
        onBookingCompleted: (BookingData bookingData) {
          // For custom bookings, navigate directly to OrderSummaryScreen
          // instead of showing the bottom order view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSummaryScreen(
                bookingData: bookingData,
                totalSavings: bookingData
                    .discountAmount, // Use the actual discount from booking
                originalPrice: bookingData.originalPrice,
                onPaymentSuccess:
                    _onPaymentSuccess, // Use the original price from booking
                customBooking: true,
              ),
            ),
          );
        },
      );
    },
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Reduced vertical padding
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Added horizontal margin
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30), // More rounded corners like in image
        border: Border.all(
          color: Color(0xFF1E49A0), // --Second-blue color
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the content
        children: [
          Icon(
            Icons.add,
            color: Color(0xFF1E49A0), // --Second-blue color
            size: 27,
          ),
          SizedBox(width: 8),
          Text(
            loc.designYourCard,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600, // Slightly bolder
              color: Color(0xFF1E49A0), // --Second-blue color
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCompactServiceCard(PackageModel package, AppLocalizations loc) {
  return GestureDetector(
    onTap: () => _showPackageDetailsOverlay(package, loc), // Add this line
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact service image with discount badge
          Container(
            height: 120, // Reduced height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      'assets/images/cleaning_service_card.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.brown[100],
                          child: Center(
                            child: Icon(
                              Icons.cleaning_services,
                              size: 40,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${loc.get} ${package.discountPercentage}% ${loc.off}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Compact service details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package name - truncated with Poppins font
                  Text(
                    package.packageName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Visit details
                  Text(
                    '${package.visitsWeekly} ${loc.weeklyVisits}: ${package.duration} ${loc.hours}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),

                  // Price row with bolder text
                  Row(
                    children: [
                      Text(
                        'SAR ${package.finalPrice}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800, // Made more bold
                          color: Color(0xFFF2582A),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SAR ${package.packagePrice}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w700, // Made more bold
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Add button - wrapped with GestureDetector to prevent parent tap
                  GestureDetector(
                    onTap: () {}, // Empty onTap to prevent parent tap
                    child: SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          ContinuousBookingOverlay.showAsOverlay(
                            context,
                            package: package,
                            selectedShift: selectedShiftsByGroup.values.isNotEmpty ? selectedShiftsByGroup.values.first : 1,
                            serviceId: selectedServiceId ?? widget.serviceId,
                            professionId: widget.professionId,
                            onBookingCompleted: _onBookingCompleted,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10295C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          loc.add,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  void dispose() {
    super.dispose();
  }
}