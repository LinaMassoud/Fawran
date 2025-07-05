import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart';
import 'package:fawran/OnboardingScreens/onboarding_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/screens/AuthCheckingScreen.dart';
import 'package:fawran/screens/bookings.dart';
import 'package:fawran/screens/home_screen.dart';
import 'package:fawran/screens/launchScreen.dart';
import 'package:fawran/screens/location_screen.dart';
import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/serviceChoice.dart';
import 'package:fawran/screens/userProfile.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import '../Fawran4Hours/fawran_services_display.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider); // Reactively watch locale

    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      home: const LaunchScreen(),
      routes: {
        // '/login' key routes to LoginScreen widget
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/bookings': (context) => const BookingsScreen(),
        '/location': (context) => const LocationScreen(),
        '/home':(contex)=> HomeScreen(),
        '/hourly':(context)=>CleaningServiceScreen(),
        '/selectAddress':(context)=>AddressSelectionScreen()


        // '/profile' key routes to UserProfileScreen widget
      },
    );
  }
}
