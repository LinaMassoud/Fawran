import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';
import '../widgets/background_container.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  
  // Validation states
  bool _phoneEmpty = false;
  bool _otpEmpty = false;
  bool _passwordEmpty = false;
  bool _confirmPasswordEmpty = false;
  bool _passwordMismatch = false;
  bool _submitted = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Updated method to use FlashyFlushbar with localized messages and SVG icons
  void _showFlashyFlushbar(String message, {bool isError = false}) {
    FlashyFlushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: isError ? Colors.red : Colors.green,
      leadingWidget: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 24,
      ),
      isDismissible: true,
    ).show();
  }

  Future<void> _sendOTP() async {
    final loc = AppLocalizations.of(context)!;
    
    setState(() {
      _submitted = true;
      _phoneEmpty = _phoneController.text.trim().isEmpty;
    });

    if (_phoneEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.sendForgotPasswordOTP(
        phoneNumber: _phoneController.text.trim(),
      );

      if (response != null) {
        final statusCode = response['status_code'] ?? 200;
        final isSuccess = statusCode >= 200 && statusCode < 300;
        
        // Handle both 'message' and 'error' fields from backend
        final message = response['message'] ?? response['error'] ?? loc.unknownResponse;
        
        _showFlashyFlushbar(message, isError: !isSuccess);
        
        if (isSuccess) {
          setState(() {
            _currentStep = 1;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        _showFlashyFlushbar(loc.failedSendOTP, isError: true);
      }
    } catch (e) {
      _showFlashyFlushbar(loc.errorOccurred, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final loc = AppLocalizations.of(context)!;
    
    setState(() {
      _submitted = true;
      _otpEmpty = _otpController.text.trim().isEmpty;
      _passwordEmpty = _passwordController.text.trim().isEmpty;
      _confirmPasswordEmpty = _confirmPasswordController.text.trim().isEmpty;
      _passwordMismatch = _passwordController.text.trim() != _confirmPasswordController.text.trim();
    });

    if (_otpEmpty || _passwordEmpty || _confirmPasswordEmpty || _passwordMismatch) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.resetPasswordWithOTP(
        phoneNumber: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      if (response != null) {
        final statusCode = response['status_code'] ?? 200;
        final isSuccess = statusCode >= 200 && statusCode < 300;
        
        // Handle both 'message' and 'error' fields from backend
        final message = response['message'] ?? response['error'] ?? loc.unknownResponse;
        
        // Show message from server response
        _showFlashyFlushbar(message, isError: !isSuccess);
        
        if (isSuccess) {
          // Add a small delay before navigating back to allow user to see the success message
          await Future.delayed(const Duration(seconds: 1));
          
          // Navigate back to login screen
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        _showFlashyFlushbar(loc.failedResetPassword, isError: true);
      }
    } catch (e) {
      _showFlashyFlushbar(loc.errorOccurred, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBackButton() {
    if (_currentStep == 1) {
      // If on step 2 (reset step), go back to step 1 (phone step)
      setState(() {
        _currentStep = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // If on step 1 (phone step), go back to login screen
      Navigator.of(context).pop();
    }
  }

  Widget _buildPhoneStep(AppLocalizations loc, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        
        // Title
        Center(
          child: Text(
            loc.forgotPassword,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10295C),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Subtitle
        Center(
          child: Text(
            loc.enterPhoneForOTP,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),

        // Phone Number Field
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: loc.phone,
            hintText: loc.enterPhoneNumber,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SvgPicture.asset(
                'assets/icons/phone.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _phoneEmpty && _submitted
                ? '${loc.phoneNumber} ${loc.requiredField}'
                : null,
          ),
        ),
        const SizedBox(height: 32),

        // Send OTP Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06214B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc.sendOTP,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep(AppLocalizations loc, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        
        // Title
        Center(
          child: Text(
            loc.resetPassword,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10295C),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Subtitle
        Center(
          child: Text(
            '${loc.enterOTPSentTo} ${_phoneController.text}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),

        // OTP Field
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: loc.otp,
            hintText: loc.enterResetOTP,
            prefixIcon: Icon(
              Icons.security_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _otpEmpty && _submitted
                ? '${loc.otp} ${loc.requiredField}'
                : null,
          ),
        ),
        const SizedBox(height: 20),

        // New Password Field
        TextField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: loc.newPassword,
            hintText: loc.enterNewPassword,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SvgPicture.asset(
                'assets/icons/lock.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
              ),
            ),
            suffixIcon: IconButton(
            icon: Padding(
              padding: const EdgeInsets.all(2.0),
              child: SvgPicture.asset(
                _passwordVisible
                    ? 'assets/icons/eye-regular-full.svg'
                    : 'assets/icons/eye-slash-regular-full.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade400,
                  BlendMode.srcIn,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _passwordEmpty && _submitted
                ? '${loc.newPassword} ${loc.requiredField}'
                : null,
          ),
        ),
        const SizedBox(height: 20),

        // Confirm Password Field
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: loc.confirmPassword,
            hintText: loc.confirmNewPassword,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SvgPicture.asset(
                'assets/icons/lock.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
              ),
            ),
            suffixIcon: IconButton(
              icon: Padding(
                padding: const EdgeInsets.all(2.0),
                child: SvgPicture.asset(
                  _confirmPasswordVisible
                      ? 'assets/icons/eye-regular-full.svg'
                      : 'assets/icons/eye-slash-regular-full.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade400,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: _confirmPasswordEmpty && _submitted
                ? '${loc.confirmPassword} ${loc.requiredField}'
                : _passwordMismatch && _submitted
                    ? loc.passwordsDoNotMatch
                    : null,
          ),
        ),
        const SizedBox(height: 32),

        // Reset Password Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06214B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc.resetPassword,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);
    final isArabic = locale.languageCode == 'ar';

    return BackgroundContainer(
      showBackButton: true,
      onBackPressed: _handleBackButton,
      topSectionHeight: MediaQuery.of(context).size.height * 0.25,
      topRightWidget: GestureDetector(
        onTap: () {
          final newLocale = isArabic ? const Locale('en') : const Locale('ar');
          ref.read(localeNotifierProvider.notifier).setLocale(newLocale);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset(
            'assets/icons/language.svg',
            width: 23,
            height: 23,
            colorFilter: const ColorFilter.mode(Color(0xFFFFA200), BlendMode.srcIn),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPhoneStep(loc, isArabic),
              _buildResetStep(loc, isArabic),
            ],
          ),
        ),
      ),
    );
  }
}