import 'dart:convert';
import 'package:fawran/models/ProffesionModel.dart';
import 'package:fawran/models/sliderItem.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';
import 'dart:io'; // for SocketException
import 'dart:async'; // for TimeoutException
import 'package:intl/intl.dart';
import '../models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  static const String _baseUrl =
      'http://fawran.ddns.net:8080/ords/emdad/fawran';
  static const String packagesBaseUrl =
      'http://fawran.ddns.net:8080/ords/emdad/fawran/service/packages';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Sign up API
  Future<Map<String, dynamic>?> signUp({
    required String userName,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
    required String nationalId,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');

    print('🔐 [SIGNUP] Starting sign-up process...');
    print('📤 [SIGNUP] POST to: $url');
    print('📤 [SIGNUP] Request payload: ${{
      'username': userName,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email': email,
      'password': '***', // Mask password for security
    }}');

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
          'id_number': nationalId
        }),
      );

      print('📬 [SIGNUP] Response status: ${response.statusCode}');
      print('📬 [SIGNUP] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = safeJsonDecode(response.body);
        print('✅ [SIGNUP] Parsed result: $result');
        return result;
      } else if (response.statusCode == 409) {
        final result = safeJsonDecode(response.body);
        print('✅ [SIGNUP] Parsed result: $result');
        return result;
      } else {
        return null;
      }
    } catch (ex) {
      print('🧨 [SIGNUP] Exception occurred: $ex');
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

  static Future<List<dynamic>> fetchCustomerAddresses(
      {required int userId}) async {
    try {
      final url = '$_baseUrl/customer_addresses/$userId';

      print(
          '🔍 [fetchCustomerAddresses] Fetching addresses for userId: $userId');
      print('🌐 [fetchCustomerAddresses] URL: $url');

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
      );

      print(
          '📡 [fetchCustomerAddresses] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(
            '✅ [fetchCustomerAddresses] Successfully fetched ${data.length} addresses');
        return data;
      } else {
        print(
            '❌ [fetchCustomerAddresses] Failed with status: ${response.statusCode}');
        print('❌ [fetchCustomerAddresses] Response body: ${response.body}');
        throw Exception(
            'Failed to load addresses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [fetchCustomerAddresses] Error: $e');
      throw Exception('Error loading addresses: $e');
    }
  }

  static Future<List<dynamic>> fetchProfessionsHourly() async {
    try {
      final url = '$_baseUrl/home/professions';

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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

  static Future<List<City>> fetchCities(int serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/service_cities/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> citiesJson = json.decode(response.body);
        List<City> cities =
            citiesJson.map((city) => City.fromJson(city)).toList();
        return cities;
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      throw Exception('Error fetching cities: $e');
    }
  }

  static Future<List<District>> fetchDistricts(int cityCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/districts/$cityCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> districtsJson = json.decode(response.body);
        List<District> districts = districtsJson
            .map((district) => District.fromJson(district))
            .toList();
        return districts;
      } else {
        throw Exception('Failed to load districts');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  static Future<DistrictMapResponse> fetchDistrictMapData(
      String districtCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/districts/info/$districtCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final districtMapResponse =
            DistrictMapResponse.fromJson(json.decode(response.body));
        return districtMapResponse;
      } else {
        throw Exception('Failed to load district map data');
      }
    } catch (e) {
      throw Exception('Error fetching district map data: $e');
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null) {
        print('❌ [REFRESH_TOKEN] No refresh token found');
        return false;
      }

      print('🔄 [REFRESH_TOKEN] Attempting to refresh token...');

      final url = Uri.parse('$_baseUrl/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refresh_token': refreshToken,
        }),
      );

      print('📡 [REFRESH_TOKEN] Response status: ${response.statusCode}');
      print('📡 [REFRESH_TOKEN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Save new tokens
        await _secureStorage.write(key: 'token', value: responseData['token']);
        await _secureStorage.write(
            key: 'refresh_token', value: responseData['refresh_token']);

        print('✅ [REFRESH_TOKEN] Token refreshed successfully');
        return true;
      } else {
        print(
            '❌ [REFRESH_TOKEN] Failed to refresh token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 [REFRESH_TOKEN] Error refreshing token: $e');
      return false;
    }
  }

   static Future<List<SliderItem>> fetchSliderItems() async {
   final response = await makeAuthenticatedRequest(
      method: 'GET',
      url: '$_baseUrl/slider-items',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => SliderItem.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load slider items");
    }
  }

