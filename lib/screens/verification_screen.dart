import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/signup_screen.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String usernme;

  const VerificationScreen({super.key, required this.phoneNumber, required this.usernme});

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
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        return true;
      }
      return false;
    });
  }

  void _submitOtp() async {
  final code = _otpControllers.map((c) => c.text).join();
  if (code.length < 6) return;

  setState(() => _isVerifying = true);

  final apiService = ApiService();

  final success = await apiService.verifyCode(
    username: widget.usernme, // Replace this with the actual value
    otp: '000000',
  );

  setState(() => _isVerifying = false);

  if (!mounted) return;

  if (success) {
 Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification failed. Please try again.')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.verification),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    ); 
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loc.enterOtp,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${loc.codeSentTo} ${widget.phoneNumber}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (val) => _onOtpChanged(i, val),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.all(8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isVerifying ? null : _submitOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isVerifying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(loc.verify),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _secondsRemaining == 0 ? () {
                // TODO: Trigger resend
                setState(() => _secondsRemaining = 60);
                _startCountdown();
              } : null,
              child: Text(_secondsRemaining == 0
                  ? loc.resendCode
                  : '${loc.resendIn} $_secondsRemaining s'),
            ),
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
