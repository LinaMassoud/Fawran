import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'continuous_booking_overlay.dart';
import 'order_summary_screen.dart';


class PackageModel {
  final int pricingId;
  final String groupCode;
  final int serviceId;
  final String serviceShift;
  final int duration;
  final int noOfMonth;
  final double hourPrice;
  final int visitsWeekly;
  final int noOfEmployee;
  final int packageId;
  final double visitPrice;
  final String packageName;
  final int vatPercentage;
  final double packagePrice;
  final double discountPercentage;
  final double priceAfterDiscount;
  final int vatAmount;
  final double finalPrice;

  PackageModel({
    required this.pricingId,
    required this.groupCode,
    required this.serviceId,
    required this.serviceShift,
    required this.duration,
    required this.noOfMonth,
    required this.hourPrice,
    required this.visitsWeekly,
    required this.noOfEmployee,
    required this.packageId,
    required this.visitPrice,
    required this.packageName,
    required this.vatPercentage,
    required this.packagePrice,
    required this.discountPercentage,
    required this.priceAfterDiscount,
    required this.vatAmount,
    required this.finalPrice,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      pricingId: json['pricing_id'],
      groupCode: json['group_code'],
      serviceId: json['service_id'],
      serviceShift: json['service_shift'],
      duration: json['duration'],
      noOfMonth: json['no_of_month'],
      hourPrice: json['hour_price'].toDouble(),
      visitsWeekly: json['visits_weekly'],
      noOfEmployee: json['no_of_employee'],
      packageId: json['package_id'],
      visitPrice: json['visit_price'].toDouble(),
      packageName: json['package_name'],
      vatPercentage: json['vat_percentage'],
      packagePrice: json['package_price'].toDouble(),
      discountPercentage: json['discount_percentage'].toDouble(),
      priceAfterDiscount: json['price_after_discount'].toDouble(),
      vatAmount: json['vat_amount'],
      finalPrice: json['final_price'].toDouble(),
    );
  }

  // Helper methods to get display values
  String get nationalityDisplay {
    if (groupCode == '1') return 'African';        // Fixed: group code 1 is African
    if (groupCode == '2') return 'East Asia';      // Fixed: group code 2 is East Asia
    if (groupCode == '3') return 'South Asia';
    return 'East Asia'; // default
  }

  String get timeDisplay {
    if (serviceShift == 1) return 'Morning';
    if (serviceShift == 2) return 'Afternoon';
    if (serviceShift == 3) return 'Evening';
    return 'Morning'; // default
  }

  String get durationDisplay {
    return '$duration hours';
  }
}

class CleaningServiceScreen extends StatefulWidget {
  const CleaningServiceScreen({Key? key}) : super(key: key);

  @override
  _CleaningServiceScreenState createState() => _CleaningServiceScreenState();
}

class _CleaningServiceScreenState extends State<CleaningServiceScreen> {
  // Global keys for navigation to specific sections
  final GlobalKey eastAsiaKey = const GlobalObjectKey("eastAsia");
  final GlobalKey africanKey = const GlobalObjectKey("african");

  // Package lists for different groups and shifts
  List<PackageModel> eastAsiaPackages = [];
  List<PackageModel> africanPackages = [];
  
  bool isEastAsiaLoading = true;
  bool isAfricanLoading = true;
  String? eastAsiaErrorMessage;
  String? africanErrorMessage;
  
  // Shift selection state
  int selectedEastAsiaShift = 1; // 1 = Morning, 2 = Evening
  int selectedAfricanShift = 1;  // 1 = Morning, 2 = Evening
  
  // Booking state management
  BookingData? completedBooking;
  double totalSavings = 375.0; // This can be calculated based on discounts
  double originalPrice = 1497.0; // This can be calculated from package prices

  @override
  void initState() {
    super.initState();
    fetchEastAsiaPackages();
    fetchAfricanPackages();
  }