// Enhanced HTTP request method with automatic token refresh
  static Future<http.Response> makeAuthenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
    int retryCount = 0,
  }) async {
    final token = await _secureStorage.read(key: 'token');
    final local = await _secureStorage.read(key: 'lang_code');

    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'token': token,
      if(local!=null) 'language':local,
      ...?headers,
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(Uri.parse(url),
            headers: requestHeaders, body: body);
        break;
      case 'PUT':
        response =
            await http.put(Uri.parse(url), headers: requestHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If we get a 401 (unauthorized) and haven't already retried
    if (response.statusCode == 401 && retryCount == 0) {
      print('🔄 [AUTH_REQUEST] Received 401, attempting token refresh...');

      final refreshSuccess = await refreshToken();
      if (refreshSuccess) {
        print('✅ [AUTH_REQUEST] Token refreshed, retrying original request...');
        // Retry the original request with the new token
        return makeAuthenticatedRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          retryCount: 1, // Prevent infinite retry loop
        );
      } else {
        print('❌ [AUTH_REQUEST] Token refresh failed, clearing storage...');
        // Clear all stored tokens if refresh fails
        await _secureStorage.deleteAll();
      }
    }

    return response;
  }



static Future<Map<String, dynamic>> createContract({
  required int customerId,
  required int serviceId,
  required String groupCode,
  required String cityId,
  required String district,
  required int employeeCount,
  required int hoursNumber,
  required int weeklyVisit,
  required int contractPeriod,
  required int visitShift,
  required int hourlyPrice,
  required String contractStartDate,
  required double totalPrice,
  required double priceVat,
  required int vatRat,
  required String customerLocation,
  required double priceAfterDiscount,
  required double originalPrice,
  required double visitPrice,
  String? visitCalendar,
  int? packageId,
  List<String>? appointments,
}) async {
  try {
    // Prepare request body
    Map<String, dynamic> requestBody = {
      "customer_id": customerId,
      "service_id": serviceId,
      "group_code": groupCode,
      "city_id": cityId,
      "district": district,
      "employee_count": employeeCount,
      "hours_number": hoursNumber,
      "weekly_visit": weeklyVisit,
      "contract_period": contractPeriod,
      "visit_shift": visitShift,
      "hourly_price": hourlyPrice,
      "contract_start_date": contractStartDate,
      "total_price": totalPrice,
      "price_vat": priceVat,
      "vat_rat": vatRat,
      "customer_location": customerLocation,
      "price_after_discount": priceAfterDiscount,
      "original_price": originalPrice,
      "visit_price": visitPrice,
    };

    // Add optional fields if available
    if (visitCalendar != null && visitCalendar.isNotEmpty) {
      requestBody["visit_calendar"] = visitCalendar;
    }
    
    if (packageId != null) {
      requestBody["package_id"] = packageId;
    }
    
    if (appointments != null && appointments.isNotEmpty) {
      requestBody["appointments"] = appointments;
    }

    print('Creating contract with body: ${json.encode(requestBody)}');

    final response = await makeAuthenticatedRequest(
      method: 'POST',
      url: '$_baseUrl/hourly/contract/create',
      body: json.encode(requestBody),
    );

    print('Contract creation response status: ${response.statusCode}');
    print('Contract creation response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      
      if (responseData['contract_id'] != null) {
        print('Contract created successfully with ID: ${responseData['contract_id']}');
        
        return {
          'success': true,
          'contract_id': responseData['contract_id'],
          'message': responseData['message'] ?? 'Contract created successfully',
          'data': responseData,
        };
      } else {
        throw Exception('Contract creation failed: Invalid response format');
      }
    } else {
      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Unknown error occurred',
        'statusCode': response.statusCode,
      };
    }
    
  } catch (e) {
    print('Error creating contract: $e');
    return {
      'success': false,
      'message': 'Failed to create contract: ${e.toString()}',
      'error': e.toString(),
    };
  }
}



