import 'dart:convert';

import 'package:fawran/models/Nationality.dart';
import 'package:fawran/models/ProffesionModel.dart';
import 'package:fawran/models/labour.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;


final selectedLaborerProvider = StateProvider<Laborer?>((ref) => null);

final laborersProvider = FutureProvider<List<Laborer>>((ref) async {
  final profession = ref.watch(selectedProfessionProvider);
  if (profession == null) return [];

  final response = await http.get(Uri.parse(
      'http://10.20.10.114:8080/ords/emdad/fawran/available-domestic-workers/${profession.positionId}'));

  if (response.statusCode == 200) {
    final items = jsonDecode(response.body)as List;
    final m = items.map((e) => Laborer.fromJson(e)).toList();
    return m;
  } else {
    throw Exception('Failed to load laborers');
  }
});
