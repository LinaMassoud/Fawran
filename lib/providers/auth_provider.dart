// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isLoading;
  final bool isSignedUp;
  final String errorMessage;

  AuthState({
    required this.isLoading,
    required this.isSignedUp,
    required this.errorMessage,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      isSignedUp: false,
      errorMessage: '',
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isSignedUp,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState.initial());

  Future<void> signUp({
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    bool success = await _apiService.signUp(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
    );

    if (success) {
      state = state.copyWith(isLoading: false, isSignedUp: true);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign up failed. Please try again.');
    }
  }
}

// Create a provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService());
});
