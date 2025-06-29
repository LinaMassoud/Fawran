import 'dart:convert';

import 'package:fawran/models/Nationality.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final nationalitiesProvider = FutureProvider<List<Nationality?>>((ref) async {
  final selectedProfession = ref.watch(selectedProfessionProvider);
  final selectedAddress = ref.watch(selectedAddressProvider);

  if (selectedProfession == null || selectedAddress == null) {
    return [];
  }

  final professionId = selectedProfession.positionId;
  final cityCode = selectedAddress.cityCode;

  final url =
      'http://fawran.ddns.net:8080/ords/emdad/fawran/nationalities/$professionId/$cityCode';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    return data.map((json) => Nationality.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load nationalities');
  }
});

final selectedNationalityProvider = StateProvider<int?>((ref) => null);
