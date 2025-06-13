import 'package:fawran/l10n/app_localizations.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool showLocation = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final locationState = ref.read(locationProvider.notifier);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationState.state = "خدمة تحديد الموقع غير مفعّلة.";
      setState(() => isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationState.state = "تم رفض صلاحية الوصول إلى الموقع.";
        setState(() => isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      locationState.state =
          "تم رفض الصلاحية بشكل دائم. الرجاء تعديل الإعدادات.";
      setState(() => isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates (Arabic locale)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'ar',
      );

      Placemark place = placemarks.first;

      final address =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

      locationState.state = "$address";

      setState(() {
        isLoading = false;
        showLocation = true;
      });

      _controller.forward();
      await Future.delayed(const Duration(seconds: 2));
       if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      locationState.state = "حدث خطأ أثناء جلب الموقع: $e";
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
        final loc = AppLocalizations.of(context)!;


    return Scaffold(
      appBar: AppBar( automaticallyImplyLeading: false,title: const Text("تحديد الموقع")),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                   loc.fetching_location ,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
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
                ),
              ),
      ),
    );
  }
}
