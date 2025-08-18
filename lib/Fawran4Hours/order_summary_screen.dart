import 'package:flutter/material.dart';
import 'continuous_booking_overlay.dart';
import '../models/booking_model.dart';
import '../screens/bookings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:checkout_flutter/checkout_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderSummaryScreen extends ConsumerStatefulWidget {
  final BookingData bookingData;
  final double totalSavings;
  final double originalPrice;
  final VoidCallback? onPaymentSuccess; // Added callback
  final bool customBooking;

  const OrderSummaryScreen({
    Key? key,
    required this.bookingData,
    required this.totalSavings,
    required this.originalPrice,
    this.onPaymentSuccess, // Added callback parameter
    this.customBooking = false,
  }) : super(key: key);

  @override
  _OrderSummaryScreenState createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  bool _isPaymentSummaryExpanded = false;
  bool _agreeToTerms = false;
  bool _isLoadingTerms = false; 
  String _termsContent = '';

  late ConfettiController _confettiController;
  String _checkoutStatus = '';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();



@override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

Future<void> _fetchServiceTerms() async {
  setState(() {
    _isLoadingTerms = true;
  });

  try {
    final result = await ApiService.fetchServiceTerms();
    
    setState(() {
      if (result['success']) {
        // Store the terms as JSON string to be parsed later
        _termsContent = result['terms'];
      } else {
        _termsContent = result['message'];
      }
      _isLoadingTerms = false;
    });
  } catch (e) {
    print('Error: $e');
    setState(() {
      _termsContent = 'Error loading terms and conditions. Please check your internet connection.';
      _isLoadingTerms = false;
    });
  }
}


