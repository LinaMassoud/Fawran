import 'package:fawran/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool isLoading = true;
  bool showLocation = false;
  bool isPermissionGranted = false; // Flag to track permission state

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Method to fetch current location
 Future<void> _getCurrentLocation() async {
  try {
    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get the placemark (address)
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      localeIdentifier: 'en',
    );
    Placemark place = placemarks.first;

    final address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

    // Update state with the fetched address
    if (!mounted) return;
    ref.read(locationProvider.notifier).state = address;

    setState(() {
      isLoading = false;
      showLocation = true;
    });

    // Wait 2 seconds then navigate to HomeScreen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) =>  HomeScreen()),
    );
  } catch (e) {
    // Handle any errors that occur while fetching location
    if (!mounted) return;

    ref.read(locationProvider.notifier).state = "حدث خطأ أثناء جلب الموقع.";
    setState(() {
      isLoading = false;
      showLocation = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("تحديد الموقع"),
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    loc.fetching_location,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : showLocation
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.currentLocation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isLoading = true);
                            _getCurrentLocation();
                          },
                          child: const Text("إعادة المحاولة"),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
