// providers/auth_provider.dart
import 'package:flutter/material.dart'; // ✅ Import for Locale
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));


class AuthState {
  final bool isLoading;
  final bool isSignedUp;
  final bool isLoggedIn;
  final String errorMessage;
  final String? token; // Optional, if API returns a token

  AuthState({
    required this.isLoading,
    required this.isSignedUp,
    required this.isLoggedIn,
    required this.errorMessage,
    this.token,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      isSignedUp: false,
      isLoggedIn: false,
      errorMessage: '',
      token: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isSignedUp,
    bool? isLoggedIn,
    String? errorMessage,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState.initial());

  Future<void> signUp({
    required String userName,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    bool success = await _apiService.signUp(
      userName:userName,
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

Future<void> login({
  required String phoneNumber,
  required String password,
}) async {
  state = state.copyWith(isLoading: true, errorMessage: '');

  final result = await _apiService.login(phoneNumber: phoneNumber, password: password);

  if (result != null && result['token'] != null) {
    final token = result['token'];
    // Optionally store token in secure storage
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      token: token,
    );
  } else {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Login failed. Please check your credentials.',
    );
  }
}

}

// Create a provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService());
});
