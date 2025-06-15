import 'dart:convert';
import 'package:fawran/models/domestic_package_model.dart';
import 'package:fawran/providers/home_screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'labour_provider.dart';


final selectedPackageProvider = StateProvider<PackageModel?>((ref) => null);
final packageProvider = FutureProvider<List<PackageModel>>((ref) async {
  final selectedprofession = ref.watch(selectedProfessionProvider);
  if (selectedprofession == null) return [];

  final response = await http.get(Uri.parse(
    'http://10.20.10.114:8080/ords/emdad/fawran/domestic_packages/${selectedprofession.positionId}',
  ));

  if (response.statusCode == 200) {
    final items = jsonDecode(response.body) as List;
    return items.map((e) => PackageModel.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load packages');
  }
});
