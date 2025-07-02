import 'dart:async';

import 'package:fawran/generated/app_localizations.dart';
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

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled: $serviceEnabled");

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
              onPressed: () {
                Geolocator.openLocationSettings();
              },
              child: const Text("فتح الإعدادات"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء"),
            ),
          ],
        ),
      );

      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    print("Initial permission status: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("Requested permission status: $permission");
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        locationState.state = "تم رفض صلاحية الوصول إلى الموقع.";
        setState(() => isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      locationState.state =
          "تم رفض الصلاحية بشكل دائم. الرجاء تعديل الإعدادات.";
      setState(() => isLoading = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("الصلاحيات مرفوضة"),
          content: const Text("يجب تفعيل صلاحية الموقع من الإعدادات."),
          actions: [
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text("فتح الإعدادات"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء"),
            ),
          ],
        ),
      );

      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Timeout أثناء جلب الموقع.");
        },
      );

      print("Position: ${position.latitude}, ${position.longitude}");

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

      _controller.forward();
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e, stackTrace) {
      print("Location error: $e");
      print("Stack trace: $stackTrace");

      if (!mounted) return;

      String errorMessage;

      if (e is TimeoutException) {
        errorMessage = "انتهت المهلة أثناء محاولة جلب الموقع. حاول مرة أخرى.";
      } else if (e is PermissionDeniedException ||
          e.toString().contains("PERMISSION_DENIED")) {
        errorMessage = "صلاحية الموقع مرفوضة. يرجى التحقق من إعدادات التطبيق.";
      } else if (e.toString().contains("LocationServiceDisabledException")) {
        errorMessage = "خدمة الموقع غير مفعلة. يرجى تفعيلها من إعدادات الجهاز.";
      } else {
        errorMessage = "حدث خطأ غير متوقع أثناء جلب الموقع. حاول مرة أخرى.${e}";
      }

      locationState.state = errorMessage;

      setState(() {
        isLoading = false;
        showLocation = false;
      });
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
