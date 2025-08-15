import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectWithUsScreen extends StatelessWidget {
  const ConnectWithUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // light background
appBar: PreferredSize(
  preferredSize: const Size.fromHeight(80),
  child: AppBar(
    backgroundColor: const Color(0xFF0B2A74),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(20),
      ),
    ),
    automaticallyImplyLeading: false,
    flexibleSpace: Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Stack(
        children: [
          // Back arrow at bottom left
          Positioned(
            bottom: -7, // align to bottom
            left: 0,
            child: IconButton(
              padding: EdgeInsets.zero, // remove internal padding
              constraints: const BoxConstraints(), // remove default min size
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFFFFA726),
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Title at bottom center
          Align(
            alignment: Alignment.bottomCenter,
            child: const Text(
              "Connect With Us",
              style: TextStyle(
                color: Color(0xFFFFA726),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
, body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SvgPicture.asset(
              "assets/images/imdadLogo.svg",
              width: 227,
              height: 60,
            ),
            const SizedBox(height: 30),
            // Subtitle
        Text(
  "Follow Us In Social Media",
  style: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF091735),
  ),
),
            const SizedBox(height: 30),
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
                  "assets/images/xplat.svg",
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
