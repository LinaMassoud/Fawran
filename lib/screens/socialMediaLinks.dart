import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConnectWithUsScreen extends StatelessWidget {
  const ConnectWithUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // light background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A74), // dark blue
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFFFFA726)), // orange
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Connect With Us",
          style: TextStyle(
            color: Color(0xFFFFA726), // orange
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SvgPicture.asset(
              "assets/images/imdadLogo.svg",
              width: 120,
            ),
            const SizedBox(height: 12),
            // Subtitle
            const Text(
              "Follow Us In Social Media",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            // Social media icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/facebook.svg",
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 16),
                SvgPicture.asset(
                  "assets/images/insta.svg",
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 16),
                SvgPicture.asset(
                  "assets/images/x.svg",
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 16),
                SvgPicture.asset(
                  "assets/images/linkedin.svg",
                  width: 40,
                  height: 40,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
