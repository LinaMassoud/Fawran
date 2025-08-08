// newhome.dart

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

                      const Text(
                        'Welcome on board!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A variety of services at your fingertips — ready to start?',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Slider
                      sliderItemsAsync.when(
                        data: (items) {
                          return SizedBox(
                            height: 150,
                            child: PageView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final imageUrl = getFullImageUrl(item.imageUrl);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error loading slider: $e'),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Our Services',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0C1A30),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Professions
                      professionsAsync.when(
                        data: (professions) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: professions.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final profession = professions[index];
                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(selectedProfessionProvider.notifier)
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
                                          builder: (_) => HourlyServiceScreen(
                                            professionId: profession.positionId,
                                            serviceId:
                                                profession.services[0].id,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          getFullImageUrl(profession.image)),
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
                                    child: Text(
                                      profession.positionName,
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error loading services: $e'),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Special Packages',
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
                        child: const Center(child: Text('Coming soon...')),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.language, color: Colors.blue),
                  onPressed: () {
                    final localeNotifier =
                        ref.read(localeNotifierProvider.notifier);
                    final currentLocale = ref.read(localeNotifierProvider);

                    if (currentLocale.languageCode == 'ar') {
                      localeNotifier.setLocale(const Locale('en'));
                    } else {
                      localeNotifier.setLocale(const Locale('ar'));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            // Menu Items and Logout (unchanged)...
          ],
        ),
      ),
    );
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