static Future<Map<String, dynamic>> fetchServiceTerms() async {
  try {
    final response = await makeAuthenticatedRequest(
      method: 'GET',
      url: '$_baseUrl/service_terms',
    );

    print('📡 [FETCH_TERMS] Response status: ${response.statusCode}');
    print('📡 [FETCH_TERMS] Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Return the raw response body as terms since it's already a JSON array
      return {
        'success': true,
        'terms': response.body, // Store as JSON string to be parsed in UI
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to load terms and conditions. Please try again.',
      };
    }
  } catch (e) {
    print('💥 [FETCH_TERMS] Error: $e');
    return {
      'success': false,
      'message': 'Error loading terms and conditions. Please check your internet connection.',
    };
  }
}



static Future<List<Map<String, dynamic>>> fetchPermanentContracts({
  required int userId,
}) async {
  try {
    if (userId.toString().isEmpty) {
      throw Exception("Missing customer ID");
    }

    print('🔍 [PERMANENT_CONTRACTS] Fetching contracts for user: $userId');

    final url = "$_baseUrl/domestic/contracts/$userId";
    
    final response = await makeAuthenticatedRequest(
      method: 'GET',
      url: url,
    );

    print('📡 [PERMANENT_CONTRACTS] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      String rawJson = response.body;
      print('📦 [PERMANENT_CONTRACTS] Raw response length: ${rawJson.length}');

      // Fix missing price_before_vat fields (e.g. "price_before_vat":,)
      rawJson = rawJson.replaceAllMapped(
        RegExp(r'"price_before_vat"\s*:\s*,'),
        (match) => '"price_before_vat": null,',
      );

      final List<dynamic> data = json.decode(rawJson);
      print('✅ [PERMANENT_CONTRACTS] Successfully fetched ${data.length} contracts');

      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ [PERMANENT_CONTRACTS] Failed with status: ${response.statusCode}');
      throw Exception("Failed to load permanent contracts: ${response.statusCode}");
    }
  } catch (e) {
    print("💥 [PERMANENT_CONTRACTS] Error fetching permanent contracts: $e");
    throw Exception("Error fetching permanent contracts: $e");
  }
}

