import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/verification_screen.dart';
import 'package:fawran/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';

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

  final nameOnlyRegex =
      RegExp(r'^(?=.{3,}$)[a-zA-Z\u0600-\u06FF]+(?: [a-zA-Z\u0600-\u06FF]+)*$');

  final numberOnlyRegex = RegExp(r'^\d+$');
  final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{7,20}$');
  final nationalIdRegex = RegExp(r'^[12]\d{9}$');

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
    final locale = ref.watch(localeNotifierProvider);
    final isArabic = locale.languageCode == 'ar';

    return BackgroundContainer(
      showBackButton: true,
      topSectionHeight: MediaQuery.of(context).size.height * 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  loc.getStarted,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10295C),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              _buildTextField(
                controller: _firstNameController,
                label: loc.firstName,
                hintText:
                    isArabic ? 'أدخل الاسم الأول' : 'Enter your first name',
                iconPath: 'assets/icons/person.svg',
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.firstName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.firstName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _middleNameController,
                label: loc.middleName,
                hintText:
                    isArabic ? 'أدخل الاسم الأوسط' : 'Enter your middle name',
                iconPath: 'assets/icons/person.svg',
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.middleName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.middleName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _lastNameController,
                label: loc.lastName,
                hintText:
                    isArabic ? 'أدخل الاسم الأخير' : 'Enter your last name',
                iconPath: 'assets/icons/person.svg',
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.lastName} is required';
                  if (!nameOnlyRegex.hasMatch(val))
                    return '${loc.lastName} must not contain special characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nationalIdController,
                label: "National ID",
                hintText: isArabic
                    ? 'أدخل رقم الهوية الوطنية'
                    : 'Enter your national ID',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'National ID is required';
                  if (!nationalIdRegex.hasMatch(val))
                    return 'National ID must be 10 digits and start with 1 or 2';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: loc.phoneNumber,
                hintText:
                    isArabic ? 'أدخل رقم الهاتف' : 'Enter your phone number',
                iconPath: 'assets/icons/phone.svg',
                keyboardType: TextInputType.phone,
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.phoneNumber} is required';
                  if (!phoneRegex.hasMatch(val))
                    return 'Enter valid Saudi ${loc.phoneNumber}';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: loc.email,
                hintText:
                    isArabic ? 'أدخل البريد الإلكتروني' : 'Enter your email',
                iconPath: 'assets/icons/email.svg',
                keyboardType: TextInputType.emailAddress,
                isArabic: isArabic,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return '${loc.email} is required';
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  return emailRegex.hasMatch(val) ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: loc.password,
                hintText: isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
                iconPath: 'assets/icons/lock.svg',
                isArabic: isArabic,
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
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                label: loc.confirmPassword,
                hintText:
                    isArabic ? 'تأكيد كلمة المرور' : 'Confirm your password',
                iconPath: 'assets/icons/lock.svg',
                isArabic: isArabic,
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
              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          // Trim all inputs before validation and usage
                          _firstNameController.text =
                              _firstNameController.text.trim();
                          _middleNameController.text =
                              _middleNameController.text.trim();
                          _lastNameController.text =
                              _lastNameController.text.trim();
                          _nationalIdController.text =
                              _nationalIdController.text.trim();

                          if (_formKey.currentState!.validate()) {
                            ref.read(authProvider.notifier).signUp(
                                  userName: _phoneController.text,
                                  firstName: _firstNameController.text,
                                  middleName: _middleNameController.text,
                                  lastName: _lastNameController.text,
                                  phoneNumber: _phoneController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  nationalId: _nationalIdController.text,
                                );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06214B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          loc.signUp,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Error message
              if (authState.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Login navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${loc.alreadyHaveAccount} ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      loc.login,
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Extra bottom padding for safe scrolling
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? iconPath,
    IconData? icon,
    required bool isArabic,
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
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: iconPath != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SvgPicture.asset(
                  iconPath,
                  color: Colors.grey.shade400,
                  width: 16,
                  height: 16,
                ),
              )
            : icon != null
                ? Icon(
                    icon,
                    color: Colors.grey.shade400,
                    size: 16,
                  )
                : null,
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  (isObscured ?? obscureText)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: toggleVisibility,
              )
            : null,
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
      ),
    );
  }
}
