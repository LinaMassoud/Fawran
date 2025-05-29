// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.20.10.114:8080/ords/emdad/fawran';

  // API method for sign up
  Future<bool> signUp({
    required String userName,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': userName,
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'email': email,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (ex) {
      return false;
    }
  }

  // ✅ API method for login
  Future<Map<String, dynamic>?> login({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return token or user info
      } else {
        return null; // Login failed
      }
    } catch (ex) {
      return null;
    }
  }
}
