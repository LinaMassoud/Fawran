import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart';
import 'package:fawran/models/package_model.dart';
import 'package:fawran/providers/auth_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceScreen.dart';
import 'package:flutter/material.dart';
import 'package:fawran/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_model.dart';
import 'package:fawran/Fawran4Hours/fawran_services_display.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final location = ref.watch(locationProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final loc = AppLocalizations.of(context)!;
    final examplePackage = PackageModel(
      groupCode: "GRP001",
      serviceShift: "Evening",
      duration: "90", // duration in minutes
      noOfMonth: 3,
      hourPrice: 25.0,
      visitsWeekly: 2,
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
    final List<String> imagePaths = [
      'assets/images/5.png',
      'assets/images/1.png',
      'assets/images/3.png',
      'assets/images/2.png',
      'assets/images/4.png',
    ];

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
              ref.read(localeProvider.notifier).state =
                  isArabic ? const Locale('en') : const Locale('ar');
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
                                  builder: (context) => CleaningServiceScreen(
                                        professionId: profession.positionId,
                                      )),
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
                                  image: AssetImage(
                                      'assets/images/${profession.positionId}.png'),
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
            SizedBox(height: 20),

            // Horizontal Slider (Colored Rectangles)
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      //navigateToCleaningWithOffer(examplePackage,1); // 👈 Call your function here with optional index
                    },
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.primaries[index % Colors.primaries.length]
                            .shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          loc.offer,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // New Horizontal Slider with Title "الخدمات الاكثر طلبا"
            Text(
              loc.top_requested,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 160, // taller to fit bigger image
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.accents[index % Colors.accents.length]
                          .withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          services[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Image.asset(
                          imagePaths[index],
                          height: 80, // Bigger image
                          width: 80,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  );
                },
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
                                'خدمة السائق الخاص\n7 أيام',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'خصم %10',
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
                                'عقد عاملة منزلية\n3 شهور',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'خصم %10',
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
              Icon(Icons.favorite, color: Colors.grey),
              Icon(Icons.person, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
