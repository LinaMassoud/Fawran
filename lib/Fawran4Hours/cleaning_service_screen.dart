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

class CleaningServiceScreen extends StatefulWidget {
  final PackageModel? autoOpenPackage;
  final int? autoOpenShift;
  final String serviceType; // Keep this parameter but make it dynamic
  final String serviceCode;
  final int serviceId;
  final int professionId;

  const CleaningServiceScreen({
    Key? key,
    this.autoOpenPackage,
    this.autoOpenShift,
    this.serviceType = '', // Remove default, will be set dynamically
    this.serviceCode = '',
    this.serviceId = 1,
    this.professionId = 7,
  }) : super(key: key);

  @override
  _CleaningServiceScreenState createState() => _CleaningServiceScreenState();
}

class _CleaningServiceScreenState extends State<CleaningServiceScreen> {
  // Global keys for navigation to specific sections
  final GlobalKey eastAsiaKey = const GlobalObjectKey("eastAsia");
  final GlobalKey africanKey = const GlobalObjectKey("african");
  final GlobalKey searchResultsKey = const GlobalObjectKey("searchResults");
  final GlobalKey eastAsiaSearchKey = const GlobalObjectKey("eastAsiaSearch");
  final GlobalKey africanSearchKey = const GlobalObjectKey("africanSearch");
  final _storage = FlutterSecureStorage();
  // Package lists for different groups and shifts
  List<PackageModel> eastAsiaPackages = [];
  List<PackageModel> africanPackages = [];

  

  bool isEastAsiaLoading = true;
  bool isAfricanLoading = true;
  String? eastAsiaErrorMessage;
  String? africanErrorMessage;

  bool isSearchActive = false;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  List<PackageModel> filteredEastAsiaPackages = [];
  List<PackageModel> filteredAfricanPackages = [];
  // Shift selection state
  int selectedEastAsiaShift = 1; // 1 = Morning, 2 = Evening
  int selectedAfricanShift = 1; // 1 = Morning, 2 = Evening

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
  List<dynamic> countryGroups = [];
  bool isLoadingShifts = true;
  bool isLoadingGroups = true;
  String eastAsiaGroupName = 'East Asia';
  String africanGroupName = 'African Pack';

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
        final matchingService = availableServices.firstWhere(
          (service) => service.id == widget.serviceId,
          orElse: () => availableServices.first,
        );
        
        selectedServiceId = matchingService.id;
        selectedServiceName = matchingService.name;
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
          Service(id: widget.serviceId, name: widget.serviceType.isNotEmpty ? widget.serviceType : 'FAWRAN Service'),
        ];
        
        selectedServiceId = widget.serviceId;
        selectedServiceName = availableServices.first.name;
        _setServiceTitle();
      }
    });
    print('Error fetching services: $e');
  }
}

