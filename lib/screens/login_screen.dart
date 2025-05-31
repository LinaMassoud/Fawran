import 'package:fawran/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isArabic;
  final ValueChanged<bool?> onLanguageChanged;

  const LoginScreen({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoggedIn) {
        // Navigate to home or another screen after successful login
      
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
                    value: !widget.isArabic,
                    onChanged: (val) => widget.onLanguageChanged(!val),
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

                    // Phone / Email
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.emailAddress,
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
                      controller: _passwordController,
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
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                final email = _phoneController.text.trim();
                                final password =
                                    _passwordController.text.trim();
                                ref.read(authProvider.notifier).login(
                                      phoneNumber: email,
                                      password: password,
                                    );
                              },
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
