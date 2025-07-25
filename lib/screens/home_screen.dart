// Redesigned HomeScreen with logo and language button restored, slider and packages fixed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/sliderprovider.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/providers/userNameProvider.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/package_model.dart';

class RedesignedHomeScreen extends ConsumerWidget {
  const RedesignedHomeScreen({super.key});

  String getFullImageUrl(String imagePath) {
    String sanitizedPath = imagePath.replaceAll('\\', '/');
    String encodedPath = Uri.encodeFull(sanitizedPath);
    return "http://fawran.ddns.net:8080/$encodedPath";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sliderItemsAsync = ref.watch(sliderItemsProvider);
    final professionsAsync = ref.watch(professionsProvider);
    final location = ref.watch(locationProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B9BE4), Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets//images/1.png", width: 48, height: 48),
                  IconButton(
                    icon: const Icon(Icons.language, color: Colors.white),
                    onPressed: () {
                      // trigger language toggle logic here
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userNameAsync.when(
                          data: (name) => Text(
                            "${loc.welcome}, \$name",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          loading: () => Text(loc.welcome,
                              style: const TextStyle(color: Colors.white)),
                          error: (_, __) => Text(loc.welcome,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: sliderItemsAsync.when(
                  data: (items) => PageView.builder(
                    itemCount: items.length,
                    controller: PageController(viewportFraction: 0.85),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final imageUrl = getFullImageUrl(item.imageUrl);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: \$e")),
                ),
              ),
              const SizedBox(height: 20),
              Text("${loc.ourServices}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              professionsAsync.when(
                data: (professions) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: professions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final profession = professions[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.orange[300],
                        image: DecorationImage(
                          image: NetworkImage(getFullImageUrl(profession.image)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          profession.positionName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: \$e")),
              ),
              const SizedBox(height: 20),
              Text("${loc.saving_packages}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.blue[400],
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/maid_offer.png", width: 80),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("1 Month - ${loc.housemaidoffer}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text("-15%",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
