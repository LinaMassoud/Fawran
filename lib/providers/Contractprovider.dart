import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/services/api_service.dart';

class ContractsState {
  final List<Map<String, dynamic>> permanentContracts;
  final List<Map<String, dynamic>> hourlyContracts;
  final bool isLoading;
  final String? error;

  ContractsState({
    required this.permanentContracts,
    required this.hourlyContracts,
    required this.isLoading,
    this.error,
  });

  ContractsState copyWith({
    List<Map<String, dynamic>>? permanentContracts,
    List<Map<String, dynamic>>? hourlyContracts,
    bool? isLoading,
    String? error,
  }) {
    return ContractsState(
      permanentContracts: permanentContracts ?? this.permanentContracts,
      hourlyContracts: hourlyContracts ?? this.hourlyContracts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ContractsNotifier extends StateNotifier<ContractsState> {
  ContractsNotifier() : super(ContractsState(
    permanentContracts: [],
    hourlyContracts: [],
    isLoading: true,
    error: null,
  ));

  Future<void> fetchContracts(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final permanentContracts = await ApiService.fetchPermanentContracts(userId: userId);
      final hourlyContracts = await ApiService.fetchHourlyContracts(userId: userId);

      state = state.copyWith(
        permanentContracts: permanentContracts,
        hourlyContracts: hourlyContracts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching contracts: $e',
      );
    }
  }
}

final contractsProvider = StateNotifierProvider<ContractsNotifier, ContractsState>((ref) {
  return ContractsNotifier();
});