Future<void> reloadServices() async {
  try {
    setState(() => isLoadingServices = true);
    
    final List<dynamic> servicesList = await ApiService.fetchServices(
      professionId: widget.professionId,
    );

    setState(() {
      availableServices = servicesList.map((service) => Service.fromJson(service)).toList();
      
      // Try to maintain current selection if it exists in new data
      if (availableServices.isNotEmpty) {
        final currentSelection = availableServices.firstWhere(
          (service) => service.id == selectedServiceId,
          orElse: () => availableServices.first,
        );
        
        selectedServiceId = currentSelection.id;
        selectedServiceName = currentSelection.name;
        _setServiceTitle();
      }
      
      isLoadingServices = false;
    });
    
    // Reload related data after services are updated
    await _loadServiceShifts();
    fetchEastAsiaPackages();
    fetchAfricanPackages();
    
  } catch (e) {
    setState(() {
      isLoadingServices = false;
    });
    print('Error reloading services: $e');
  }
}

  Future<void> _initializeData() async {
  // Set dynamic service title based on serviceId
  _setServiceTitle();

  // CHANGED: Load services FIRST before other operations
  await fetchServices();
  
  // Then load other data in parallel
  await Future.wait([
    _loadServiceShifts(),
    _loadCountryGroups(),
    _loadServicePackTitles(),
  ]);

  // After loading shifts and groups, fetch packages
  fetchEastAsiaPackages();
  fetchAfricanPackages();

  filteredEastAsiaPackages = eastAsiaPackages;
  filteredAfricanPackages = africanPackages;

  _checkAndShowAutoOverlay();
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
    switch (widget.serviceId) {
      case 1:
        fallbackTitle = 'FAWRAN 4 Hours';
        break;
      case 21:
        fallbackTitle = 'FAWRAN 8 Hours';
        break;
      default:
        fallbackTitle = widget.serviceType.isNotEmpty
            ? widget.serviceType
            : 'Fawran Service';
    }
    
    setState(() {
      dynamicServiceTitle = fallbackTitle;
    });
    
    if (selectedServiceId == null) {
      selectedServiceId = widget.serviceId;
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

        // Set default shift to first available shift
        if (shifts.isNotEmpty) {
          selectedEastAsiaShift = shifts.first['id'];
          selectedAfricanShift = shifts.first['id'];
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

      final groups =
          await ApiService.fetchCountryGroups(serviceId: widget.serviceId);

      setState(() {
        countryGroups = groups;
        isLoadingGroups = false;

        // Update group names based on API response
        for (var group in groups) {
          if (group['group_name'].toString().toUpperCase().contains('ASIA')) {
            eastAsiaGroupName = group['group_name'];
          } else if (group['group_name']
              .toString()
              .toUpperCase()
              .contains('AFRICAN')) {
            africanGroupName = group['group_name'];
          }
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

  void _filterPackages(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      if (query.isEmpty) {
        filteredEastAsiaPackages = eastAsiaPackages;
        filteredAfricanPackages = africanPackages;
      } else {
        filteredEastAsiaPackages = eastAsiaPackages.where((package) {
          return package.packageName.toLowerCase().contains(searchQuery) ||
              package.nationalityDisplay.toLowerCase().contains(searchQuery) ||
              package.timeDisplay.toLowerCase().contains(searchQuery) ||
              package.durationDisplay.toLowerCase().contains(searchQuery) ||
              package.visitsWeekly.toString().contains(searchQuery) ||
              'cleaning'.contains(searchQuery) ||
              'visit'.contains(searchQuery) ||
              'hours'.contains(searchQuery);
        }).toList();

        filteredAfricanPackages = africanPackages.where((package) {
          return package.packageName.toLowerCase().contains(searchQuery) ||
              package.nationalityDisplay.toLowerCase().contains(searchQuery) ||
              package.timeDisplay.toLowerCase().contains(searchQuery) ||
              package.durationDisplay.toLowerCase().contains(searchQuery) ||
              package.visitsWeekly.toString().contains(searchQuery) ||
              'cleaning'.contains(searchQuery) ||
              'visit'.contains(searchQuery) ||
              'hours'.contains(searchQuery);
        }).toList();

        // Auto-scroll to search results after filtering
        if (filteredEastAsiaPackages.isNotEmpty ||
            filteredAfricanPackages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSearchResults();
          });
        }
      }
    });
  }

  void _scrollToSearchResults() {
    GlobalKey? targetKey;

    // Determine which section to scroll to based on search results
    if (filteredEastAsiaPackages.isNotEmpty &&
        filteredAfricanPackages.isNotEmpty) {
      // Both have results, scroll to East Asia first
      targetKey = eastAsiaSearchKey;
    } else if (filteredEastAsiaPackages.isNotEmpty) {
      // Only East Asia has results
      targetKey = eastAsiaSearchKey;
    } else if (filteredAfricanPackages.isNotEmpty) {
      // Only African has results
      targetKey = africanSearchKey;
    }

    // Scroll to the target section
    if (targetKey != null) {
      final context = targetKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.0, // Scroll to top of the section
        );
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearchActive = !isSearchActive;
      if (!isSearchActive) {
        searchController.clear();
        searchQuery = '';
        filteredEastAsiaPackages = eastAsiaPackages;
        filteredAfricanPackages = africanPackages;
      } else {
        filteredEastAsiaPackages = eastAsiaPackages;
        filteredAfricanPackages = africanPackages;
      }
    });
  }

  void _onServiceChanged(int serviceId) {
  // FIXED: Add null check and ensure the service exists
  final selectedService = availableServices.firstWhere(
    (service) => service.id == serviceId,
    orElse: () => availableServices.isNotEmpty ? availableServices.first : Service(id: widget.serviceId, name: widget.serviceType),
  );

  setState(() {
    selectedServiceId = serviceId;
    print("selectedServiceId on _onServiceChanged = $selectedServiceId");
    selectedServiceName = selectedService.name;
    // Update the dynamic service title immediately
    _setServiceTitle();
  });
  // Refresh shifts and packages when service changes
  _loadServiceShifts().then((_) {
    // After shifts are loaded, update the UI state and fetch packages
    setState(() {
      // Force rebuild to ensure radio buttons remain visible
    });
    fetchEastAsiaPackages();
    fetchAfricanPackages();
  });
}

  Future<void> fetchEastAsiaPackages() async {
    try {
      print(
          'Fetching East Asia packages with professionId: ${widget.professionId}, serviceId: ${selectedServiceId ?? widget.serviceId}');

      setState(() {
        isEastAsiaLoading = true;
        eastAsiaErrorMessage = null;
      });

      final packages = await ApiService.fetchEastAsiaPackages(
        professionId: widget.professionId,
        serviceId:
            selectedServiceId ?? widget.serviceId, // Use selectedServiceId
        serviceShift: (selectedServiceId ?? widget.serviceId) == 1
            ? selectedEastAsiaShift
            : null,
      );

      setState(() {
        eastAsiaPackages = packages;
        isEastAsiaLoading = false;
      });
    } catch (e) {
      print('Error fetching East Asia packages: $e');
      setState(() {
        eastAsiaErrorMessage = e.toString();
        isEastAsiaLoading = false;
      });
    }

    if (searchQuery.isEmpty) {
      filteredEastAsiaPackages = eastAsiaPackages;
    } else {
      _filterPackages(searchQuery);
    }
  }

