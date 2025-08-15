// newhome.dart

import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fawran/Fawran4Hours/hourly_service_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/package_model.dart';
import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/contractsProvider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/providers/notification_provider.dart';
import 'package:fawran/providers/sliderprovider.dart';
import 'package:fawran/providers/userNameProvider.dart';
import 'package:fawran/screens/FaqScreen.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceChoice.dart';
import 'package:fawran/screens/socialMediaLinks.dart';
import 'package:fawran/screens/user_details.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/screens/address_display_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion_model.dart';
import 'package:fawran/services/location_service.dart';
import 'dart:ui';

class Newhome extends ConsumerWidget {
  const Newhome({super.key});

  String getFullImageUrl(String imagePath) {
    String sanitizedPath = imagePath.replaceAll('\\', '/');
    String encodedPath = Uri.encodeFull(sanitizedPath);
    return "http://fawran.ddns.net:8080/$encodedPath";
  }

  static bool _promotionShown = false;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final sliderItemsAsync = ref.watch(sliderItemsProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final loc = AppLocalizations.of(context)!;
    final isArabic = currentLocale.languageCode == 'ar';
    final hasUnconfirmedContracts = ref.watch(hasUnconfirmedContractsProvider);
    if (!_promotionShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAndShowPromotions(context);
        _promotionShown = true; // Mark as shown
      });
    }
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAFF),
        drawer: _buildSideDrawer(context, ref, userNameAsync, loc, isArabic),
        body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Column(
            children: [
              // Top Bar
              Container(
                height: 124,
                decoration: const BoxDecoration(
                  color: Color(0xFF10295C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu,
                                color: Color(0xFFFFA200), size: 28),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Color(0xFFFFA200), size: 26),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      if (hasUnconfirmedContracts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.blueAccent),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.unconfirmedcontracts,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Text(
                        loc.welcome,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: Color(0xFFFF9800), // #091735
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.intro_text,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: const Color(0xFF091735), // #091735
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Slider
                      sliderItemsAsync.when(
                        data: (items) {
                          final PageController pageController =
                              PageController();
                          int currentPage = 0;
                          final ValueNotifier<int> pageNotifier =
                              ValueNotifier<int>(0);

                          // Auto-slide logic
                          Timer.periodic(const Duration(seconds: 3), (timer) {
                            if (pageController.hasClients) {
                              currentPage = (currentPage + 1) % items.length;
                              pageController.animateToPage(
                                currentPage,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                              pageNotifier.value = currentPage;
                            }
                          });

                          return Stack(
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    child: PageView.builder(
                                      controller: pageController,
                                      itemCount: items.length,
                                      onPageChanged: (index) =>
                                          pageNotifier.value = index,
                                      itemBuilder: (context, index) {
                                        final item = items[index];
                                        final imageUrl =
                                            getFullImageUrl(item.imageUrl);

                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.network(
                                            imageUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error,
                                                    color: Colors.red),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Slider indicator
                                  ValueListenableBuilder<int>(
                                    valueListenable: pageNotifier,
                                    builder: (context, value, _) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(items.length,
                                            (index) {
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            height: 8,
                                            width: value == index ? 24 : 8,
                                            decoration: BoxDecoration(
                                              color: value == index
                                                  ? Colors.blue.shade800
                                                  : Colors.blue.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // Fixed "Popular" tag at bottom left of slider
                              Positioned(
                                bottom: 40, // adjust this to your liking
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    loc.popular,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error loading slider: $e'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.our_services,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0C1A30),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Professions

                      // fixed width

                      // Professions
                      professionsAsync.when(
                        data: (professions) {
                          final PageController pageController = PageController(
                            viewportFraction:
                                0.45, // roughly fits 162 width cards on screen
                            initialPage: professions.length - 1,
                          );

                          return SizedBox(
                            height: 162, // height of the cards
                            child: PageView.builder(
                              controller: pageController,
                              itemCount: professions.length,
                              reverse: true, // RTL direction
                              padEnds: false,
                              itemBuilder: (context, index) {
                                final profession = professions[index];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(selectedProfessionProvider
                                              .notifier)
                                          .state = profession;

                                      final hasDomestic =
                                          profession.hasDomesticPackage;
                                      final serviceCount =
                                          profession.services.length;

                                      if (hasDomestic) {
                                        if (serviceCount > 1) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ServiceChoicePage()),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddressSelectionScreen(
                                                header: profession.positionName,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (serviceCount <= 1) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  HourlyServiceScreen(
                                                professionId:
                                                    profession.positionId,
                                                serviceId:
                                                    profession.services[0].id,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: SizedBox(
                                      width: 162,
                                      height: 162,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(getFullImageUrl(
                                                profession.image)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF072C74),
                                            borderRadius: BorderRadius.vertical(
                                                bottom: Radius.circular(12)),
                                          ),
                                          child: AutoSizeText(
                                            profession.positionName,
                                            textAlign: TextAlign.center,
                                            maxLines:
                                                1, // still limits number of lines
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  14, // starting font size
                                              color: Colors.white,
                                            ),
                                            minFontSize:
                                                9, // smallest font allowed
                                            maxFontSize:
                                                14, // max starting font
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error loading services: $e'),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        loc.saving_packages,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0C1A30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(child: Text(loc.coming_soon)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<String> userNameAsync,
    AppLocalizations loc,
    bool isArabic,
  ) {
    final phoneNumberAsync = ref.watch(phoneNumberProvider);
    final hasUnconfirmedContracts = ref.watch(hasUnconfirmedContractsProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Profile picture with globe icon overlay on left
            SizedBox(
              width: double.infinity, // make Stack fill drawer width
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  Positioned(
                    left: isArabic ? null : 16,
                    right: isArabic ? 12 : null,
                    child: IconButton(
                      icon: const Icon(Icons.public,
                          color: Color(0xFF1E49A0), size: 22),
                      onPressed: () {
                        final localeNotifier =
                            ref.read(localeNotifierProvider.notifier);
                        final currentLocale = ref.read(localeNotifierProvider);

                        if (currentLocale.languageCode == 'en') {
                          localeNotifier.setLocale(const Locale('ar'));
                        } else {
                          localeNotifier.setLocale(const Locale('en'));
                        }
                        ref.refresh(sliderItemsProvider);
                        ref.refresh(professionsProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // User name
            userNameAsync.when(
              data: (name) => Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF091735), // #091735
                ),
                textAlign: TextAlign.center,
              ),
              loading: () => const Text("..."),
              error: (_, __) => Text(loc.user),
            ),
            const SizedBox(height: 20),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/addresses.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.myAddresses,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddressDisplayScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/account.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.myInformation,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyAccountScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/about.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.aboutCompany,
                    onTap: () async {
                      Navigator.pop(context);
                      const url = 'https://emdadhr.com/#/about';
                      final Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/branches.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.companyBranches,
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/social.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.socialMediaLinks,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ConnectWithUsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/faq.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.faq,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FAQPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/bookings.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.myContracts,
                    showNotification: hasUnconfirmedContracts,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/bookings');
                    },
                  ),
                  _buildDrawerItem(
                    iconWidget: SvgPicture.asset(
                      'assets/images/privacy.svg',
                      width: 18,
                      height: 18,
                      color: Color(0xFF1E49A0), // optional tint
                    ),
                    title: loc.privacyPolicy,
                    onTap: () async {
                      Navigator.pop(context);
                      const url = 'https://emdadhr.com/#/PrivacyPolicy';
                      final Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                ],
              ),
            ),

            // Logout at bottom (aligned same as other items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 14),
              child: _buildDrawerItem(
                iconWidget: SvgPicture.asset(
                  'assets/images/logout.svg',
                  width: 20,
                  height: 20,
                  color: Colors.red, // optional tint
                ),
                title: loc.logout,
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      {required Widget iconWidget,
      required String title,
      required VoidCallback onTap,
      bool showNotification = false,
      Color textColor = const Color(0xFF091735)}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: Stack(
        alignment: Alignment.topRight,
        children: [
          Transform.translate(
            offset: const Offset(3, 0), // 0 so it aligns with text baseline
            child: iconWidget,
          ),
          if (showNotification)
            const Positioned(
              right: -2,
              top: 2, // lowered slightly to match icon's new position
              child: CircleAvatar(
                radius: 5,
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(ref);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(WidgetRef ref) async {
    const storage = FlutterSecureStorage();

    // Clear secure storage
    await storage.deleteAll();

    // Call logout from authProvider
    ref.read(authProvider.notifier).logout(ref);
  }

  Future<void> _loadAndShowPromotions(BuildContext context) async {
    // Add this check at the beginning of the method
    if (_promotionShown) return;

    try {
      // Get current city name
      String cityName = await LocationService.getCurrentCityName();
      print('Current city: $cityName');

      // Fetch promotions for the city
      List<PromotionModel> promotions =
          await ApiService.getValidPromotions(cityName);

      if (promotions.isNotEmpty) {
        // Filter promotions that have valid image URLs
        List<PromotionModel> validPromotions = promotions
            .where((promotion) =>
                promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
            .toList();

        if (validPromotions.isNotEmpty) {
          // Show the first valid promotion
          PromotionModel firstValidPromotion = validPromotions.first;

          // Delay to ensure the screen is fully loaded
          await Future.delayed(Duration(milliseconds: 500));

          if (context.mounted) {
            _showPromotionPopup(context, firstValidPromotion);
          }
        } else {
          print('No promotions with valid images found');
        }
      } else {
        print('No promotions found for city: $cityName');
      }
    } catch (e) {
      print('Error loading promotions: $e');
    }
  }

  // ... keep your existing promotion dialog, logout, and helper methods as-is
}

void _showPromotionPopup(BuildContext context, PromotionModel promotion) {
  // Only show popup if imageUrl exists
  if (promotion.imageUrl == null || promotion.imageUrl!.isEmpty) {
    print('No image URL found in promotion, skipping popup');
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Main image container
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    getFullImageUrl(promotion.imageUrl!),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black54,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading promotion image: $error');
                      // Close dialog if image fails to load
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pop();
                      });
                      return SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // Close button positioned at top-right
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String getFullImageUrl(String imagePath) {
  String sanitizedPath = imagePath.replaceAll('\\', '/');
  String encodedPath = Uri.encodeFull(sanitizedPath);
  return "http://fawran.ddns.net:8080/$encodedPath";
}
