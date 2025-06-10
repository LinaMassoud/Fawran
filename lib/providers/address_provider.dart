import 'package:fawran/models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Static/mock list of addresses
final addressListProvider = Provider<List<Address>>((ref) {
  return [
    Address(
      cardText: "Riyadh-Al Shohada-Building-Number:77-Apartment-Number:202-Floor No:2",
      addressId: 163,
      cityCode: "1",
      districtCode: "20",
    ),
    Address(
      cardText: "Riyadh-Al Shohada-Building-Number:77-Apartment-Number:202-Floor No:2",
      addressId: 164,
      cityCode: "1",
      districtCode: "20",
    ),
  ];
});

/// Holds the currently selected address
final selectedAddressProvider = StateProvider<Address?>((ref) => null);
