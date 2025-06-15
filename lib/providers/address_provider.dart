import 'package:fawran/models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Static/mock list of addresses
final addressListProvider = Provider<List<Address>>((ref) {
  return [];
});

/// Holds the currently selected address
final selectedAddressProvider = StateProvider<Address?>((ref) => null);

final selectedCityProvider = StateProvider<String?>((ref) => null);
