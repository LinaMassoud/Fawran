import 'package:flutter/material.dart';
import 'continuous_booking_overlay.dart';
import '../models/booking_model.dart';
import '../screens/bookings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
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


Future<void> _fetchServiceTerms() async {
  setState(() {
    _isLoadingTerms = true;
  });

  try {
    final result = await ApiService.fetchServiceTerms(ref: ref);
    
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


void _showTermsAndConditions() async {
  await _fetchServiceTerms();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
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
                    'Terms and Conditions',
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
                            color: Colors.purple,
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
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Close',
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
      );
    },
  );
}

// Add this new method to format the terms properly
Widget _buildFormattedTerms() {
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
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.purple,
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Summary',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service details section
                  Text(
                    'Service details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                              // Wrap the Text with Expanded
                              child: Text(
                                widget.bookingData.packageName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow
                                    .ellipsis, // Handle overflow gracefully
                                maxLines: 2, // Allow up to 2 lines if needed
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Service details rows
                        _buildDetailRow(
                            'Start Date',
                            _formatDate(
                                widget.bookingData.selectedDates.isNotEmpty
                                    ? widget.bookingData.selectedDates.first
                                    : DateTime.now())),
                        // Use actual nationality instead of 'East Asia'
                        SizedBox(height: 12),
                        _buildDetailRow(
                            'Weekly visits', widget.bookingData.visitsPerWeek),
                        SizedBox(height: 16),
                        Container(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        _buildDetailRow(
                            'Nationality',
                            widget.bookingData
                                .selectedNationality), // Use actual nationality instead of 'East Asia'
                        SizedBox(height: 12),
                        _buildDetailRow(
                            'Workers', '${widget.bookingData.workerCount}'),
                        SizedBox(height: 12),
                        _buildDetailRow('Contract Duration',
                            widget.bookingData.contractDuration),
                        SizedBox(height: 16),
                        Container(height: 1, color: Colors.grey[300]),
                        SizedBox(height: 16),

                        // Weekly visit section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Final Price",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SAR ${widget.bookingData.totalPrice.toStringAsFixed(1)}',
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
                    'Billing and payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

                  if (!_isPaymentSummaryExpanded) ...[
                    // Coupons and offers card
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
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Coupons and offers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Payment summary section - Hidden for custom bookings
                  if (!widget.customBooking) ...[
                    Text(
                      'Payment summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Payment breakdown
                    _buildPaymentRow('Item total',
                        'SAR ${(widget.bookingData.originalPrice).toStringAsFixed(1)}'),
                    SizedBox(height: 12),
                    _buildPaymentRow('Pack discount',
                        '-SAR ${widget.bookingData.discountAmount.toStringAsFixed(1)}',
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
                            'Yay! You have saved SAR ${widget.bookingData.discountAmount.toStringAsFixed(0)} on final bill',
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
                        'Total',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'SAR ${widget.bookingData.totalPrice.toStringAsFixed(1)}',
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
                      activeColor: Colors.purple,
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
                              text: 'I agree to the ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.purple,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _showTermsAndConditions();
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
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom section with dynamic address and proceed button
          Container(
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
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _agreeToTerms
                          ? () {
                              // Handle proceed to pay
                              _showPaymentSuccess();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _agreeToTerms ? Colors.purple : Colors.grey[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed to pay',
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
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
    // You can customize this based on your address structure
    // For now, providing default details based on the address name
    switch (selectedAddress) {
      case 'Al rashidiya':
        return 'Riyadh Province, Riyadh Principality, Riyadh';
      case 'Al Abha':
        return 'Asir Province, Al Abha Principality, Al Abha';
      default:
        return 'Saudi Arabia'; // Default fallback
    }
  }

  void _showPaymentSuccess() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.all(24), // Add proper padding
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Center align all content
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
              'Order Created Successfully!',
              textAlign: TextAlign.center, // Add text alignment
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create order successfully. Kindly pay within 60 minutes otherwise order will be cancelled.',
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
                  backgroundColor: Colors.purple,
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
      );
    },
  );
}
}