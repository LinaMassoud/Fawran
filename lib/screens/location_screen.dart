import 'dart:async';
import 'dart:convert';

import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/location_provider.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool showLocation = false;
  bool isPermissionGranted = false; // Flag to track permission state

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Completer<void>? _locationRequestCompleter;

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

  Future<void> fetchNearbyPlaces(Position position) async {
    final apiKey = dotenv.env['API_KEY'];
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=1000&type=point_of_interest&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      if (results.isNotEmpty) {
        final nearestPlaceName = results.first['name'] as String;

        if (!mounted) return;
        ref.read(locationProvider.notifier).state =
            'أقرب مكان إليك: $nearestPlaceName';

        setState(() {
          isLoading = false;
          showLocation = false;
        });
      } else {
        throw Exception("لم يتم العثور على أماكن قريبة.");
      }
    } else {
      throw Exception("فشل الاتصال بخدمة Google Places.");
    }
  }

Future<void> _getCurrentLocation() async {
  // If there's already an ongoing location request, wait for it to finish
  if (_locationRequestCompleter != null && !_locationRequestCompleter!.isCompleted) {
     await _locationRequestCompleter!.future;
    print("Location request is already in progress, waiting for it to complete...");
  } else {
    // Create a new location request if no request is in progress
    _locationRequestCompleter = Completer<void>();
  }

  final locationState = ref.read(locationProvider.notifier);

  try {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      locationState.state = "خدمة تحديد الموقع غير مفعّلة.";
      setState(() => isLoading = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("خدمة الموقع موقفة"),
          content: const Text("يرجى تفعيل خدمة الموقع من إعدادات الجهاز."),
          actions: [
            TextButton(
              onPressed: () => Geolocator.openLocationSettings(),
              child: const Text("فتح الإعدادات"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء"),
            ),
          ],
        ),
      );
      return;
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        locationState.state = "تم رفض صلاحية الوصول إلى الموقع.";
        setState(() => isLoading = false);
        return;
      }
    }

    // Handle permanently denied permissions
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      locationState.state = "تم رفض الصلاحية بشكل دائم. الرجاء تعديل الإعدادات.";
      setState(() => isLoading = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("الصلاحيات مرفوضة"),
          content: const Text("يجب تفعيل صلاحية الموقع من الإعدادات."),
          actions: [
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: const Text("فتح الإعدادات"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إلغاء"),
            ),
          ],
        ),
      );
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception("Timeout أثناء جلب الموقع.");
      },
    );

    // Fetch the address (placemark) for the coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      localeIdentifier: 'en',
    );

    Placemark place = placemarks.first;
    final address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

    if (!mounted) return;
    locationState.state = address;

    setState(() {
      isLoading = false;
      showLocation = true;
    });

    // Start the fade transition animation
    _controller.forward();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } catch (e, stackTrace) {
    print("Location error: $e");
    print("Stack trace: $stackTrace");

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } on PermissionRequestInProgressException catch (_) {
      print("Permission request in progress. Skipping fallback.");
      return;
    } catch (e) {
      print("Error fetching last known position: $e");
    }

    if (lastKnown != null) {
      try {
        await fetchNearbyPlaces(lastKnown);

        if (!mounted) return;
        setState(() {
          isLoading = false;
          showLocation = true;
        });

        _controller.forward();
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return;
      } catch (e) {
        print("Failed to fetch from last known: $e");
      }
    }

    if (!mounted) return;

    String errorMessage;
    if (e is TimeoutException) {
      errorMessage = "انتهت المهلة أثناء محاولة جلب الموقع. حاول مرة أخرى.";
    } else if (e.toString().contains("PERMISSION_DENIED")) {
      errorMessage = "صلاحية الموقع مرفوضة. تحقق من إعدادات التطبيق.";
    } else if (e.toString().contains("LocationServiceDisabledException")) {
      errorMessage = "خدمة الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.";
    } else {
      errorMessage = "حدث خطأ غير متوقع أثناء جلب الموقع. حاول مرة أخرى.\n$e";
    }

    locationState.state = errorMessage;
    setState(() {
      isLoading = false;
      showLocation = false;
    });
  } finally {
    // Complete the location request when done
    _locationRequestCompleter?.complete();
    _locationRequestCompleter = null;
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
                ? FadeTransition(
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
