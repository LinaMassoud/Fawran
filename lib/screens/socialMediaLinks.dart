import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectWithUsScreen extends StatelessWidget {
  const ConnectWithUsScreen({super.key});

  // 🔗 Helper function to open links
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
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
                // Back arrow
                Positioned(
                  bottom: -7,
                  left: 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFFFA726),
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Title
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    loc.connectwithus,
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
      ),
      body: Center(
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
              loc.followus,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF091735),
              ),
            ),
            const SizedBox(height: 30),
            // Social media icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Facebook
                GestureDetector(
                  onTap: () => _launchUrl(
                      "https://www.facebook.com/share/1Ry3FMZviX/"),
                  child: SvgPicture.asset(
                    "assets/images/facebook.svg",
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 16),
                // Instagram
                GestureDetector(
                  onTap: () => _launchUrl(
                      "https://www.instagram.com/fawranksa?igsh=N3ZsNXdqNncyazgz"),
                  child: SvgPicture.asset(
                    "assets/images/insta.svg",
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 16),
                // LinkedIn
                GestureDetector(
                  onTap: () => _launchUrl(
                      "https://www.linkedin.com/company/fawranksa/"),
                  child: SvgPicture.asset(
                    "assets/images/linkedin.svg",
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
