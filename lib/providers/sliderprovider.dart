import 'package:fawran/models/sliderItem.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Directly using the static method of ApiService to fetch slider items
final sliderItemsProvider = FutureProvider<List<SliderItem>>((ref) async {
  return ApiService.fetchSliderItems();  // Calling the static method directly
});