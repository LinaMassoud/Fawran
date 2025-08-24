import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onSplashComplete;
  final Duration duration;
  final Widget? nextScreen;
  final bool autoNavigate;

  const SplashScreen({
    Key? key,
    this.onSplashComplete,
    this.duration = const Duration(seconds: 3),
    this.nextScreen,
    this.autoNavigate = false,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _fadeController.forward();
    
    // Trigger network request for iOS wireless data permission
    _triggerNetworkPermission();
    
    // Start splash timer
    _startSplashTimer();
  }

  Future<void> _triggerNetworkPermission() async {
    // Only attempt on iOS
    if (Platform.isIOS) {
      try {
        // Make a simple HTTP request to trigger the wireless data permission dialog
        // Using a lightweight endpoint that's likely to be available
        final response = await http.get(
          Uri.parse('https://www.google.com/generate_204'),
          headers: {'User-Agent': 'Fawran-iOS-App'},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Return a dummy response if timeout occurs
            return http.Response('', 204);
          },
        );
        
        print('Network permission request completed with status: ${response.statusCode}');
      } catch (e) {
        // Silently handle any network errors
        // The permission dialog should still appear even if the request fails
        print('Network permission request failed: $e');
      }
    }
  }

  void _startSplashTimer() {
    Future.delayed(widget.duration, () {
      if (mounted) {
        if (widget.autoNavigate && widget.nextScreen != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.nextScreen!),
          );
        } else if (widget.onSplashComplete != null) {
          widget.onSplashComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: SvgPicture.asset(
                'assets/images/background1.svg',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}