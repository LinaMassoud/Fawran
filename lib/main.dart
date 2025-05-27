import 'package:flutter/material.dart';
import 'package:fawran/Fawran4Hours/cleaning_service_screen.dart'; // Import your cleaning service screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleaning Service App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CleaningServiceScreen(), // Changed to use CleaningServiceScreen
      debugShowCheckedModeBanner: false, // Optional: removes debug banner
    );
  }
}