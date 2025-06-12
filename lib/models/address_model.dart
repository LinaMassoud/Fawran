import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

class AddressModel {
  final String id;
  final String name;
  final String fullAddress;
  final bool isSelected;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.isSelected,
  });

  AddressModel copyWith({
    String? id,
    String? name,
    String? fullAddress,
    bool? isSelected,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class Address {
  final String cardText;
  final int addressId;
  final String cityCode;
  final String districtCode;

  Address({
    required this.cardText,
    required this.addressId,
    required this.cityCode,
    required this.districtCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      cardText: json['card_text'] as String,
      addressId: json['address_id'] as int,
      cityCode: json['city_code'] as String,
      districtCode: json['district_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_text': cardText,
      'address_id': addressId,
      'city_code': cityCode,
      'district_code': districtCode,
    };
  }
}
/// Model for district map response containing location and boundary data
class DistrictMapResponse {
  final double latitude;
  final double longitude;
  final String mapUrl;
  final String districtDays;
  final String districtsShift;
  final List<LatLng> polygonCoordinates;
  final Map<String, dynamic> geojson;
  final String districtName;  // Changed from specialPlace

  DistrictMapResponse({
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
    required this.districtDays,
    required this.districtsShift,
    required this.polygonCoordinates,
    required this.geojson,
    required this.districtName,
  });

  factory DistrictMapResponse.fromJson(Map<String, dynamic> json) {
    // Parse polygon coordinates from string format
    List<LatLng> coordinates = [];
    if (json['polygon_coordinates'] != null) {
      try {
        // Parse the polygon_coordinates string as JSON
        List<dynamic> coordsList = jsonDecode(json['polygon_coordinates']);
        for (var coord in coordsList) {
          coordinates.add(LatLng(coord['lat'], coord['lng']));
        }
      } catch (e) {
        print('Error parsing polygon coordinates: $e');
      }
    }

    // Parse geojson from string format
    Map<String, dynamic> geojsonMap = {};
    if (json['geojson'] != null) {
      try {
        geojsonMap = jsonDecode(json['geojson']);
      } catch (e) {
        print('Error parsing geojson: $e');
      }
    }

    return DistrictMapResponse(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      mapUrl: json['map_url'] ?? '',
      districtDays: json['district_days'] ?? '',
      districtsShift: json['districts_shift'] ?? '',
      polygonCoordinates: coordinates,
      geojson: geojsonMap,
      districtName: json['district_name'] ?? '',  // Changed from special_place
    );
  }
}

/// Model for city data
class City {
  final int cityCode;  // Changed from cityId
  final String cityName;

  City({required this.cityCode, required this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityCode: json['city_code'],  // Changed from city_id
      cityName: json['city_name'],
    );
  }
}

/// Response model for cities API
class CitiesResponse {
  final List<City> cities;

  CitiesResponse({required this.cities});

  factory CitiesResponse.fromJson(Map<String, dynamic> json) {
    var cityList = json['cities'] as List;
    List<City> cities = cityList.map((city) => City.fromJson(city)).toList();
    return CitiesResponse(cities: cities);
  }
}

/// Model for district data
class District {
  final String districtCode;  // Changed from int districtId to String districtCode
  final String districtName;

  District({required this.districtCode, required this.districtName});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtCode: json['district_code'],  // Changed from district_id
      districtName: json['district_name'],
    );
  }
}

/// Response model for districts API
class DistrictsResponse {
  final List<District> districts;

  DistrictsResponse({required this.districts});

  factory DistrictsResponse.fromJson(Map<String, dynamic> json) {
    var districtList = json['districts'] as List;
    List<District> districts = districtList.map((district) => District.fromJson(district)).toList();
    return DistrictsResponse(districts: districts);
  }
}

/// Model for creating new address
class CreateAddressRequest {
  final double longitude;
  final double latitude;
  final String mapUrl;
  final String customerId;
  final int floorNumber;
  final int apartmentNumber;
  final int createdBy;
  final int houseType;
  final String districtId;
  final String cityCode;
  final int buildingNumber;
  final String buildingName;

  CreateAddressRequest({
    required this.longitude,
    required this.latitude,
    required this.mapUrl,
    required this.customerId,
    required this.floorNumber,
    required this.apartmentNumber,
    required this.createdBy,
    required this.houseType,
    required this.districtId,
    required this.cityCode,
    required this.buildingNumber,
    required this.buildingName,
  });

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
      'map_url': mapUrl,
      'customer_id': customerId,
      'floor_number': floorNumber,
      'apartment_number': apartmentNumber,
      'created_by': createdBy,
      'house_type': houseType,
      'district_id': districtId,
      'city_code': cityCode,
      'building_number': buildingNumber,
      'building_name': buildingName,
    };
  }
}