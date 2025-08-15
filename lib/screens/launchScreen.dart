import 'package:fawran/OnboardingScreens/onboarding_screen.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:fawran/screens/newhome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'package:fawran/OnboardingScreens/splash_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _determineNextScreen();
  }

  Future<void> _determineNextScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      setState(() {
        _nextScreen = const LoginScreen();
        _isLoading = false;
      });
    } else {
      String? token = await _secureStorage.read(key: 'token');
      if (token != null && token.isNotEmpty) {
        setState(() {
          _nextScreen = const Newhome();
          _isLoading = false;
        });
      } else {
        setState(() {
          _nextScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNextScreen() {
    if (_nextScreen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _nextScreen!,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SplashScreen(
        duration: const Duration(seconds: 2),
        onSplashComplete: () {
          if (!_isLoading) {
            _navigateToNextScreen();
          }
        },
      );
    } else {
      return SplashScreen(
        duration: const Duration(milliseconds: 500),
        onSplashComplete: _navigateToNextScreen,
      );
    }
  }
}
