import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/screens/ChangePasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class MyAccountScreen extends ConsumerStatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends ConsumerState<MyAccountScreen> {
  final _storage = const FlutterSecureStorage();

  String firstName = '';
  String middleName = '';
  String lastName = '';
  String phoneNumber = '';
  String email = '';
  String userID = '';
  String nationaId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    firstName = await _storage.read(key: 'first_name') ?? '';
    middleName = await _storage.read(key: 'middle_name') ?? '';
    lastName = await _storage.read(key: 'last_name') ?? '';
    phoneNumber = await _storage.read(key: 'phone_number') ?? '';
    email = await _storage.read(key: 'email') ?? '';
    userID = await _storage.read(key: 'user_id') ?? '';
    nationaId = await _storage.read(key: 'national_id') ?? '';

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final isRTL = locale.languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A2A66),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              loc.myAccountTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Image
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "$firstName $lastName",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    // Account Section
                    sectionTitle(loc.accountSection),
                    listTileItem(
                      icon: Icons.person_outline,
                      title: loc.personalInformation,
                      subtitle:
                          "${loc.firstNameLabel}  : $firstName\n${loc.middleNameLabel}: $middleName\n${loc.lastNameLabel}: $lastName\n${loc.nationalIdLabel}: $nationaId",
                      onTap: () {},
                    ),

                    const SizedBox(height: 12),

                    sectionTitle(loc.personalDetailsSection),
                    listTileItem(
                      svgAsset: 'assets/images/email.svg',
                      title: loc.email,
                      subtitle: email,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    listTileItem(
                      icon: Icons.phone_outlined,
                      title: loc.phone,
                      subtitle: phoneNumber,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    listTileItem(
                      icon: Icons.lock_outline,
                      title: loc.changePasswordLabel,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ChangePasswordScreen(), // your target screen
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget listTileItem({
    IconData? icon,
    String? svgAsset,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment:
            hasSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Background rectangle for icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(224, 234, 255, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset,
                      width: 20,
                      height: 20,
                      color: Colors.black54,
                    )
                  : Icon(icon, color: Colors.black54, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          // Title + optional subtitle
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        ],
      ),
    );
  }
}