// Update your fetchAfricanPackages method to use selectedServiceId
  Future<void> fetchAfricanPackages() async {
    try {
      print(
          'Fetching African packages with professionId: ${widget.professionId}, serviceId: ${selectedServiceId ?? widget.serviceId}');

      setState(() {
        isAfricanLoading = true;
        africanErrorMessage = null;
      });

      final packages = await ApiService.fetchAfricanPackages(
        professionId: widget.professionId,
        serviceId:
            selectedServiceId ?? widget.serviceId, // Use selectedServiceId
        serviceShift: (selectedServiceId ?? widget.serviceId) == 1
            ? selectedAfricanShift
            : null,
      );

      setState(() {
        africanPackages = packages;
        isAfricanLoading = false;
      });
    } catch (e) {
      print('Error fetching African packages: $e');
      setState(() {
        africanErrorMessage = e.toString();
        isAfricanLoading = false;
      });
    }

    if (searchQuery.isEmpty) {
      filteredAfricanPackages = africanPackages;
    } else {
      _filterPackages(searchQuery);
    }
  }

  void _onEastAsiaShiftChanged(int shift) {
    setState(() {
      selectedEastAsiaShift = shift;
    });
    fetchEastAsiaPackages();
  }

  void _onAfricanShiftChanged(int shift) {
    setState(() {
      selectedAfricanShift = shift;
    });
    fetchAfricanPackages();
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

Widget _buildServiceSelector() {
  // Show loading while fetching services
  if (isLoadingServices) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
          SizedBox(height: 24),
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
            'Select Service',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // HORIZONTAL ROW FOR RADIO BUTTONS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableServices
                  .map(
                    (service) => Container(
                      margin: EdgeInsets.only(right: 5),
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
                              activeColor: Colors.purple,
                            ),
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
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

          

          SizedBox(height: 24),
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
          'Select Service',
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
                style: TextButton.styleFrom(foregroundColor: Colors.purple),
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sticky App Bar Header
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 2,
                pinned: true,
                floating: false,
                snap: false,
                expandedHeight: 0,
                toolbarHeight: 70,
                leading: Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Text(
                  "Hourly Services",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 8, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(isSearchActive ? Icons.close : Icons.search,
                          color: Colors.black),
                      onPressed: _toggleSearch,
                    ),
                  ),
                ],
              ),
              if (isSearchActive)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: _filterPackages,
                        decoration: InputDecoration(
                          hintText: 'Search packages, duration, visits...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey[600]),
                                  onPressed: () {
                                    searchController.clear();
                                    _filterPackages('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isSearchActive && searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSearchResultsHeader(),
                ),
              // Main content
              SliverToBoxAdapter(
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
                              borderRadius: BorderRadius.zero,
                              child: Image.asset(
                                'assets/images/cleaning_hero.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
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
                              'Scrub Away\ntough stains',
                              style: TextStyle(
                                fontSize: 28,
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
                          horizontal: 20, vertical: 20), // Consistent padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service selector (only shows when multiple services)
                          _buildServiceSelector(),

                          // Service title
                          Text(
                            dynamicServiceTitle,
                            style: TextStyle(
                              fontSize: 25, // Match package section title size
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16), // Consistent spacing

                          // Design your card button
                          _buildDesignCardButton(),
                          SizedBox(
                              height: 32), // Spacing before package sections

                          // East Asia Pack Section
                          _buildPackageSection(
                            sectionTitle: eastAsiaGroupName,
                            packages: eastAsiaPackages,
                            filteredPackages: filteredEastAsiaPackages,
                            isLoading: isEastAsiaLoading,
                            errorMessage: eastAsiaErrorMessage,
                            onRetry: fetchEastAsiaPackages,
                            isEastAsia: true,
                            sectionKey: eastAsiaKey,
                            searchKey: eastAsiaSearchKey,
                          ),
                          SizedBox(height: 40),

                          // African Pack Section
                          _buildPackageSection(
                            sectionTitle: africanGroupName,
                            packages: africanPackages,
                            filteredPackages: filteredAfricanPackages,
                            isLoading: isAfricanLoading,
                            errorMessage: africanErrorMessage,
                            onRetry: fetchAfricanPackages,
                            isEastAsia: false,
                            sectionKey: africanKey,
                            searchKey: africanSearchKey,
                          ),
                          SizedBox(height: completedBooking != null ? 120 : 20),
                        ],
                      ),
                    ),
                  ],
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            'Congratulations! SAR${completedBooking!.discountAmount.toStringAsFixed(1)} saved so far!',
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
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'SAR ${completedBooking!.originalPrice}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
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
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'View Order',
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


void _showPackageDetailsOverlay(PackageModel package) {
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
                      'Package Details',
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
                          'GET ${package.discountPercentage}% OFF',
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
                          _buildDetailRow('No of Employee', package.noOfEmployee.toString()),
                          SizedBox(height: 8),
                          _buildDetailRow('Duration', '${package.duration} Hours'),
                          SizedBox(height: 8),
                          _buildDetailRow('Weekly Visits', '${package.visitsWeekly}'),
                          SizedBox(height: 8),
                          _buildDetailRow('Contract Duration', '${package.noOfWeeks.toString()} Weeks'),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Price section - outside of grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price:',
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
                            selectedShift: selectedEastAsiaShift,
                            serviceId: selectedServiceId ?? widget.serviceId,
                            professionId: widget.professionId,
                            onBookingCompleted: _onBookingCompleted,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Add',
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

  String _formatPackName(String packName) {
    // Convert "East Asia Pack" to "East Asia\nPack" format
    List<String> words = packName.split(' ');
    if (words.length >= 2) {
      // Take last word as second line, rest as first line
      String lastWord = words.removeLast();
      String firstLine = words.join(' ');
      return '$firstLine\n$lastWord';
    }
    return packName;
  }

  Widget _buildShiftSelector(bool isEastAsia) {
  if (isLoadingShifts || availableShifts.isEmpty) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
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
    
    // Check Arabic shift names - Fixed patterns
    if (lowerShiftName.contains('صباح') || lowerShiftName.contains('الصباح')) {
      return '7:30-10:00 صباحاً';
    } else if (lowerShiftName.contains('مسائي') || lowerShiftName.contains('مساني') || 
               lowerShiftName.contains('مساء') || lowerShiftName.contains('المساء')) {
      return '3:30-6:00 مساءً';
    } else if (lowerShiftName.contains('يوم كامل') || lowerShiftName.contains('كامل')) {
      return '7:30 صباحاً-10:00 مساءً';
    }
    
    return ''; // Default case if shift type is not recognized
  }

  // Helper function to get appropriate icon based on shift name
  IconData _getShiftIcon(String shiftName) {
    final lowerShiftName = shiftName.toLowerCase();
    
    // Check for morning shifts (English and Arabic)
    if (lowerShiftName.contains('morning') || 
        lowerShiftName.contains('صباح') || 
        lowerShiftName.contains('الصباح')) {
      return Icons.wb_sunny;
    }
    
    // Check for evening shifts (English and Arabic) - Fixed patterns
    if (lowerShiftName.contains('evening') || 
        lowerShiftName.contains('مسائي') || 
        lowerShiftName.contains('مساني') ||
        lowerShiftName.contains('مساء') || 
        lowerShiftName.contains('المساء')) {
      return Icons.nightlight_round; 
    }
    
    // Check for full day shifts (English and Arabic) - Fixed patterns
    if (lowerShiftName.contains('full day') || 
        lowerShiftName.contains('fullday') ||
        lowerShiftName.contains('يوم كامل') || 
        lowerShiftName.contains('كامل')) {
      return Icons.access_time; // Changed from schedule to access_time to match screenshot
    }
    
    // Default icon
    return Icons.access_time;
  }

  // Helper function to get icon color based on shift name
  Color _getShiftIconColor(String shiftName, bool isSelected) {
    if (!isSelected) return Colors.grey;
    
    final lowerShiftName = shiftName.toLowerCase();
    
    // Morning shifts - orange
    if (lowerShiftName.contains('morning') || 
        lowerShiftName.contains('صباح') || 
        lowerShiftName.contains('الصباح')) {
      return Colors.orange;
    }
    
    // Evening shifts - indigo - Fixed patterns
    if (lowerShiftName.contains('evening') || 
        lowerShiftName.contains('مسائي') || 
        lowerShiftName.contains('مساني') ||
        lowerShiftName.contains('مساء') || 
        lowerShiftName.contains('المساء')) {
      return Colors.indigo;
    }
    
    // Full day shifts - blue - Fixed patterns
    if (lowerShiftName.contains('full day') || 
        lowerShiftName.contains('fullday') ||
        lowerShiftName.contains('يوم كامل') || 
        lowerShiftName.contains('كامل')) {
      return Colors.blue;
    }
    
    // Default color
    return Colors.grey[700]!;
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
        borderRadius: BorderRadius.circular(25),
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
              Icon(
                _getShiftIcon(shiftName),
                color: _getShiftIconColor(shiftName, true),
                size: 20,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  shiftName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
                fontWeight: FontWeight.w400,
              ),
              textDirection: _isArabicText(deliveryTime) ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }

  // Multiple shifts available - show selector
  int selectedShift =
      isEastAsia ? selectedEastAsiaShift : selectedAfricanShift;
  Function(int) onShiftChanged =
      isEastAsia ? _onEastAsiaShiftChanged : _onAfricanShiftChanged;

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(25),
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
                borderRadius: BorderRadius.circular(25),
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
                      Icon(
                        _getShiftIcon(shiftName),
                        color: _getShiftIconColor(shiftName, isSelected),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          shiftName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w400,
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

  Widget _buildSearchResultsHeader() {
    if (!isSearchActive || searchQuery.isEmpty) return SizedBox.shrink();

    int totalResults =
        filteredEastAsiaPackages.length + filteredAfricanPackages.length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        'Found $totalResults result${totalResults != 1 ? 's' : ''} for "$searchQuery"',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
    required bool isEastAsia,
    required GlobalKey sectionKey,
    required GlobalKey searchKey,
  }) {
    return Container(
      key: isSearchActive && searchQuery.isNotEmpty ? searchKey : sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show section title only if there are results or no search is active
          if (!isSearchActive ||
              searchQuery.isEmpty ||
              filteredPackages.isNotEmpty)
            Text(
              sectionTitle,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

          // Show search results count for this section
          if (isSearchActive &&
              searchQuery.isNotEmpty &&
              filteredPackages.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                '${filteredPackages.length} result${filteredPackages.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Show shift selector only if not searching or has results
          if ((!isSearchActive ||
              searchQuery.isEmpty ||
              filteredPackages.isNotEmpty))
            Column(
              children: [
                SizedBox(height: 16),
                _buildShiftSelector(isEastAsia),
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
          else if (isSearchActive &&
              searchQuery.isNotEmpty &&
              filteredPackages.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Text(
                'No ${sectionTitle.toLowerCase()} packages match your search',
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
                    child: _buildCompactServiceCard(filteredPackages[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesignCardButton() {
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
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Design your card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactServiceCard(PackageModel package) {
  return GestureDetector(
    onTap: () => _showPackageDetailsOverlay(package), // Add this line
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
                      'GET ${package.discountPercentage}% OFF',
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
                  // Package name - truncated
                  Text(
                    package.packageName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  // Visit details
                  Text(
                    '${package.visitsWeekly} weekly visit: ${package.duration} Hours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),

                  // Price row
                  Row(
                    children: [
                      Text(
                        'SAR ${package.finalPrice}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SAR ${package.packagePrice}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
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
                            selectedShift: selectedEastAsiaShift,
                            serviceId: selectedServiceId ?? widget.serviceId,
                            professionId: widget.professionId,
                            onBookingCompleted: _onBookingCompleted,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add',
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

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}