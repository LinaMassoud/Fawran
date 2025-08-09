import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/signup_screen.dart';
import 'package:fawran/services/api_service.dart';
import 'package:fawran/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false; // Prevent setState if widget is gone

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        return true;
      }
      return false;
    });
  }

  void _submitOtp() async {
    if (!mounted) return;
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _isVerifying = true);

    final apiService = ApiService();
    final userId = ref.read(userIdProvider); // ✅ Read from provider

    if (userId == null) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not available')),
      );
      return;
    }

    final success = await apiService.verifyCode(
      userid: userId.toString(),
      otp: code, // ✅ use actual OTP entered
    );

    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification successful!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification failed. Please try again.')),
      );
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);
    final isArabic = locale.languageCode == 'ar';

    return BackgroundContainer(
      showBackButton: true,
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
            color: const Color(0xFFFFA200),
            width: 23,
            height: 23,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Verification Title
            Text(
              loc.verification,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B4C7E),
              ),
            ),
            const SizedBox(height: 16),
            
            // Enter OTP instruction
            Text(
              loc.enterOtp,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B4C7E),
              ),
            ),
            const SizedBox(height: 8),
            
            // Phone number display
            Text(
              '${loc.codeSentTo} ${widget.phoneNumber}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return Container(
                  width: 45,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B4C7E),
                    ),
                    onChanged: (val) => _onOtpChanged(i, val),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            
            // Verify Button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _submitOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06214B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        loc.verify,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Resend Code Button
            TextButton(
              onPressed: _secondsRemaining == 0
                  ? () {
                      // TODO: Trigger resend
                      setState(() => _secondsRemaining = 60);
                      _startCountdown();
                    }
                  : null,
              child: Text(
                _secondsRemaining == 0
                    ? loc.resendCode
                    : '${loc.resendIn} $_secondsRemaining s',
                style: TextStyle(
                  color: _secondsRemaining == 0 
                      ? const Color(0xFF4A90E2) 
                      : Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focus in _focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }
}