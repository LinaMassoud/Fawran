import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashTimer();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SvgPicture.asset(
          'assets/images/onboarding_background.svg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}