import 'package:fawran/models/user.dart';
import 'package:fawran/providers/contractsProvider.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/providers/userNameProvider.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:fawran/screens/location_screen.dart';
import 'package:fawran/screens/newhome.dart';
import 'package:fawran/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fawran/OnboardingScreens/splash_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import '../widgets/background_container.dart';
import 'forgot_password_screen.dart';

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
  void initState() {
    super.initState();
  }

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
      print("Inside _handleLogin");
      ref.read(authProvider.notifier).login(
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
            ref: ref,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeNotifierProvider);
    final isArabic = locale.languageCode == 'ar';

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoggedIn && next.isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SplashScreen(
              duration: const Duration(seconds: 3),
              nextScreen: Newhome(),
              autoNavigate: true,
            ),
          ),
        );
      } else if (next.isLoggedIn && !next.isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              phoneNumber: _phoneController.text,
            ),
          ),
        );
      } else if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage)),
        );
      }
    });

    return BackgroundContainer(
      showBackButton: false,
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
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFA200),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Welcome Back Title
            Center(
              child: Text(
                loc.welcomeBack,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10295C),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Phone Number Field with Floating Label
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                labelText: loc.phone,
                hintText: isArabic
                    ? 'أدخل رقم هاتفك'
                    : 'Enter your phone number',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SvgPicture.asset(
                    'assets/icons/phone.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
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
            const SizedBox(height: 20),

            // Password Field with Floating Label
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                labelText: loc.password,
                hintText: isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SvgPicture.asset(
                    'assets/icons/lock.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
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
                    ? '${loc.password} ${loc.requiredField}'
                    : null,
              ),
            ),

            // Forgot Password Link
            const SizedBox(height: 8),
              Align(
                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // Clear any existing error messages
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    
                    // Navigate to forgot password screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    loc.forgotPassword,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A69DD),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Login Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
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
                        loc.login,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${loc.dontHaveAccount} ",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
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
                    loc.signUp,
                    style: const TextStyle(
                      color: const Color(0xFF1A69DD),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}