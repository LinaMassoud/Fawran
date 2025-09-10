// Create a new file: discount_step.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/address_model.dart';
import 'package:fawran/generated/app_localizations.dart';
import '../providers/localProvider.dart';
import 'dart:ui' as ui;
import '../models/package_model.dart';
import '../models/promotion_model.dart';
import '../providers/address_provider.dart';

class DiscountStep extends ConsumerStatefulWidget {
  final double originalPrice;
  final double originalPricePerVisit;
  final int serviceId;
  final String selectedTime;
  final Address? selectedAddress;
  final double hourPrice;
  final int totalVisits;
  final Function(double)? onTotalPriceChanged;
  final Function(double)? onPricePerVisitChanged;
  final Function(int?)? onPromotionIdChanged;
  final Function(String?)? onPromotionCodeChanged;
  final VoidCallback? onSkipPressed;
  final VoidCallback? onNextPressed;
  final PackageModel? package; 

  const DiscountStep({
    Key? key,
    required this.originalPrice,
    required this.originalPricePerVisit,
    required this.serviceId,
    required this.selectedTime,
    this.selectedAddress,
    required this.hourPrice,
    required this.totalVisits,
    this.onTotalPriceChanged,
    this.onPricePerVisitChanged,
    this.onPromotionIdChanged,
    this.onPromotionCodeChanged,
    this.onSkipPressed,
    this.onNextPressed,
    this.package,
  }) : super(key: key);

  @override
  ConsumerState<DiscountStep> createState() => _DiscountStepState();
}

class _DiscountStepState extends ConsumerState<DiscountStep> {
  final TextEditingController _couponController = TextEditingController();
  
  String _couponCode = '';
  bool _isValidatingCoupon = false;
  bool _isCouponApplied = false;
  String _couponMessage = '';
  bool _isCouponValid = false;
  double _discountedPrice = 0.0;
  double _discountedPricePerVisit = 0.0;
  int? _appliedPromotionId;
  String _appliedPromotionCode = '';

  List<PromotionModel> _availablePromotions = [];
bool _isLoadingPromotions = false;
String? _currentCityName;

  @override
void initState() {
  super.initState();
  _discountedPrice = widget.originalPrice;
  _discountedPricePerVisit = widget.originalPricePerVisit;
  
  // Pre-fill and auto-apply package promotion code
  if (widget.package?.promotionCode != null && widget.package!.promotionCode!.isNotEmpty) {
    _couponController.text = widget.package!.promotionCode!;
    _couponCode = widget.package!.promotionCode!;
    _isCouponApplied = true;
    _isCouponValid = true;
    _couponMessage = '';
    _appliedPromotionId = widget.package!.promotionId;
    _appliedPromotionCode = widget.package!.promotionCode!;
    _discountedPrice = widget.package!.finalPrice;
    
    // Calculate price per visit for package promotion
    if (widget.totalVisits > 0) {
      _discountedPricePerVisit = widget.package!.finalPrice / widget.totalVisits;
    } else {
      _discountedPricePerVisit = widget.package!.visitPrice?.toDouble() ?? widget.originalPricePerVisit;
    }
    
    // Notify parent about pre-applied promotion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onPromotionIdChanged != null) {
        widget.onPromotionIdChanged!(widget.package!.promotionId);
      }
      if (widget.onPromotionCodeChanged != null) {
        widget.onPromotionCodeChanged!(widget.package!.promotionCode!);
      }
      if (widget.onTotalPriceChanged != null) {
        widget.onTotalPriceChanged!(_discountedPrice);
      }
      if (widget.onPricePerVisitChanged != null) {
        widget.onPricePerVisitChanged!(_discountedPricePerVisit);
      }
    });
  }
  
  // Load available promotions for custom bookings after build
  if (widget.package == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailablePromotions();
    });
  }
}

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

