import 'package:fawran/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import '../services/api_service.dart';

final contractsProvider =
    StateNotifierProvider<ContractsNotifier, ContractsState>(
        (ref) => ContractsNotifier(ref));
  final _storage = FlutterSecureStorage();

class ContractsState {
  final List<Map<String, dynamic>> permanent;
  final List<Map<String, dynamic>> hourly;
  final bool isLoading;

  ContractsState({
    required this.permanent,
    required this.hourly,
    this.isLoading = false,
  });

  ContractsState copyWith({
    List<Map<String, dynamic>>? permanent,
    List<Map<String, dynamic>>? hourly,
    bool? isLoading,
  }) {
    return ContractsState(
      permanent: permanent ?? this.permanent,
      hourly: hourly ?? this.hourly,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ContractsNotifier extends StateNotifier<ContractsState> {
  final Ref ref;

  ContractsNotifier(this.ref)
      : super(ContractsState(permanent: [], hourly: [])) {
    fetchContracts();
  }

  Future<void> fetchContracts() async {
    state = state.copyWith(isLoading: true);
  final userId = await _storage.read(key: 'user_id') ?? '';
    if (userId == null) return;

    try {
      final permanent =
          await ApiService.fetchPermanentContracts(userId: userId);
      final hourly = await ApiService.fetchHourlyContracts(userId: userId);
      state = ContractsState(permanent: permanent, hourly: hourly);
    } catch (e) {
      print("💥 Error fetching contracts: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> cancelPermContract(String contractId,
      {required bool isHourly}) async {
    try {
      await ApiService.cancelPermContract(
          contractId); // You'll define this in ApiService
      await fetchContracts(); // Refresh list
    } catch (e) {
      print("💥 Error cancelling contract: $e");
    }
  }

  Future<void> cancelHourlyContract(String contractServiceId,
      {required bool isHourly}) async {
    try {
      await ApiService.cancelHourlyContract(
          contractServiceId); // You'll define this in ApiService
      await fetchContracts(); // Refresh list
    } catch (e) {
      print("💥 Error cancelling contract: $e");
    }
  }

  Future<Response> createPermanentContract(
      Map<String, dynamic> requestBody) async {
    try {
      final response = await ApiService.createPermanentContract(
        requestBody: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchContracts(); // Optional: Refresh local data
      } else {
        print(
            "❌ Failed to create contract: ${response.statusCode} - ${response.body}");
      }
      return response;
    } catch (e) {
      print("💥 Error creating permanent contract: $e");
      return Response("{error:${e}}", 404);
    }
  }
}
