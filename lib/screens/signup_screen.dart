import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  late final ProviderSubscription _subscription;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final nameRegex = RegExp(r'^[a-zA-Z0-9\u0600-\u06FF]+$');

  final nameOnlyRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF]+$');
  final numberOnlyRegex = RegExp(r'^\d+$');
  final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$');
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isSignedUp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              phoneNumber: _phoneController.text,
            ),
          ),
        );
      }
    });
    final authState = ref.watch(authProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.signUp)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: loc.firstName,
                icon: Icons.person,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.firstName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.firstName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _middleNameController,
                label: loc.middleName,
                icon: Icons.person,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.middleName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.middleName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _lastNameController,
                label: loc.lastName,
                icon: Icons.person,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.lastName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.lastName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nationalIdController,
                label: "National Id",
                icon: Icons.person,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'national id is required';
                  if (!numberOnlyRegex.hasMatch(val))
                    return 'national id must not contain characters';
                  if (val.length != 9) return 'national id must be 9 numbers';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                label: loc.phoneNumber,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.phoneNumber} is required';
                  if (!phoneRegex.hasMatch(val))
                    return ' enter valid ${loc.phoneNumber} ';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                label: loc.email,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.email} is required';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  return emailRegex.hasMatch(val) ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _passwordController,
                label: loc.password,
                icon: Icons.lock,
                validator: (val) => val != null && val.length >= 6
                    ? null
                    : 'Password must be at least 6 characters',
                isObscured: !_showPassword,
                toggleVisibility: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _confirmPasswordController,
                label: loc.confirmPassword,
                icon: Icons.lock,
                validator: (val) => val == _passwordController.text
                    ? null
                    : 'Passwords do not match',
                isObscured: !_showConfirmPassword,
                toggleVisibility: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authProvider.notifier).signUp(
                              userName: _phoneController.text,
                              firstName: _firstNameController.text,
                              middleName: _middleNameController.text,
                              lastName: _lastNameController.text,
                              phoneNumber: _phoneController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                              nationalId: _nationalIdController.text);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc.signUp),
              ),
              if (authState.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  authState.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: Text(loc.alreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? toggleVisibility,
    bool? isObscured,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured ?? obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  (isObscured ?? obscureText)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
    );
  }
}
