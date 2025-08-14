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
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceChoice.dart';
import 'package:fawran/screens/socialMediaLinks.dart';
import 'package:fawran/screens/user_details.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/screens/address_display_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion_model.dart';
import 'package:fawran/services/location_service.dart';
import 'dart:ui';

// Move the phoneNumberProvider outside the class
final phoneNumberProvider = FutureProvider<String>((ref) async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'phone_number') ?? '';
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String getFullImageUrl(String imagePath) {
    String sanitizedPath = imagePath.replaceAll('\\', '/');
    String encodedPath = Uri.encodeFull(sanitizedPath);
    return "http://fawran.ddns.net:8080/$encodedPath";
  }
static bool _promotionShown = false;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final location = ref.watch(locationProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final sliderItemsAsync = ref.watch(sliderItemsProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final loc = AppLocalizations.of(context)!;
    final isArabic = currentLocale.languageCode == 'ar';

    final hasUnconfirmedContracts = ref.watch(hasUnconfirmedContractsProvider);

    final examplePackage = PackageModel(
      groupCode: "GRP001",
      serviceShift: "Evening",
      duration: "90",
      noOfMonth: 3,
      hourPrice: 25.0,
      visitsWeekly: 2,
      originalPrice: 147.2,
      noOfEmployee: 1,
      packageId: 2001,
      visitPrice: 50.0,
      packageName: "Aisian Package",
      vatPercentage: 15,
      packagePrice: 1200.0,
      discountPercentage: 10.0,
      priceAfterDiscount: 1080.0,
      vatAmount: 162,
      finalPrice: 1242.0,
    );

    if (!_promotionShown) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndShowPromotions(context);
      _promotionShown = true; // Mark as shown
    });
  }

    void navigateToCleaningWithOffer(PackageModel package, int shift) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HourlyServiceScreen(
            autoOpenPackage: package,
            autoOpenShift: shift,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildSideDrawer(context, ref, userNameAsync, loc, isArabic),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 100,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userNameAsync.when(
              data: (name) => Text(
                "${loc.welcome}, $name",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              loading: () => Text(loc.welcome),
              error: (_, __) => Text(loc.welcome),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              ref.read(localeNotifierProvider.notifier).setLocale(
                    isArabic ? const Locale('en') : const Locale('ar'),
                  );
              ref.invalidate(professionsProvider);
              ref.invalidate(sliderItemsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              if (hasUnconfirmedContracts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD), // light blue
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You have unconfirmed contracts",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              professionsAsync.when(
                data: (professions) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: professions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final profession = professions[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedProfessionProvider.notifier).state =
                            profession;

                        final hasDomestic = profession.hasDomesticPackage;
                        final serviceCount = profession.services.length;

                        if (hasDomestic) {
                          if (serviceCount > 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ServiceChoicePage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddressSelectionScreen(
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
                                builder: (_) => HourlyServiceScreen(
                                  professionId: profession.positionId,
                                  serviceId: profession.services[0].id,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(
                                    getFullImageUrl(profession.image)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              profession.positionName,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 130,
                child: sliderItemsAsync.when(
                  data: (sliderItems) => sliderItems.isEmpty
                      ? const Center(child: Text("No items available"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sliderItems.length,
                          itemBuilder: (context, index) {
                            final item = sliderItems[index];
                            final imageUrl = getFullImageUrl(item.imageUrl);
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[300],
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text("Error loading images: $e")),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.saving_packages,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 130,
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[400],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.drive_eta,
                                size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.privateDriver,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  loc.tenpercent,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 130,
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person_outline,
                                size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.housemaidoffer,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  loc.tenpercent,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
            // Avatar
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            // User name centered
            userNameAsync.when(
              data: (name) => Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              loading: () => const Text("..."),
              error: (_, __) => Text(loc.user),
            ),
            const SizedBox(height: 20),

            // Menu Items (Expanded to push logout to bottom)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.location_on,
                    title: loc.myAddresses,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddressDisplayScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: loc.myInformation,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyAccountScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.business,
                    title: loc.aboutCompany,
                    onTap: () async {
                      Navigator.pop(context);
                      const url = 'https://emdadhr.com/#/about';
                      final Uri uri = Uri.parse(url);

                      // Open the external link
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.store,
                    title: loc.companyBranches,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to branches
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.share,
                    title: loc.socialMediaLinks,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SocialMediaPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: loc.faq,
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FAQPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment,
                    title: loc.myContracts,
                    showNotification: hasUnconfirmedContracts,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/bookings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.lock,
                    title: loc.privacyPolicy,
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer
                      const url = 'https://emdadhr.com/#/PrivacyPolicy';
                      final Uri uri = Uri.parse(url);

                      // Open the external link
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  )
                ],
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDrawerItem(
                icon: Icons.logout,
                title: loc.logout,
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showNotification = false,
  }) {
    return ListTile(
      leading: Stack(
        alignment: Alignment.topRight,
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 22,
          ),
          if (showNotification)
            const Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(
                radius: 5,
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onTap: onTap,
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
      List<PromotionModel> promotions = await ApiService.getValidPromotions(cityName);
      
      if (promotions.isNotEmpty) {
        // Filter promotions that have valid image URLs
        List<PromotionModel> validPromotions = promotions
            .where((promotion) => promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
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



}
