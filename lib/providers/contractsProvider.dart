import 'package:fawran/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final contractsProvider =
    StateNotifierProvider<ContractsNotifier, ContractsState>(
        (ref) => ContractsNotifier(ref));

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
    final userId = ref.read(userIdProvider);
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

  Future<void> cancelHourlyContract(String contractId,
      {required bool isHourly}) async {
    try {
      await ApiService.cancelHourlyContract(
          contractId); // You'll define this in ApiService
      await fetchContracts(); // Refresh list
    } catch (e) {
      print("💥 Error cancelling contract: $e");
    }
  }
}
