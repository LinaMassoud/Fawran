// providers/auth_provider.dart
import 'package:fawran/providers/contractsProvider.dart';
import 'package:fawran/providers/userNameProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

final userIdProvider = StateProvider<int?>((ref) => null);
  final _storage = FlutterSecureStorage();

class AuthState {
  final bool isLoading;
  bool isVerified = true;
  final bool isSignedUp;
  final bool isLoggedIn;
  final String errorMessage;
  final String? token;
  final String? refreshToken;
  final int? userId;

  AuthState({
    required this.isLoading,
    required this.isSignedUp,
    required this.isLoggedIn,
    required this.errorMessage,
    required this.isVerified,
    this.token,
    this.refreshToken,
    this.userId,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      isVerified: true,
      isSignedUp: false,
      isLoggedIn: false,
      errorMessage: '',
      token: null,
      refreshToken: null,
      userId: null,
    );
  }

  AuthState copyWith(
      {bool? isLoading,
      bool? isSignedUp,
      bool? isLoggedIn,
      String? errorMessage,
      String? token,
      String? refreshToken,
      int? userId,
      bool? isVerified = true}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;

  AuthNotifier(this._ref, this._apiService) : super(AuthState.initial());

  void _setUserId(int? userId) {
    _ref.read(userIdProvider.notifier).state = userId;
  }

  Future<void> signUp({
    required String userName,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
    required String nationalId,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', isSignedUp: false);

    final response = await _apiService.signUp(
        userName: userName,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        nationalId: nationalId);

    if (response != null && response['error'] != null) {
      state = state.copyWith(
          isLoading: false, errorMessage: response['error'], isSignedUp: false);
    } else if (response != null && response['error'] == null) {
      state = state.copyWith(isLoading: false, isSignedUp: true);
      final userId = response['user_id'];
      _setUserId(userId);
    } else {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Sign up failed. Please try again.');
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
    required WidgetRef ref
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', isSignedUp: false);

    final result =
        await _apiService.login(phoneNumber: phoneNumber, password: password);

    if (result != null) {
      // Check if the response contains an error message
      if (result['error'] != null) {
        String errorMessage = result['error'];

        // Check if the error message contains 'not verified'
        if (errorMessage.contains('not verified')) {
          final userId = result['user_id'];
          _setUserId(userId);

          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            isSignedUp: false,
            isVerified: false,
            errorMessage: errorMessage, // Set the exact error message here
          );
                ref.invalidate(userNameProvider);
        } else {
          // For other errors, simply show the error message
          state = state.copyWith(
            isLoading: false,
            errorMessage: errorMessage,
          );
        }
      }
      // Check for a successful login
      else if (result['token'] != null &&
          result['refresh_token'] != null &&
          result['user_id'] != null) {
        final token = result['token'];
        final refreshToken = result['refresh_token'];
        final userId = result['user_id'];

        _setUserId(userId);
      ref.invalidate(userNameProvider);
      ref.invalidate(contractsProvider);
        // Optionally store token and refreshToken in secure storage
        // await _secureStorage.write(key: 'token', value: token);
        // await _secureStorage.write(key: 'refresh_token', value: refreshToken);

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isSignedUp: false,
          token: token,
          refreshToken: refreshToken,
          userId: userId,
          isVerified: true, // User is verified after login success
        );
      }
      // If the response is unexpected (i.e., no token or refresh_token)
      else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check your credentials.',
        );
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }
void logout(WidgetRef ref) {
  _storage.deleteAll();
  _setUserId(null);
  state = AuthState.initial();
}

  clearStateError() {
    state = state.copyWith(errorMessage: '');
  }
}

// Create a provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ApiService());
});
