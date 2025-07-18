import 'dart:convert';

import 'package:fawran/models/Nationality.dart';
import 'package:fawran/models/ProffesionModel.dart';
import 'package:fawran/models/labour.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/nationality_provider.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final selectedLaborerProvider = StateProvider<Laborer?>((ref) => null);

final laborersProvider = FutureProvider<List<Laborer>>((ref) async {
  final profession = ref.watch(selectedProfessionProvider);
  final nationality = ref.watch(selectedNationalityProvider);

  if (profession == null || nationality == null) return [];

  return await ApiService.fetchLaborers(
    professionId: profession.positionId,
    nationality: nationality,
  );
});