static Future<List<Map<String, dynamic>>> fetchHourlyContracts({
  required int userId,
}) async {
  try {
    print("=== HOURLY CONTRACTS DEBUG ===");
    print("User ID: $userId");

    if (userId.toString().isEmpty) {
      throw Exception("Missing customer ID");
    }

    final url = "$_baseUrl/hourly/contracts/$userId";
    print("Request URL: $url");

    final response = await makeAuthenticatedRequest(
      method: 'GET',
      url: url,
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Headers: ${response.headers}");
    print("Response Body Length: ${response.body.length}");
    print("Raw Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print("Parsed Data Type: ${data.runtimeType}");
        print("Number of hourly contracts: ${data.length}");

        // Print each contract with its structure
        for (int i = 0; i < data.length; i++) {
          print("--- Hourly Contract $i ---");
          print("Contract Type: ${data[i].runtimeType}");
          if (data[i] is Map) {
            final contract = data[i] as Map<String, dynamic>;
            print("Contract Keys: ${contract.keys.toList()}");
            contract.forEach((key, value) {
              print("  $key: $value (${value.runtimeType})");
            });
          } else {
            print("Contract Data: ${data[i]}");
          }
        }

        print("✅ [HOURLY_CONTRACTS] Successfully fetched ${data.length} hourly contracts");
        return data.cast<Map<String, dynamic>>();
      } catch (jsonError) {
        print("JSON Parsing Error: $jsonError");
        print("Attempting to parse as single object...");
        try {
          final Map<String, dynamic> singleData = json.decode(response.body);
          print("Single Object Keys: ${singleData.keys.toList()}");
          singleData.forEach((key, value) {
            print("  $key: $value (${value.runtimeType})");
          });
          return [singleData]; // Return as list with single item
        } catch (e) {
          print("Failed to parse as single object: $e");
          throw Exception("Failed to parse hourly contracts response");
        }
      }
    } else {
      print("HTTP Error Details:");
      print("Status Code: ${response.statusCode}");
      print("Reason Phrase: ${response.reasonPhrase}");
      print("Error Response Body: ${response.body}");
      throw Exception("Failed to load hourly contracts: ${response.statusCode}");
    }
  } catch (e) {
    print("💥 [HOURLY_CONTRACTS] Error fetching hourly contracts: $e");
    print("Error Type: ${e.runtimeType}");
    if (e is http.ClientException) {
      print("Network Error Details: ${e.message}");
    }
    throw Exception("Error fetching hourly contracts: $e");
  } finally {
    print("=== END HOURLY CONTRACTS DEBUG ===\n");
  }
}


  static Future<Map<String, dynamic>> createAddress({
    required String buildingName,
    required int buildingNumber,
    required String cityCode,
    required String districtId,
    required int houseType,
    required int createdBy,
    required int customerId,
    required String mapUrl,
    required double latitude,
    required double longitude,
    int? apartmentNumber,
    int? floorNumber,
  }) async {
    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {
        'building_name': buildingName,
        'building_number': buildingNumber,
        'city_code': cityCode,
        'district_id': districtId,
        'house_type': houseType,
        'created_by': createdBy,
        'customer_id': customerId,
        'map_url': mapUrl,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Add apartment-specific fields only if house type is Apartment (2)
      if (houseType == 2) {
        requestBody['apartment_number'] = apartmentNumber ?? 0;
        requestBody['floor_number'] = floorNumber ?? 0;
      }

      print('Sending POST request with body: ${json.encode(requestBody)}');

      final response = await makeAuthenticatedRequest(
        method: 'POST',
        url: '$_baseUrl/customer_addresses',
        headers: {'Accept': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Address created successfully!'
        };
      } else {
        // Handle error responses
        String errorMessage = 'Failed to create address. Please try again.';

        // Check if response is HTML (like the 555 error)
        if (response.body.contains('<!DOCTYPE html>') ||
            response.body.contains('<html>')) {
          errorMessage =
              'Server error occurred. Please check your network connection and try again.';
        } else {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            // Keep default error message
          }
        }

        print('API Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': '$errorMessage (${response.statusCode})',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('Exception creating address: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'error': e.toString()
      };
    }
  }

  // Fetch service shifts by service ID
  static Future<List<dynamic>> fetchServiceShifts(
      {required int serviceId}) async {
    try {
      final url = '$_baseUrl/service_shifts/$serviceId';

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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

      final requestBody = json.encode({
        'service_id': serviceId,
        'duration': duration,
        'group_code': groupCode,
        'number_of_weeks': numberOfWeeks,
        'number_of_visits': numberOfVisits,
        'shift_id': shiftId,
        'number_of_workers': numberOfWorkers,
      });

      final response = await makeAuthenticatedRequest(
        method: 'POST',
        url: url,
        body: requestBody,
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
    // ... existing print statements ...

    try {
      final url = '$_baseUrl/validate-workers';

      final requestBody = {
        "position_id": positionId,
        "sector_type": "H",
        "nationality_group": nationalityId,
        "num_workers": numWorkers,
        "start_date": DateFormat('MM-dd-yyyy').format(startDate),
        "end_date": DateFormat('MM-dd-yyyy').format(endDate),
      };

      print(
          '📦 [validateWorkersHourly] Request body: ${json.encode(requestBody)}');

      final response = await makeAuthenticatedRequest(
        method: 'POST',
        url: url,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print(
          '📡 [validateWorkersHourly] Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [validateWorkersHourly] Request successful');
        final responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>?;
      } else {
        print(
            '❌ [validateWorkersHourly] Request failed with status ${response.statusCode}');
        throw Exception(
            'Failed to validate workers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 [validateWorkersHourly] Error: $e');
      throw Exception('Error validating workers: $e');
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
    try {
      final url = '$_baseUrl/home/professions';

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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
    try {
      final url = '$_baseUrl/nationalities/$professionId/$cityCode';

      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
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
