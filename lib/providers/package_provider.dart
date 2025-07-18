import 'dart:convert';
import 'package:fawran/models/domestic_package_model.dart';
import 'package:fawran/providers/address_provider.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:fawran/providers/nationality_provider.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'labour_provider.dart';


final selectedPackageProvider = StateProvider<DomesticPackageModel?>((ref) => null);
final packageProvider = FutureProvider<List<DomesticPackageModel>>((ref) async {
  final selectedProfession = ref.watch(selectedProfessionProvider);
  final selectedAddress = ref.watch(selectedAddressProvider);
  final selectedNationality = ref.watch(selectedNationalityProvider);

  if (selectedProfession == null) return [];

  final result = await ApiService.fetchPermPackages(
    positionId: selectedProfession.positionId,
    nationality: selectedNationality,
    cityCode: selectedAddress?.cityCode,
  );

  if (result['success'] == true) {
    final data = result['data'];
  final List<DomesticPackageModel> packages = List<DomesticPackageModel>.from(result['data']);
return packages;

  } else {
    throw Exception(result['message'] ?? 'Failed to load packages');
  }
});
