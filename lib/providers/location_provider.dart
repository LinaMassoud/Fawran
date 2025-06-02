import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to store location string
final locationProvider = StateProvider<String>((ref) => 'جارٍ تحديد الموقع...');