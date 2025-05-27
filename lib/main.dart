import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Generated localization file
import 'screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
    runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isArabic = false;  // Initially set to false (English)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      locale: isArabic ? const Locale('ar') : const Locale('en'),
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
      home: LoginScreen(isArabic: isArabic, onLanguageChanged: (bool? value) {
        setState(() {
          isArabic = value ?? false;  
        });
      }),
    );
  }
}
