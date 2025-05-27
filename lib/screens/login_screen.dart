import 'package:fawran/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<bool?> onLanguageChanged;

  const LoginScreen({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Language Switch (top-right, fixed LTR)
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
                    onChanged: (val) => onLanguageChanged(!val),
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
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone),
                        labelText: loc.phoneNumber,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: loc.password,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
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

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Submit logic here
                        },
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(loc.login),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up
                    Center(
                      child: TextButton(
                        onPressed: () {
                            Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
                        },
                        child: Text(
                          "${loc.dontHaveAccount} ${loc.signUp}",
                          style: const TextStyle(fontWeight: FontWeight.w300),
                        ),
                      ),
                    )
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
