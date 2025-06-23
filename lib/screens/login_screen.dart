import 'package:fawran/models/user.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:fawran/screens/location_screen.dart';
import 'package:fawran/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/l10n/app_localizations.dart';

import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  bool _phoneEmpty = false;
  bool _passwordEmpty = false;
  bool _submitted = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() {
      _submitted = true;
      _phoneEmpty = _phoneController.text.trim().isEmpty;
      _passwordEmpty = _passwordController.text.trim().isEmpty;
    });

    if (!_phoneEmpty && !_passwordEmpty) {
      ref.read(authProvider.notifier).login(
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoggedIn && next.isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen()),
        );
      } else if (next.isLoggedIn && !next.isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              phoneNumber: _phoneController.text,
              userId: 'userId',
            ),
          ),
        );
      } else if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage)),
        );
      }
    });

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Language Switch
          Positioned(
            top: 16,
            right: 16,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  const Text('العربية', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: !isArabic,
                    onChanged: (val) {
                      final newLocale =
                          val ? const Locale('en') : const Locale('ar');
                      ref.read(localeProvider.notifier).state = newLocale;
                    },
                    activeTrackColor: Colors.orange,
                  ),
                  const Text('English', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),

          // Login UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        loc.login,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Phone Number
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone),
                        labelText: loc.phoneNumber,
                        border: inputBorder,
                        enabledBorder: _phoneEmpty && _submitted
                            ? errorBorder
                            : inputBorder,
                        focusedBorder: _phoneEmpty && _submitted
                            ? errorBorder
                            : inputBorder,
                        errorText: _phoneEmpty && _submitted
                            ? loc.phoneNumber + ' ' + loc.requiredField
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: loc.password,
                        border: inputBorder,
                        enabledBorder: _passwordEmpty && _submitted
                            ? errorBorder
                            : inputBorder,
                        focusedBorder: _passwordEmpty && _submitted
                            ? errorBorder
                            : inputBorder,
                        errorText: _passwordEmpty && _submitted
                            ? '${loc.password} ${loc.requiredField}'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        loc.forgotPassword,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authState.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(loc.login),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ref.read(authProvider.notifier).clearStateError();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "${loc.dontHaveAccount} ${loc.signUp}",
                          style: const TextStyle(fontWeight: FontWeight.w300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
