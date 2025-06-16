import 'dart:convert';
import 'package:fawran/models/ProffesionModel.dart';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';

class ApiService {
  static const String _baseUrl = 'http://10.20.10.114:8080/ords/emdad/fawran';
  static const String packagesBaseUrl = 'http://10.20.10.114:8080/ords/emdad/fawran/service/packages';

  // Sign up API
  Future<bool> signUp({
    required String userName,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');

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

  // Login API
  Future<Map<String, dynamic>?> login({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (ex) {
      return null;
    }
  }

  // ✅ OTP Verification API
  Future<bool> verifyCode({
    required String username,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/verify');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'otp': otp,
        }),
      );

      return response.statusCode == 200;
    } catch (ex) {
      return false;
    }
  }
  static Future<List<PackageModel>> fetchPackages({
    required int serviceId,
    required String groupCode,
    int? serviceShift,
    int jobId = 251,
  }) async {
    try {
      String apiUrl;
      // For Fawran 4 Hours (service_id=1), include service_shift parameter
      if (serviceId == 1 && serviceShift != null) {
        apiUrl = '$packagesBaseUrl?service_id=$serviceId&group_code=$groupCode&service_shift=$serviceShift&job_id=$jobId';
      } else {
        // For Fawran 8 Hours (service_id=21), no service_shift parameter
        apiUrl = '$packagesBaseUrl?service_id=$serviceId&group_code=$groupCode&job_id=$jobId';
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Fix malformed JSON before parsing
        String jsonString = response.body;
        
        // Replace empty discount_percentage values
        jsonString = jsonString.replaceAll('"discount_percentage":,', '"discount_percentage":0,');
        jsonString = jsonString.replaceAll('"discount_percentage":"",', '"discount_percentage":0,');
        
        // Also fix any other potential empty numeric fields
        jsonString = jsonString.replaceAll('":,', '":0,');
        jsonString = jsonString.replaceAll('":",', '":0,');
        
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> packagesJson = data['packages'];
        
        return packagesJson.map((json) => PackageModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load packages. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading packages: $e');
    }
  }

  static Future<List<PackageModel>> fetchEastAsiaPackages({
    required int serviceId,
    int? serviceShift,
  }) async {
    return fetchPackages(
      serviceId: serviceId,
      groupCode: '2',
      serviceShift: serviceShift,
    );
  }

  static Future<List<PackageModel>> fetchAfricanPackages({
    required int serviceId,
    int? serviceShift,
  }) async {
    return fetchPackages(
      serviceId: serviceId,
      groupCode: '3',
      serviceShift: serviceShift,
    );
  }
  Future<List<ProfessionModel>> fetchProfessions() async {
  final url = Uri.parse('$_baseUrl/home/professions');

  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProfessionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch professions. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching professions: $e');
  }
}

Future<List<dynamic>> fetchNationalities({
  required int professionId,
  required String cityCode,
}) async {
  final url = Uri.parse('$_baseUrl/nationalities/$professionId/$cityCode');

  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to fetch nationalities. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching nationalities: $e');
  }
}




}

