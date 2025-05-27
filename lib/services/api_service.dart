// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http ;

class ApiService {
  static const String _baseUrl = 'http://10.20.10.114:8080/ords/emdad/fawran'; 
  

  // API method for sign up
  Future<bool> signUp({
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;  // Sign-up successful
    } else {
      return false; // Sign-up failed
    }
  }
}
