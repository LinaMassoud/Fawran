import 'package:fawran/models/ProffesionModel.dart';
import 'package:fawran/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final professionsProvider = FutureProvider<List<ProfessionModel>>((ref) async {
  return await ApiService().fetchProfessions();
});


final selectedProfessionProvider = StateProvider<ProfessionModel?>((ref) => null);