Future<void> _loadAvailablePromotions() async {
  setState(() {
    _isLoadingPromotions = true;
  });

  try {
    // Get city name from selected address
    _currentCityName = _getCityNameFromAddress();
    
    if (_currentCityName == null) {
      print('No selected address found for promotions');
      setState(() {
        _isLoadingPromotions = false;
      });
      return;
    }
    
    // Fetch available promotions for the city
    final promotions = await ApiService.getValidPromotions(_currentCityName!);
    
    setState(() {
      _availablePromotions = promotions;
      _isLoadingPromotions = false;
    });
  } catch (e) {
    print('Error loading promotions: $e');
    setState(() {
      _isLoadingPromotions = false;
    });
  }
}

  Future<void> _validateCouponCode() async {
  final loc = AppLocalizations.of(context)!;
  
  if (_couponCode.trim().isEmpty) {
    _showMessage(loc.pleaseEnterCouponCode ?? 'Please enter a coupon code', false);
    return;
  }

  // Check if this is the pre-applied promotion code from the package
  if (widget.package?.promotionCode != null && 
      _couponCode.trim() == widget.package!.promotionCode!) {
    setState(() {
      _isCouponValid = true;
      _isCouponApplied = true;
      _couponMessage = loc.packagePromotionApplied ?? 'Package promotion applied successfully!';
      _appliedPromotionId = widget.package!.promotionId;
      _appliedPromotionCode = widget.package!.promotionCode!;
      _discountedPrice = widget.package!.finalPrice;
      
      if (widget.totalVisits > 0) {
        _discountedPricePerVisit = widget.package!.finalPrice / widget.totalVisits;
      }
    });
    
    // Call parent callbacks
    if (widget.onPromotionIdChanged != null) {
      widget.onPromotionIdChanged!(_appliedPromotionId);
    }
    if (widget.onPromotionCodeChanged != null) {
      widget.onPromotionCodeChanged!(_appliedPromotionCode);
    }
    if (widget.onTotalPriceChanged != null) {
      widget.onTotalPriceChanged!(_discountedPrice);
    }
    if (widget.onPricePerVisitChanged != null) {
      widget.onPricePerVisitChanged!(_discountedPricePerVisit);
    }
    return;
  }

  if (widget.selectedAddress == null) {
    _showMessage(loc.pleaseSelectAddressFirst ?? 'Please select an address first', false);
    return;
  }

  setState(() {
    _isValidatingCoupon = true;
    _couponMessage = '';
  });

  try {
    // Get shift ID from selected time
    int shiftId = 1;
    try {
      final serviceShifts = await ApiService.fetchServiceShifts(serviceId: widget.serviceId);
      final matchingShift = serviceShifts.firstWhere(
        (shift) => shift['service_shifts']?.toString().toLowerCase() == widget.selectedTime.toLowerCase(),
        orElse: () => {'id': 1},
      );
      shiftId = int.parse(matchingShift['id'].toString());
    } catch (e) {
      print('Error fetching shift ID for coupon: $e');
    }

    // Get city code
    int cityCode = 1;
    if (widget.selectedAddress != null) {
      cityCode = int.tryParse(widget.selectedAddress!.cityCode.toString()) ?? 1;
    }

    // FIXED: Use package originalPrice for package bookings, widget.originalPrice for custom bookings
    double priceForValidation = widget.package != null 
        ? widget.package!.originalPrice 
        : widget.originalPrice;

    print('Validating coupon with parameters:');
    print('  - promotionCode: $_couponCode');
    print('  - shiftId: $shiftId');
    print('  - cityCode: $cityCode');
    print('  - originalPrice: $priceForValidation');
    print('  - hourPrice: ${widget.hourPrice}');
    print('  - totalVisits: ${widget.totalVisits}');

    final response = await ApiService.validatePromotion(
      promotionCode: _couponCode.trim(),
      shiftId: shiftId,
      cityCode: cityCode,
      originalPrice: priceForValidation,
      hourPrice: widget.hourPrice,
      totalVisits: widget.totalVisits,
    );

    if (response != null && response['valid'] == true) {
      final newFinalPrice = response['final_price']?.toDouble() ?? widget.originalPrice;
      final newPricePerVisit = response['price_per_visit']?.toDouble() ?? widget.originalPricePerVisit;
      final promotionId = response['promotion_id'] as int?;
      
      setState(() {
        _isCouponValid = true;
        _isCouponApplied = true;
        _couponMessage = response['message'] ?? (loc.couponAppliedSuccessfully ?? 'Coupon applied successfully!');
        _appliedPromotionId = promotionId;
        _appliedPromotionCode = _couponCode.trim();
        _discountedPricePerVisit = newPricePerVisit;
        _discountedPrice = newFinalPrice;
        _isValidatingCoupon = false;
      });

      // Call parent callbacks
      if (widget.onPromotionIdChanged != null) {
        widget.onPromotionIdChanged!(promotionId);
      }
      if (widget.onPromotionCodeChanged != null) {
        widget.onPromotionCodeChanged!(_appliedPromotionCode);
      }
      if (widget.onTotalPriceChanged != null) {
        widget.onTotalPriceChanged!(_discountedPrice);
      }
      if (widget.onPricePerVisitChanged != null) {
        widget.onPricePerVisitChanged!(_discountedPricePerVisit);
      }
    } else {
      setState(() {
        _isCouponValid = false;
        _isCouponApplied = false;
        _couponMessage = response?['message'] ?? (loc.invalidCouponCode ?? 'Invalid coupon code');
        _isValidatingCoupon = false;
      });
    }
  } catch (e) {
    print('Error validating coupon: $e');
    setState(() {
      _isValidatingCoupon = false;
      _isCouponValid = false;
      _isCouponApplied = false;
      _couponMessage = loc.errorValidatingCoupon ?? 'Error validating coupon. Please try again.';
    });
  }
}

  void _removeCoupon() {
  // Determine the correct price to reset to based on whether it's a package or custom booking
  double resetPrice;
  double resetPricePerVisit;
  
  if (widget.package != null) {
    // For package bookings, reset to the package's final price (which already includes package discounts)
    resetPrice = widget.package!.originalPrice;
    resetPricePerVisit = widget.package!.visitPrice?.toDouble() ?? widget.originalPricePerVisit;
  } else {
    // For custom bookings, reset to the original calculated price
    resetPrice = widget.originalPrice;
    resetPricePerVisit = widget.originalPricePerVisit;
  }

  setState(() {
    _isCouponApplied = false;
    _isCouponValid = false;
    _couponMessage = '';
    _couponCode = '';
    _couponController.clear();
    _appliedPromotionId = null;
    _appliedPromotionCode = '';
    _discountedPrice = resetPrice;
    _discountedPricePerVisit = resetPricePerVisit;
  });

  // Reset parent callbacks with the correct reset price
  if (widget.onPromotionIdChanged != null) {
    widget.onPromotionIdChanged!(null);
  }
  if (widget.onPromotionCodeChanged != null) {
    widget.onPromotionCodeChanged!(null);
  }
  if (widget.onTotalPriceChanged != null) {
    widget.onTotalPriceChanged!(resetPrice);
  }
  if (widget.onPricePerVisitChanged != null) {
    widget.onPricePerVisitChanged!(resetPricePerVisit);
  }
}

