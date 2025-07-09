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
Future<void> _getCurrentLocation({bool isRetry = false}) async {
  if (_locationRequestCompleter != null && !_locationRequestCompleter!.isCompleted) {
    print("Another location request is in progress. Waiting...");
    await _locationRequestCompleter!.future;

    if (!isRetry) {
      await _getCurrentLocation(isRetry: true);
    }
    return;
  }

  _locationRequestCompleter = Completer<void>();
  final locationState = ref.read(locationProvider.notifier);

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      locationState.state = "خدمة تحديد الموقع غير مفعّلة.";
      setState(() => isLoading = false);
      await _showLocationSettingsDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      locationState.state = "صلاحية الوصول إلى الموقع مرفوضة. تحقق من الإعدادات.";
      setState(() => isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException("Timeout أثناء جلب الموقع."),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      localeIdentifier: 'en',
    );

    final address = "${placemarks.first.street}, "
        "${placemarks.first.locality}, "
        "${placemarks.first.administrativeArea}, "
        "${placemarks.first.country}";

    if (!mounted) return;
    locationState.state = address;

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
  } catch (e, stackTrace) {
    print("Error: $e");
    print("Stack: $stackTrace");

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
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
      }
    } catch (err) {
      print("Failed to use last known location: $err");
    }

    if (!mounted) return;

    final errorMessage = e is TimeoutException
        ? "انتهت المهلة أثناء محاولة جلب الموقع. حاول مرة أخرى."
        : "حدث خطأ غير متوقع أثناء جلب الموقع. حاول مرة أخرى.\n$e";

    locationState.state = errorMessage;
    setState(() {
      isLoading = false;
      showLocation = false;
    });
  } finally {
    _locationRequestCompleter?.complete();
    _locationRequestCompleter = null;
  }
}
Future<void> _showLocationSettingsDialog() async {
  if (!mounted) return;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("خدمة الموقع غير مفعّلة"),
      content: const Text("يرجى تفعيل خدمة تحديد الموقع من إعدادات الجهاز."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("إلغاء"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await Geolocator.openLocationSettings();
          },
          child: const Text("فتح الإعدادات"),
        ),
      ],
    ),
  );
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