void _showTermsAndConditions(AppLocalizations loc) async {
  await _fetchServiceTerms();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final currentLocale = ref.watch(localeNotifierProvider);
      final isArabic = currentLocale.languageCode == 'ar';
      
      return Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.termsAndCond,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  color: Colors.grey[300],
                  margin: EdgeInsets.symmetric(vertical: 16),
                ),
                
                // Content
                Expanded(
                  child: _isLoadingTerms
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF10295C),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading terms and conditions...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: _buildFormattedTerms(),
                      ),
                ),
                
                // Close button
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10295C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      loc.close,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Add this new method to format the terms properly
Widget _buildFormattedTerms() {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  try {
    // Try to parse _termsContent as JSON array
    final List<dynamic> termsList = json.decode(_termsContent);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < termsList.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF10295C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    termsList[i].toString(),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  } catch (e) {
    // Fallback to plain text display if JSON parsing fails
    return Text(
      _termsContent,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }
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
            // Sticky Header with overlap - same as hourly_service_screen
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
                loc.orderSummary,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Color(0xFFFFA200),
                ),
              ),
              centerTitle: true,
              elevation: 0,
              floating: false,
              snap: false,
            ),
            
            // Add negative margin to create overlap
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: Offset(0, -40), // Negative offset to create overlap
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 40, // Add top padding to account for the overlap
                      bottom: 180,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        // Service details section
                        Text(
                          loc.serviceDetails,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Service details card
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Service title
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.bookingData.packageName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              // Service details rows
                              _buildDetailRow(
                                  loc.startDate,
                                  _formatDate(
                                      widget.bookingData.selectedDates.isNotEmpty
                                          ? widget.bookingData.selectedDates.first
                                          : DateTime.now())),
                              SizedBox(height: 12),
                              _buildDetailRow(
                                loc.weeklyVisits, 
                                _getLocalizedVisitsPerWeek(widget.bookingData.visitsPerWeek, loc)
                            ),
                              SizedBox(height: 16),
                              Container(height: 1, color: Colors.grey[300]),
                              SizedBox(height: 16),
                              _buildDetailRow(
                                  loc.service,
                                  _getLocalizedNationality(widget.bookingData.selectedNationality, loc)),
                              SizedBox(height: 12),
                              _buildDetailRow(
                                  loc.workers, '${widget.bookingData.workerCount}'),
                              SizedBox(height: 12),
                              _buildDetailRow(loc.contractDuration,
                                  _getLocalizedContractDurationSimple(widget.bookingData.contractDuration, loc)),
                              SizedBox(height: 16),
                              Container(height: 1, color: Colors.grey[300]),
                              SizedBox(height: 16),

                              // Final Price section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      loc.finalPrice,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${widget.bookingData.totalPrice.toStringAsFixed(1)} ${loc.currencyHourly}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Billing and payment section
                        Text(
                          loc.billingPayment,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Payment methods
                        Row(
                          children: [
                            _buildPaymentLogo(
                                'assets/images/Mada-Logo.png', Colors.blue),
                            SizedBox(width: 8),
                            _buildPaymentLogo(
                                'assets/images/visa-logo.png', Colors.blue),
                            SizedBox(width: 8),
                            _buildPaymentLogo(
                                'assets/images/mastercard.png', Colors.red),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Payment summary section - Hidden for custom bookings
                        if (!widget.customBooking) ...[
                          Text(
                            loc.paymentSummary,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Payment breakdown
                          _buildPaymentRow(loc.itemTotal,
                              '${(widget.bookingData.originalPrice).toStringAsFixed(1)} ${loc.currencyHourly}'),
                          SizedBox(height: 12),
                          _buildPaymentRow(loc.packDiscount,
                              '${widget.bookingData.discountAmount.toStringAsFixed(1)}-${loc.currencyHourly}',
                              isDiscount: true),
                          SizedBox(height: 16),
                          Container(height: 1, color: Colors.black87),
                          SizedBox(height: 16),

                          // Savings banner
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${loc.savedSummary} ${widget.bookingData.discountAmount.toStringAsFixed(0)} ${loc.currencyHourly} ${loc.onFinalBill}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                        ],

                        // Total - Always shown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.total,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${widget.bookingData.totalPrice.toStringAsFixed(1)} ${loc.currencyHourly}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Terms and conditions
                        Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: Color(0xFF10295C),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    text: loc.agreementHourly,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: loc.termsAndCond,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF10295C),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            _showTermsAndConditions(loc);
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Bottom section with dynamic address and proceed button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1E49A0).withOpacity(0.15), // Blue tinted shadow
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset(0, -5),
              ),
              BoxShadow(
                color: Color(0xFF1E49A0).withOpacity(0.08), // Additional lighter blue shadow
                blurRadius: 40,
                spreadRadius: 5,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic address section
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.home, color: Colors.black54, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookingData.selectedAddress,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _getAddressDetails(
                                widget.bookingData.selectedAddress),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey[300]),

              // Proceed to pay button
              Container(
                padding: EdgeInsets.fromLTRB(
                24, 
                16, 
                24, 
                MediaQuery.of(context).padding.bottom > 0 
                  ? MediaQuery.of(context).padding.bottom + 10 
                  : 25
              ), // Updated to match BookingBottomNavigation
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _agreeToTerms
                        ? () {
                            _startCheckout();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreeToTerms ? Color(0xFF10295C) : Color(0xFF768090), // Updated disabled color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Color(0xFF768090), // Ensure disabled color is consistent
                      disabledForegroundColor: Colors.white, // White text when disabled
                    ),
                    child: Text(
                      loc.proceedToPay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

String _getLocalizedVisitsPerWeek(int visitsPerWeek, AppLocalizations loc) {
  return '$visitsPerWeek ${loc.weeklyVisits}';
}

String _getLocalizedNationality(String nationality, AppLocalizations loc) {
  // Map English nationalities to localized versions
  switch (nationality.toLowerCase()) {
    case 'east asia':
      return loc.eastAsia ?? 'شرق آسيا'; // fallback if localization doesn't exist
    case 'african':
      return loc.africa ?? 'جنوب آسيا';
    default:
      return nationality; // fallback to original if no mapping found
  }
}



String _getLocalizedContractDurationSimple(int contractDuration, AppLocalizations loc) {
  // Check if contract duration is exactly divisible by 4
  if (contractDuration % 4 == 0 && contractDuration >= 4) {
    // Convert weeks to months (4 weeks = 1 month)
    int months = contractDuration ~/ 4; // Use integer division
    return '$months ${loc.month ?? 'شهر'}';
  } else {
    // Display as weeks for any duration not exactly divisible by 4
    return '$contractDuration ${loc.weeks ?? 'أسابيع'}';
  }
}


  Widget _buildDetailRow(String label, String value) {
    print("Value from _buildDetailRow = ${value}");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentLogo(String imagePath, Color fallbackColor) {
    return Container(
      height: 32,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: fallbackColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  imagePath.contains('mada')
                      ? 'مدى'
                      : (imagePath.contains('visa') ? 'VISA' : 'MC'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount,
      {bool isDotted = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            decoration: isDotted ? TextDecoration.underline : null,
            decorationStyle: isDotted ? TextDecorationStyle.dotted : null,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    String day = date.day.toString();
    String suffix = 'th';
    if (day.endsWith('1') && day != '11')
      suffix = 'st';
    else if (day.endsWith('2') && day != '12')
      suffix = 'nd';
    else if (day.endsWith('3') && day != '13') suffix = 'rd';

    return '${day}${suffix} ${months[date.month - 1]}\'${date.year.toString().substring(2)}';
  }

  // Helper method to get address details based on selected address
  String _getAddressDetails(String selectedAddress) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  final loc = AppLocalizations.of(context)!;
  
  // You can customize this based on your address structure
  // For now, providing default details based on the address name
  switch (selectedAddress) {
    case 'Al rashidiya':
      return isArabic 
        ? 'منطقة الرياض، إمارة الرياض، الرياض'
        : 'Riyadh Province, Riyadh Principality, Riyadh';
    case 'Al Abha':
      return isArabic 
        ? 'منطقة عسير، إمارة أبها، أبها'
        : 'Asir Province, Al Abha Principality, Al Abha';
    default:
      return isArabic 
        ? loc.saudiArabia ?? 'المملكة العربية السعودية'
        : 'Saudi Arabia'; // Default fallback
  }
}

  Future<void> _startCheckout() async {
  try {
    setState(() {
      _checkoutStatus = 'Starting checkout...';
    });
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Get customer information from secure storage
    final firstName = await _secureStorage.read(key: 'first_name') ?? 'Customer';
    final lastName = await _secureStorage.read(key: 'last_name') ?? '';
    final phoneNumber = await _secureStorage.read(key: 'phone_number') ?? '555123456';
    final userId = await _secureStorage.read(key: 'user_id') ?? '';

    // Extract contract details from bookingData
    final contractId = widget.bookingData.contractId?.toString() ?? '';
    final sector = 'H'; // Default sector for hourly service
    final amount = widget.bookingData.totalPrice.toString();
    final customerName = widget.bookingData.packageName;
    final serviceDescription = "${widget.bookingData.packageName} - ${widget.bookingData.workerCount} workers for ${widget.bookingData.contractDuration} weeks";

    // Print contract ID and sector for debugging
    print('Contract ID: $contractId');
    print('Sector: $sector');

    final currentLocale = ref.watch(localeNotifierProvider);

    Map<String, dynamic> configurations = {
      "hashString": "",
      "language": currentLocale.languageCode == 'ar' ? "ar" : "en",
      "themeMode": "light",
      "supportedPaymentMethods": ["VISA", "MASTERCARD", "APPLE_PAY", "MADA","GOOGLE_PAY","STC_PAY"],
      "paymentType": "ALL",
      "selectedCurrency": "SAR",
      "supportedCurrencies": ["SAR"],
      "supportedPaymentTypes": [],
      "supportedRegions": [],
      "supportedSchemes": [],
      "supportedCountries": [],
      "gateway": {
        "publicKey": "pk_test_pLd7nzHMmgBXUqNFP1E0SWOZ",
        "merchantId": "",
      },
      "customer": {
        "firstName": firstName,
        "lastName": lastName,
        "email": "customer@example.com",
        "phone": {"countryCode": "965", "number": phoneNumber},
      },
      "transaction": {
        "mode": "charge",
        "charge": {
          "saveCard": true,
          "auto": {"type": "VOID", "time": 100},
          "redirect": {
            "url": "https://demo.staging.tap.company/v2/sdk/checkout",
          },
          "threeDSecure": true,
          "subscription": {
            "type": "SCHEDULED",
            "amount_variability": "FIXED",
            "txn_count": 0,
          },
          "airline": {
            "reference": {"booking": ""},
          },
        },
      },
      "amount": amount,
      "order": {
        "id": "",
        "currency": "SAR",
        "amount": amount,
        "items": [
          {
            "amount": amount,
            "currency": "SAR",
            "name": customerName,
            "quantity": 1,
            "description": serviceDescription,
          },
        ],
      },
      "cardOptions": {
        "showBrands": true,
        "showLoadingState": true,
        "collectHolderName": true,
        "preLoadCardName": "",
        "cardNameEditable": true,
        "cardFundingSource": "all",
        "saveCardOption": "all",
        "forceLtr": false,
        "alternativeCardInputs": {"cardScanner": false, "cardNFC": false},
      },
      "isApplePayAvailableOnClient": true,
    };

    // Call startCheckout function directly
    final success = await startCheckout(
      configurations: configurations,
      onReady: () {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          _checkoutStatus = 'Checkout is ready!';
        });
        print('Checkout is ready!');
      },
      onSuccess: (data) async {
        try {
          final parsedData = jsonDecode(data); // Parse the response data
          final chargeId = parsedData["chargeId"];
          
          print('Payment successful: $data');
          
          // Call API to add charge payment
          final result = await ApiService.addChargePayment(userId, contractId, sector, chargeId);
          
          if (result.statusCode == 200) {
            _confettiController.play();
            _showPaymentSuccessDialog();
          } else {
            Map<String, dynamic> parsed = jsonDecode(result.body);
            _showPaymentErrorDialog(parsed["message"]);
          }
        } catch (ex) {
          _showPaymentErrorDialog("Something went wrong");
          print('Error processing payment success: $ex');
        }
      },
      onError: (error) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        setState(() {
          _checkoutStatus = 'Payment failed: $error';
        });
        print('Payment failed: $error');
        _showPaymentErrorDialog(error.toString());
      },
      onClose: () {
        Navigator.of(context).pop(); // Close loading dialog if still open
        setState(() {
          _checkoutStatus = 'Checkout closed';
        });
        print('Checkout closed');
      },
      onCancel: () {
        Navigator.of(context).pop(); // Close loading dialog if still open
        setState(() {
          _checkoutStatus = 'Checkout cancelled';
        });
        print('Checkout cancelled (Android)');
      },
    );

    if (!success) {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        _checkoutStatus = 'Failed to start checkout';
      });
      _showPaymentErrorDialog('Failed to start checkout');
    }
  } catch (e) {
    Navigator.of(context).pop(); // Close loading dialog
    setState(() {
      _checkoutStatus = 'Error: $e';
    });
    _showPaymentErrorDialog(e.toString());
  }
}

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '🎉 Payment Successful!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your order has been confirmed successfully. Thank you for your purchase!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog first
                        
                        // Call the callback to notify parent about successful payment
                        if (widget.onPaymentSuccess != null) {
                          widget.onPaymentSuccess!();
                        }
                        
                        // Navigate to BookingsScreen and remove all previous routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => BookingsScreen(initialTab: 'hourly'),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10295C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 100,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                gravity: 0.3,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Payment Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Sorry, your payment could not be processed. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}