String? _getCityNameFromAddress() {
  final selectedAddress = ref.read(selectedAddressProvider);
  if (selectedAddress?.cardText != null) {
    // Extract city name from cardText (it's the first part before the first hyphen)
    final parts = selectedAddress!.cardText.split('-');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
  }
  return null;
}

  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _couponMessage = message;
      _isCouponValid = isSuccess;
    });
  }

  Widget _buildCouponField(AppLocalizations loc) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // CHANGED: Use stretch instead of conditional alignment
      children: [
        // CHANGED: Wrap the Text widget with Align for proper positioning
        Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            loc.couponCode,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF091735),
            ),
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          ),
        ),
        SizedBox(height: 12),
        Row(
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                textAlign: isArabic ? TextAlign.right : TextAlign.left, // ADDED: Explicit text alignment
                onChanged: (value) {
                  setState(() {
                    _couponCode = value;
                    // Reset validation state when text changes, but only if it's not the pre-applied promotion
                    if (widget.package?.promotionCode == null || 
                        value.trim() != widget.package!.promotionCode!) {
                      if (_isCouponApplied || _couponMessage.isNotEmpty) {
                        _isCouponApplied = false;
                        _isCouponValid = false;
                        _couponMessage = '';
                        _appliedPromotionId = null;
                        _appliedPromotionCode = '';
                        _discountedPrice = widget.originalPrice;
                        _discountedPricePerVisit = widget.originalPricePerVisit;
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                hintText: loc.enterCouponCode,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  textBaseline: TextBaseline.alphabetic,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                // FIXED: Corrected the suffix/prefix icon logic for RTL
                suffixIcon: (isArabic && _isCouponApplied) // CHANGED: For Arabic, close icon goes to suffix (left side visually)
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: _removeCoupon,
                      )
                    : null,
                prefixIcon: (!isArabic && _isCouponApplied) // CHANGED: For LTR, close icon goes to prefix (right side visually) 
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: _removeCoupon,
                      )
                    : null,
              ),
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.black,
                  textBaseline: TextBaseline.alphabetic, // ADDED: For better Arabic text rendering
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              height: 42,
              child: ElevatedButton(
                onPressed: !_isValidatingCoupon ? _validateCouponCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCouponApplied ? Colors.green : Color(0xFF10295C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isValidatingCoupon
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isCouponApplied ? loc.applied : loc.apply,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (_couponMessage.isNotEmpty) ...[
          SizedBox(height: 8),
          Row(
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              Icon(
                _isCouponValid ? Icons.check_circle : Icons.error,
                size: 16,
                color: _isCouponValid ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _couponMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isCouponValid ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildPackagePromotionHint(AppLocalizations loc) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  // Only show if package has promotion code and no coupon is currently applied
  if (widget.package?.promotionCode == null || 
      widget.package!.promotionCode!.isEmpty || 
      _isCouponApplied) {
    return SizedBox.shrink();
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Row(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.blue.shade600,
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // CHANGED: Use stretch
            children: [
              // CHANGED: Wrap each text with Align widget
              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  loc.packagePromotionAvailable ?? 'Package Promotion Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left, // ADDED: Explicit text alignment
                ),
              ),
              SizedBox(height: 4),
              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  '${loc.code ?? 'Code'}: ${widget.package!.promotionCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontFamily: 'monospace',
                  ),
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left, // ADDED: Explicit text alignment
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            _couponController.text = widget.package!.promotionCode!;
            _couponCode = widget.package!.promotionCode!;
            _validateCouponCode();
          },
          child: Text(
            loc.apply,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAvailablePromotions(AppLocalizations loc) {
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';
  
  // Only show for custom bookings (no package)
  if (widget.package != null) {
    return SizedBox.shrink();
  }

  // Hide available promotions if a coupon is currently applied
  if (_isCouponApplied) {
    return SizedBox.shrink();
  }

  // Show loading state
  if (_isLoadingPromotions) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Show message if no address selected
  if (_currentCityName == null) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        children: [
          Icon(
            Icons.location_off,
            color: Colors.orange.shade600,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select an address to see available promotions', // You can add this to localization
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  if (_availablePromotions.isEmpty) {
    return SizedBox.shrink();
  }

  return Container(
    margin: EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Always start, alignment handled by Align widget
      children: [
        Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            loc.availablePromotions, // You can add this to localization
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF091735),
            ),
            textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          ),
        ),
        SizedBox(height: 12),
        Column(
          children: _availablePromotions.map((promotion) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isArabic 
                      ? '${loc.get} ${promotion.discount}%'
                      : '${promotion.discount}% ${loc.off}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Always start, alignment handled by Align
                    children: [
                      Align(
                        alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          '${loc.code ?? 'Code'}: ${promotion.promotionCode}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                            fontFamily: 'monospace',
                          ),
                          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _couponController.text = promotion.promotionCode;
                    _couponCode = promotion.promotionCode;
                    _validateCouponCode();
                  },
                  child: Text(
                    loc.apply,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final currentLocale = ref.watch(localeNotifierProvider);
  final isArabic = currentLocale.languageCode == 'ar';

  // Set localized message for pre-applied package promotion
  if (widget.package?.promotionCode != null && 
      widget.package!.promotionCode!.isNotEmpty && 
      _isCouponApplied && 
      _couponMessage.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _couponMessage = loc.packagePromotionApplied ?? 'Package promotion applied successfully!';
      });
    });
  }
  
  return Directionality(
    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Title
                    Align(
                      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        loc.applyDiscountCode, // Replace hardcoded 'Apply Discount Code'
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF091735),
                        ),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        loc.enterCouponCodeDescription, // Replace hardcoded description
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Coupon Code Field
                    _buildCouponField(loc),

                    _buildPackagePromotionHint(loc),
                    _buildAvailablePromotions(loc),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation - Updated with RTL support
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 45),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E49A0).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              children: [
                // Price section - Updated alignment
                Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.totalIncVat,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w700,
                      ),
                      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                    Text(
                      '${_discountedPrice} ${loc.currencyHourly}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF091735),
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ],
                ),

                SizedBox(width: 16),

                // Continue Button
                Expanded(
                  flex: 6,
                  child: GestureDetector(
                    onTap: widget.onNextPressed,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Color(0xFF10295C),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          loc.done,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    ),
  );
}
}