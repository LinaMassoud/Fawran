import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/package_model.dart';
import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/providers/sliderprovider.dart';
import 'package:fawran/providers/userNameProvider.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceChoice.dart';
import 'package:fawran/screens/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/screens/address_display_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final location = ref.watch(locationProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final sliderItemsAsync = ref.watch(sliderItemsProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final loc = AppLocalizations.of(context)!;
    final isArabic = currentLocale.languageCode == 'ar';
    
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

    void navigateToCleaningWithOffer(PackageModel package, int shift) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CleaningServiceScreen(
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
                                builder: (_) => CleaningServiceScreen(
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

  Widget _buildSideDrawer(BuildContext context, WidgetRef ref, 
    AsyncValue<String> userNameAsync, AppLocalizations loc, bool isArabic) {
  final phoneNumberAsync = ref.watch(phoneNumberProvider);
  return Drawer(
    child: Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD), // Light blue background similar to screenshot
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              children: [
                // User avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB8B8B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                // User name
                userNameAsync.when(
                data: (name) => Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    phoneNumberAsync.when(
                      data: (phoneNumber) => Text(
                        phoneNumber.isEmpty ? loc.noPhoneNumber : phoneNumber,
                        style: const TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      loading: () => Text(
                        loc.loading,
                        style: const TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 14,
                        ),
                      ),
                      error: (_, __) => Text(
                        loc.noPhoneNumber,
                        style: const TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => Text(
                  loc.loading,
                  style: const TextStyle(color: Color(0xFF2C3E50)),
                ),
                error: (_, __) => Text(
                  loc.user,
                  style: const TextStyle(color: Color(0xFF2C3E50)),
                ),
              ),
              ],
            ),
          ),
          
          // Menu Items
          _buildDrawerItem(
            context: context,
            icon: Icons.location_on,
            iconColor: const Color(0xFFFF9800),
            title: loc.myAddresses,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressDisplayScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.person_outline,
            iconColor: const Color(0xFFFF9800),
            title: loc.myInformation,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserDetailsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
          context: context,
          icon: Icons.assignment,
          iconColor: const Color(0xFFFF9800),
          title: loc.myContracts,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/bookings');
          },
        ),
          _buildDrawerItem(
            context: context,
            icon: Icons.business,
            iconColor: const Color(0xFFFF9800),
            title: loc.aboutCompany,
            onTap: () {
              Navigator.pop(context);
              // Navigate to About Company screen
            },
          ),

          _buildDrawerItem(
            context: context,
            icon: Icons.support_agent,
            iconColor: const Color(0xFFFF9800),
            title: loc.ticketsSupport,
            onTap: () {
              Navigator.pop(context);
              // Navigate to Support screen
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.store,
            iconColor: const Color(0xFFFF9800),
            title: loc.companyBranches,
            onTap: () {
              Navigator.pop(context);
              // Navigate to Company Branches screen
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.share,
            iconColor: const Color(0xFFFF9800),
            title: loc.socialMediaLinks,
            onTap: () {
              Navigator.pop(context);
              // Navigate to Social Media screen
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.help_outline,
            iconColor: const Color(0xFFFF9800),
            title: loc.faq,
            onTap: () {
              Navigator.pop(context);
              // Navigate to FAQ screen
            },
          ),
          
          // Logout Button - now part of the scrollable list
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Color(0xFFE74C3C),
                size: 24,
              ),
              title: Text(
                loc.logout,
                style: const TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, ref);
              },
            ),
          ),
        ],
      ),
    ),
  )
  );
}

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
    );
  }

  Future<void> _logout(WidgetRef ref) async {
    const storage = FlutterSecureStorage();
    
    // Clear secure storage
    await storage.deleteAll();

    // Call logout from authProvider
    ref.read(authProvider.notifier).logout(ref);
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