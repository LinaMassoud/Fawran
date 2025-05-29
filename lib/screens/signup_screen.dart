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

  final _userNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
void initState() {
  super.initState();


}

  @override
  void dispose() {
    _userNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                controller: _userNameController,
                label: loc.firstName,
                icon: Icons.person,
                validator: (val) =>
                    val == null || val.isEmpty ? '${loc.firstName} is required' : null,
              ),
                            const SizedBox(height: 10),

              _buildTextField(
                controller: _firstNameController,
                label: loc.firstName,
                icon: Icons.person,
                validator: (val) =>
                    val == null || val.isEmpty ? '${loc.firstName} is required' : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _middleNameController,
                label: loc.middleName,
                icon: Icons.person,
                validator: (val) =>
                    val == null || val.isEmpty ? '${loc.middleName} is required' : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _lastNameController,
                label: loc.lastName,
                icon: Icons.person,
                validator: (val) =>
                    val == null || val.isEmpty ? '${loc.lastName} is required' : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                label: loc.phoneNumber,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.isEmpty ? '${loc.phoneNumber} is required' : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                label: loc.email,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return '${loc.email} is required';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  return emailRegex.hasMatch(val) ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _passwordController,
                label: loc.password,
                icon: Icons.lock,
                obscureText: true,
                validator: (val) => val != null && val.length >= 6
                    ? null
                    : 'Password must be at least 6 characters',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _confirmPasswordController,
                label: loc.confirmPassword,
                icon: Icons.lock,
                obscureText: true,
                validator: (val) => val == _passwordController.text
                    ? null
                    : 'Passwords do not match',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authProvider.notifier).signUp(
                                userName: _userNameController.text,
                                firstName: _firstNameController.text,
                                middleName: _middleNameController.text,
                                lastName: _lastNameController.text,
                                phoneNumber: _phoneController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                              );
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
                              builder: (context) => LoginScreen(isArabic: true, onLanguageChanged: (bool? value) {
                                print("object");
                              },),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