  Future<void> fetchEastAsiaPackages() async {
    try {
      setState(() {
        isEastAsiaLoading = true;
        eastAsiaErrorMessage = null;
      });

      // Fixed: Use group_code=2 for East Asia
      final response = await http.get(
        Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/service/packages?service_id=1&service_code=FAWRAN4Hours&profession_id=4'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> packagesJson = data['packages'];
        
        setState(() {
          eastAsiaPackages = packagesJson.map((json) => PackageModel.fromJson(json)).toList();
          isEastAsiaLoading = false;
        });
      } else {
        setState(() {
          eastAsiaErrorMessage = 'Failed to load East Asia packages. Status code: ${response.statusCode}';
          isEastAsiaLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        eastAsiaErrorMessage = 'Error loading East Asia packages: $e';
        isEastAsiaLoading = false;
      });
    }
  }

  Future<void> fetchAfricanPackages() async {
    try {
      setState(() {
        isAfricanLoading = true;
        africanErrorMessage = null;
      });

      // Fixed: Use group_code=1 for African
      final response = await http.get(
        Uri.parse('http://10.20.10.114:8080/ords/emdad/fawran/service/packages?service_id=1&service_code=FAWRAN4Hours&profession_id=4'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> packagesJson = data['packages'];
        
        setState(() {
          africanPackages = packagesJson.map((json) => PackageModel.fromJson(json)).toList();
          isAfricanLoading = false;
        });
      } else {
        setState(() {
          africanErrorMessage = 'Failed to load African packages. Status code: ${response.statusCode}';
          isAfricanLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        africanErrorMessage = 'Error loading African packages: $e';
        isAfricanLoading = false;
      });
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
          ),
        ),
      );
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
                  'Fawran 4 Hours',
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
                      icon: Icon(Icons.search, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 16, top: 10, bottom: 10),
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
                      icon: Icon(Icons.share, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),
                ],
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
                    
                    // Main content
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service title and rating
                          Text(
                            'Fawran 4 Hours',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.black, size: 20),
                              SizedBox(width: 4),
                              Text(
                                '4.80 (3.5M bookings)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // Plus membership banner and offers
                          Container(
                            height: 80,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Container(
                                  width: 280,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.blue, size: 24),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Save 10% on every order',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Get Plus now',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                ),
                                _buildOfferCard('Special Weekend Deal', '20% OFF', Colors.green),
                                _buildOfferCard('First Time User', '25% OFF', Colors.orange),
                                _buildOfferCard('Monthly Package', '30% OFF', Colors.purple),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),
                          
                          // Service packs (removed Evening pack)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _scrollToSection(eastAsiaKey),
                                  child: _buildServicePack(
                                    'East Asia\nPack',
                                    'assets/images/east_asia_flags.png',
                                    Colors.blue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _scrollToSection(africanKey),
                                  child: _buildServicePack(
                                    'African\nPack',
                                    'assets/images/african_flags.png',
                                    Colors.green,
                                  ),
                                ),
                              ),
                              // Removed the Evening pack entirely
                              SizedBox(width: 15), // Empty space to maintain layout
                            ],
                          ),
                          SizedBox(height: 40),
                          
                          // East Asia Pack Section with Segmented Control
                          Container(
                            key: eastAsiaKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'East Asia Pack',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                // Segmented Control for East Asia
                                Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(25),
  ),
  child: Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _onEastAsiaShiftChanged(1),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selectedEastAsiaShift == 1 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              boxShadow: selectedEastAsiaShift == 1
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: selectedEastAsiaShift == 1 ? Colors.orange : Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Morning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selectedEastAsiaShift == 1 ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => _onEastAsiaShiftChanged(2),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selectedEastAsiaShift == 2 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              boxShadow: selectedEastAsiaShift == 2
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: selectedEastAsiaShift == 2 ? Colors.indigo : Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Evening',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selectedEastAsiaShift == 2 ? Colors.black : Colors.grey[600],
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
SizedBox(height: 20),

                                
                                if (isEastAsiaLoading)
                                  Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (eastAsiaErrorMessage != null)
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
                                          eastAsiaErrorMessage!,
                                          style: TextStyle(color: Colors.red[700]),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: fetchEastAsiaPackages,
                                          child: Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...eastAsiaPackages.map((package) => Column(
                                    children: [
                                      _buildServiceCardFromAPI(package),
                                      SizedBox(height: 20),
                                    ],
                                  )).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          
                          // African Pack Section with Segmented Control
                          Container(
                            key: africanKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'African Pack',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                // Segmented Control for African
                                Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(25),
  ),
  child: Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _onEastAsiaShiftChanged(1),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selectedEastAsiaShift == 1 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              boxShadow: selectedEastAsiaShift == 1
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: selectedEastAsiaShift == 1 ? Colors.orange : Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Morning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selectedEastAsiaShift == 1 ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => _onEastAsiaShiftChanged(2),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selectedEastAsiaShift == 2 ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              boxShadow: selectedEastAsiaShift == 2
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: selectedEastAsiaShift == 2 ? Colors.indigo : Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Evening',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selectedEastAsiaShift == 2 ? Colors.black : Colors.grey[600],
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
SizedBox(height: 20),

                                
                                if (isAfricanLoading)
                                  Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (africanErrorMessage != null)
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
                                          africanErrorMessage!,
                                          style: TextStyle(color: Colors.red[700]),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: fetchAfricanPackages,
                                          child: Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...africanPackages.map((package) => Column(
                                    children: [
                                      _buildServiceCardFromAPI(package),
                                      SizedBox(height: 20),
                                    ],
                                  )).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: completedBooking != null ? 120 : 20), // Add bottom padding when order view is shown
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
                            'Congratulations! SAR${totalSavings.toStringAsFixed(0)} saved so far!',
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
                                      'SAR ${completedBooking!.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'SAR ${originalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
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
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
  
  Widget _buildOfferCard(String title, String discount, Color color) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  discount,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildServiceCardFromAPI(PackageModel package) {
    return Container(
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
          // Service image with discount badge
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      'assets/images/cleaning_service_card.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.brown[100],
                          child: Center(
                            child: Icon(
                              Icons.cleaning_services,
                              size: 60,
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
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GET ${package.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    package.packageName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          
          // Service details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${package.visitsWeekly} weekly visit: ${package.duration} Hours\nCleaning Visit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Pass the entire package object to address selection with callback
                        ContinuousBookingOverlay.showAsOverlay(
                          context, 
                          package: package,
                          onBookingCompleted: _onBookingCompleted, // Add this callback
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '4.83 (34K reviews)', // You can make this dynamic if available in API
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Starts at SAR ${package.finalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'SAR ${package.packagePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16),
                Text(
                  'Book ${package.visitsWeekly} weekly cleaning visit from fawran ${package.duration} hours at discounted price.\nAvail first visit now with an option of customizing.\n\n'
                  '• Duration: ${package.duration} hours\n'
                  '• Monthly visits: ${package.visitsWeekly * 4}\n'
                  '• Number of employees: ${package.noOfEmployee}\n'
                  '• VAT: ${package.vatPercentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'View details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}