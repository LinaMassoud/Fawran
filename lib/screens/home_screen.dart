import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/package_model.dart';
import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/providers/sliderprovider.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceChoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  String getFullImageUrl(String imagePath) {
    // Replace backslashes with forward slashes
    String sanitizedPath = imagePath.replaceAll('\\', '/');

    // Encode the URL to handle spaces, special characters, etc.
    String encodedPath = Uri.encodeFull(sanitizedPath);

    // Concatenate the base URL with the sanitized and encoded path
    final res = "http://fawran.ddns.net:8080/" + encodedPath;
    return res;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final location = ref.watch(locationProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final loc = AppLocalizations.of(context)!;
    final sliderItemsAsync = ref.watch(sliderItemsProvider);

    final examplePackage = PackageModel(
      groupCode: "GRP001",
      serviceShift: "Evening",
      duration: "90", // duration in minutes
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

    final isArabic = currentLocale.languageCode == 'ar';

    final List<String> services = [
      loc.service_driver,
      loc.service_full_time_maid,
      loc.service_maid_4h,
      loc.service_maid_8h,
      loc.service_driver,
      loc.service_full_time_maid,
      loc.service_maid_4h,
      loc.service_maid_8h
    ];

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
    );
    return Scaffold(
      backgroundColor: Colors.white,

      // Fixed Header
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 80,
        title: SizedBox(
          height: 80, // match toolbarHeight
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center vertically
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.home,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey, size: 18),
                  SizedBox(width: 4),
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
             ref.read(localeNotifierProvider.notifier).setLocale(isArabic ? const Locale('en') : const Locale('ar'));

                  ;
                  ref.invalidate(professionsProvider);

            },
          ),
        ],
      ),
      // Body Content
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: professionsAsync.when(
                data: (professions) {
                  return GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                    children: List.generate(professions.length, (index) {
                      final profession = professions[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(selectedProfessionProvider.notifier).state =
                              profession;
                          if (profession.services.length > 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ServiceChoicePage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddressSelectionScreen(
                                  header: profession.positionName,
                                ),
                              ),
                            );
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
                            SizedBox(height: 8),
                            Text(
                              profession.positionName,
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),

            // Services Grid
////horizontal slider
///
SizedBox(
  height: 130,
  child: sliderItemsAsync.when(
    data: (sliderItems) {
      if (sliderItems.isEmpty) {
        return Center(child: Text("No items available"));
      }
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sliderItems.length,
        itemBuilder: (context, index) {
          final item = sliderItems[index];
          final imageUrl = getFullImageUrl(item.imageUrl);
          print("Image URL: $imageUrl");  // Debug line

          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300], // Background color added
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                "Image ${index + 1}",  // Optional: Add text to help visualize each image
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    },
    loading: () => Center(child: CircularProgressIndicator()),
    error: (e, st) => Center(child: Text("Error loading images: $e")),
  ),
),

            SizedBox(height: 20),
            Text(
              loc.saving_packages,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),

            SizedBox(height: 20),

            // Promo Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 130, // ⬆️ Increased height
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.all(12), // ⬅️ Add inner padding
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(Icons.drive_eta,
                              size: 28, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.privateDriver,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                loc.tenpercent,
                                style: TextStyle(
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
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(Icons.person_outline,
                              size: 28, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.housemaidoffer,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                loc.tenpercent,
                                style: TextStyle(
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

            SizedBox(height: 80),
            // Phone / Email
          ],
        ),
      ),

      // Fixed Footer
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.home, color: Colors.black),
              Icon(Icons.search, color: Colors.grey),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                      context, '/bookings'); // Navigate to profile
                },
                child: Icon(Icons.calendar_month, color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                      context, '/profile'); // Navigate to profile
                },
                child: Icon(Icons.person, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
