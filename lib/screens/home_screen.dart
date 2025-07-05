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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 100,
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
                        ref.read(selectedProfessionProvider.notifier).state = profession;
                        if (profession.services.length > 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ServiceChoicePage()),
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
                                image: NetworkImage(getFullImageUrl(profession.image)),
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error loading images: $e")),
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
              const SizedBox(height: 100), // Enough space for BottomAppBar
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.home, color: Colors.black),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/bookings'),
                  child: const Icon(Icons.calendar_month, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}