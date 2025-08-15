import 'dart:convert';

import 'package:fawran/models/Nationality.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/services/api_service.dart'; // Make sure this is correct
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nationalitiesProvider = FutureProvider<List<Nationality?>>((ref) async {
  final selectedProfession = ref.watch(selectedProfessionProvider);
  final selectedAddress = ref.watch(selectedAddressProvider);

  if (selectedProfession == null || selectedAddress == null) {
    return [];
  }

  final professionId = selectedProfession.positionId;
  final cityCode = selectedAddress.cityCode;


  final List<dynamic> data = await ApiService.fetchNationalities(
    professionId: professionId,
    cityCode: cityCode.toString(),
  );

  return data.map((json) => Nationality.fromJson(json)).toList();
});

final selectedNationalityProvider = StateProvider<Nationality?>((ref) => null);
