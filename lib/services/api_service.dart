import 'dart:convert';
import 'package:fawran/models/ProffesionModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';
import 'dart:io'; // for SocketException
import 'dart:async'; // for TimeoutException
import 'package:intl/intl.dart';

class ApiService {
  static const String _baseUrl = 'http://10.20.10.114:8080/ords/emdad/fawran';
  static const String packagesBaseUrl =
      'http://10.20.10.114:8080/ords/emdad/fawran/service/packages';
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final FlutterSecureStorage _secureStorage2 = FlutterSecureStorage();

  // Sign up API
  Future<Map<String, dynamic>?> signUp({
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

      if (response.statusCode == 200) {
        final result = safeJsonDecode(response.body);
        return result;
      } else {
        return null;
      }
    } catch (ex) {
      return null;
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
        final responseData = json.decode(response.body);

        // Save all relevant fields to secure storage
        final fieldsToStore = {
          'token': responseData['token'],
          'refresh_token': responseData['refresh_token'],
          'user_id': responseData['user_id'].toString(),
          'phone_number': responseData['phone_number'],
          'first_name': responseData['first_name'],
          'middle_name': responseData['middle_name'],
          'last_name': responseData['last_name'],
          'username': responseData['username'],
        };

        for (var entry in fieldsToStore.entries) {
          if (entry.value != null) {
            await _secureStorage.write(key: entry.key, value: entry.value);
          }
        }

        return responseData;
      } else {
        return null;
      }
    } catch (ex) {
      return null;
    }
  }

  // OTP Verification API

  Future<bool> verifyCode({
    required String userid,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userid,
          'otp': otp,
        }),
      );

      // Always check the status code first
      if (response.statusCode != 200) {
        return false; // Return false for any non-200 status code
      }

      // Check if the response body contains an error message
      final Map<String, dynamic> responseBody = json.decode(response.body);

      // If there's an error key in the response, return false
      if (responseBody.containsKey('error')) {
        print(
            'Error: ${responseBody['error']}'); // Optional: log the error message
        return false;
      }

      // If no error found and the status code is 200, assume success
      return true;
    } catch (ex) {
      print('Error: $ex'); // Log any exceptions that occur during the request
      return false;
    }
  }

  static Future<List<dynamic>> fetchProfessionsHourly() async {
    try {
      final url = '$_baseUrl/home/professions';

      final token = await _secureStorage2.read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        return decodedData;
      } else {
        throw Exception(
            'Failed to load professions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading professions: $e');
    }
  }

  static Future<List<PackageModel>> fetchServicePackages({
    required int professionId,
    required int serviceId,
  }) async {
    try {
      final url = '$_baseUrl/service_packages/$professionId/$serviceId';

      final token = await _secureStorage2.read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        String jsonString = response.body;

        // Comprehensive null value handling
        jsonString = jsonString.replaceAll(
            '"discount_percentage":null', '"discount_percentage":0');
        jsonString = jsonString.replaceAll(
            '"discount_percentage":"null"', '"discount_percentage":0');
        jsonString = jsonString.replaceAll(
            '"discount_percentage":,', '"discount_percentage":0,');
        jsonString = jsonString.replaceAll(
            '"discount_percentage":"",', '"discount_percentage":0,');
        jsonString =
            jsonString.replaceAll('"no_of_weeks":null', '"no_of_weeks":0');
        jsonString =
            jsonString.replaceAll('"no_of_weeks":"null"', '"no_of_weeks":0');
        jsonString =
            jsonString.replaceAll('"hour_price":null', '"hour_price":0');
        jsonString =
            jsonString.replaceAll('"hour_price":"null"', '"hour_price":0');

        // Handle any other null values that might cause issues
        jsonString = jsonString.replaceAll(':null,', ':0,');
        jsonString = jsonString.replaceAll(':null}', ':0}');
        jsonString = jsonString.replaceAll(':"null",', ':0,');
        jsonString = jsonString.replaceAll(':"null"}', ':0}');

        final List<dynamic> packagesJson = json.decode(jsonString);

        List<PackageModel> packages = [];
        for (int i = 0; i < packagesJson.length; i++) {
          var packageData = packagesJson[i];
          try {
            PackageModel package = PackageModel.fromJson(packageData);
            packages.add(package);
          } catch (e) {
            // Continue with other packages instead of throwing
          }
        }

        return packages;
      } else {
        throw Exception(
            'Failed to load service packages. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading service packages: $e');
    }
  }

  // Fetch country groups by service ID
  static Future<List<dynamic>> fetchCountryGroups(
      {required int serviceId}) async {
    try {
      final url = '$_baseUrl/country_groups/$serviceId';

      final token = await _secureStorage2.read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        return decodedData;
      } else {
        throw Exception(
            'Failed to load country groups. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading country groups: $e');
    }
  }

  static Future<List<dynamic>> fetchServices(
      {required int professionId}) async {
    try {
      final url = '$_baseUrl/home/professions';

      final token = await _secureStorage2.read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Find the selected position and extract its services
        for (var position in data) {
          if (position['position_id'] == professionId) {
            final List<dynamic> servicesList = position['services'] ?? [];
            return servicesList;
          }
        }

        // If profession not found, return empty list
        return [];
      } else {
        throw Exception(
            'Failed to load services. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

  // Fetch service shifts by service ID
  static Future<List<dynamic>> fetchServiceShifts(
      {required int serviceId}) async {
    try {
      final url = '$_baseUrl/service_shifts/$serviceId';

      final token = await _secureStorage2.read(key: 'token');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        return decodedData;
      } else {
        throw Exception(
            'Failed to load service shifts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading service shifts: $e');
    }
  }

  static Future<List<PackageModel>> fetchPackagesByGroup({
    required int professionId,
    required int serviceId,
    required String groupCode,
    int? serviceShift,
  }) async {
    try {
      // First get all packages for the service
      final allPackages = await fetchServicePackages(
        professionId: professionId,
        serviceId: serviceId,
      );

      // Filter by group code and service shift if provided
      List<PackageModel> filteredPackages = [];

      for (int i = 0; i < allPackages.length; i++) {
        PackageModel package = allPackages[i];
        bool matchesGroup =
            package.groupCode.toString() == groupCode.toString();
        bool matchesShift;

        if (serviceShift == null) {
          matchesShift = true;
        } else {
          // Convert both to int for comparison to handle string/int mismatches
          int? packageShift = int.tryParse(package.serviceShift.toString());
          int? targetShift = int.tryParse(serviceShift.toString());
          matchesShift = packageShift == targetShift;
        }

        if (matchesGroup && matchesShift) {
          filteredPackages.add(package);
        }
      }

      return filteredPackages;
    } catch (e) {
      throw Exception('Error loading packages by group: $e');
    }
  }

  static Future<Map<String, dynamic>?> calculatePackagePrice({
    required int serviceId,
    required int duration,
    required String groupCode,
    required int numberOfWeeks,
    required int numberOfVisits,
    required int shiftId,
    required int numberOfWorkers,
  }) async {
    try {
      final url = '$_baseUrl/calculate-package-price';
      final token = await _secureStorage2.read(key: 'token');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
        body: json.encode({
          'service_id': serviceId,
          'duration': duration,
          'group_code': groupCode,
          'number_of_weeks': numberOfWeeks,
          'number_of_visits': numberOfVisits,
          'shift_id': shiftId,
          'number_of_workers': numberOfWorkers,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to calculate price. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calculating package price: $e');
    }
  }


  static Future<Map<String, dynamic>?> validateWorkersHourly({
  required int positionId,
  required String nationalityId,
  required int numWorkers,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  print('🔍 [validateWorkersHourly] Starting validation...');
  print('📊 [validateWorkersHourly] Input parameters:');
  print('   - positionId: $positionId');
  print('   - nationalityId: $nationalityId');
  print('   - numWorkers: $numWorkers');
  print('   - startDate: ${DateFormat('yyyy-MM-dd').format(startDate)}');
  print('   - endDate: ${DateFormat('yyyy-MM-dd').format(endDate)}');
  
  try {
    final url = '$_baseUrl/validate-workers';
    print('🌐 [validateWorkersHourly] API URL: $url');
    
    final token = await _secureStorage2.read(key: 'token');
    print('🔐 [validateWorkersHourly] Token retrieved: ${token != null ? 'Yes (${token.length} chars)' : 'No'}');
    

    final requestBody = {
      "position_id": positionId,
      "sector_type": "H", // Always H for Hourly services
      "nationality_id": nationalityId,
      "num_workers": numWorkers,
      "start_date": DateFormat('yyyy-MM-dd').format(startDate),
      "end_date": DateFormat('yyyy-MM-dd').format(endDate),
    };
    
    print('📦 [validateWorkersHourly] Request body:');
    print('   ${json.encode(requestBody)}');
    
    print('🚀 [validateWorkersHourly] Sending POST request...');
    final stopwatch = Stopwatch()..start();
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'token': token ?? '',
      },
      body: json.encode(requestBody),
    ).timeout(Duration(seconds: 30));
    
    stopwatch.stop();
    print('⏱️ [validateWorkersHourly] Request completed in ${stopwatch.elapsedMilliseconds}ms');
    print('📡 [validateWorkersHourly] Response status code: ${response.statusCode}');
    print('📡 [validateWorkersHourly] Response headers: ${response.headers}');
    print('📡 [validateWorkersHourly] Response body length: ${response.body.length} chars');
    
    

    if (response.statusCode == 200) {
      print('✅ [validateWorkersHourly] Request successful');
      final responseData = json.decode(response.body);
      print('🎯 [validateWorkersHourly] Parsed response data type: ${responseData.runtimeType}');
      print('📋 [validateWorkersHourly] Response data intially: $responseData');
      
      if (responseData is Map<String, dynamic>) {
        print('📋 [validateWorkersHourly] Response data: $responseData');
        print('📋 [validateWorkersHourly] Response keys: ${responseData.keys.toList()}');
        print('✅ [validateWorkersHourly] Validation completed successfully');
        return responseData;
      } else {
        print('⚠️ [validateWorkersHourly] Unexpected response data type: ${responseData.runtimeType}');
        return responseData as Map<String, dynamic>?;
      }
    } else {
      print('❌ [validateWorkersHourly] Request failed with status ${response.statusCode}');
      print('❌ [validateWorkersHourly] Error response body: ${response.body}');
      throw Exception('Failed to validate workers. Status code: ${response.statusCode}');
    }
  } on SocketException catch (e) {
    print('🌐 [validateWorkersHourly] SocketException caught: $e');
    print('❌ [validateWorkersHourly] No internet connection');
    throw Exception('No internet connection');
  } on TimeoutException catch (e) {
    print('⏰ [validateWorkersHourly] TimeoutException caught: $e');
    print('❌ [validateWorkersHourly] Request timeout after 30 seconds');
    throw Exception('Request timeout');
  } on FormatException catch (e) {
    print('📄 [validateWorkersHourly] FormatException caught: $e');
    print('❌ [validateWorkersHourly] Failed to parse JSON response');
    throw Exception('Invalid JSON response: $e');
  } catch (e, stackTrace) {
    print('💥 [validateWorkersHourly] Unexpected error caught: $e');
    print('📚 [validateWorkersHourly] Stack trace: $stackTrace');
    throw Exception('Error validating workers: $e');
  }
}

  @Deprecated("Old")
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
        apiUrl =
            '$packagesBaseUrl?service_id=$serviceId&group_code=$groupCode&service_shift=$serviceShift&job_id=$jobId';
      } else {
        // For Fawran 8 Hours (service_id=21), no service_shift parameter
        apiUrl =
            '$packagesBaseUrl?service_id=$serviceId&group_code=$groupCode&job_id=$jobId';
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
        jsonString = jsonString.replaceAll(
            '"discount_percentage":,', '"discount_percentage":0,');
        jsonString = jsonString.replaceAll(
            '"discount_percentage":"",', '"discount_percentage":0,');

        // Also fix any other potential empty numeric fields
        jsonString = jsonString.replaceAll('":,', '":0,');
        jsonString = jsonString.replaceAll('":",', '":0,');

        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> packagesJson = data['packages'];

        List<PackageModel> packages = [];
        for (int i = 0; i < packagesJson.length; i++) {
          try {
            PackageModel package = PackageModel.fromJson(packagesJson[i]);
            packages.add(package);
          } catch (e) {
            // Continue with other packages
          }
        }

        return packages;
      } else {
        throw Exception(
            'Failed to load packages. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading packages: $e');
    }
  }

  static Future<List<PackageModel>> fetchEastAsiaPackages({
    required int professionId,
    required int serviceId,
    int? serviceShift,
  }) async {
    try {
      // Get country groups to find the correct group code for Asian
      final countryGroups = await fetchCountryGroups(serviceId: serviceId);

      var asianGroup;
      try {
        asianGroup = countryGroups.firstWhere(
          (group) =>
              group['group_name'].toString().toUpperCase().contains('ASIAN'),
        );
      } catch (e) {
        asianGroup = {'group_code': '2'}; // fallback to hardcoded value
      }

      final groupCode = asianGroup['group_code'];

      final packages = await fetchPackagesByGroup(
        professionId: professionId,
        serviceId: serviceId,
        groupCode: groupCode,
        serviceShift: serviceShift,
      );

      return packages;
    } catch (e) {
      throw Exception('Error loading East Asia packages: $e');
    }
  }

  static Future<List<PackageModel>> fetchAfricanPackages({
    required int professionId,
    required int serviceId,
    int? serviceShift,
  }) async {
    try {
      // Get country groups to find the correct group code for African
      final countryGroups = await fetchCountryGroups(serviceId: serviceId);

      var africanGroup;
      try {
        africanGroup = countryGroups.firstWhere(
          (group) =>
              group['group_name'].toString().toUpperCase().contains('AFRICAN'),
        );
      } catch (e) {
        africanGroup = {'group_code': '3'}; // fallback to hardcoded value
      }

      final groupCode = africanGroup['group_code'];

      final packages = await fetchPackagesByGroup(
        professionId: professionId,
        serviceId: serviceId,
        groupCode: groupCode,
        serviceShift: serviceShift,
      );

      return packages;
    } catch (e) {
      throw Exception('Error loading African packages: $e');
    }
  }

  Future<List<ProfessionModel>> fetchProfessions() async {
    final url = Uri.parse('$_baseUrl/home/professions');
    final token = await _secureStorage.read(key: 'token');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProfessionModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch professions. Status code: ${response.statusCode}');
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
    final token = await _secureStorage2.read(key: 'token');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'token': token ?? ''},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to fetch nationalities. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nationalities: $e');
    }
  }
}

Map<String, dynamic>? safeJsonDecode(String jsonString) {
  try {
    return jsonDecode(jsonString);
  } catch (e) {
    print('Initial JSON decode failed. Attempting to sanitize…');

    // 1. Remove any trailing commas from the JSON string
    String fixed = jsonString.replaceAll(RegExp(r',\s*}'), '}');

    try {
      return jsonDecode(fixed);
    } catch (e) {
      print('Failed to decode even after fix: $e');
      return null;
    }
  }
}
