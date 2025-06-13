// Add this new model file: models/profession_model.dart

class ServiceModel {
  final int id;
  final String name;

  ServiceModel({
    required this.id,
    required this.name,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class ProfessionModel {
  final int positionId;
  final String positionName;
  final List<ServiceModel> services;
  final bool hasDomesticPackage;

  ProfessionModel({
    required this.positionId,
    required this.positionName,
    required this.services,
    required this.hasDomesticPackage,
  });

  factory ProfessionModel.fromJson(Map<String, dynamic> json) {
    return ProfessionModel(
      positionId: json['position_id'],
      positionName: json['position_name'],
      services: (json['services'] as List)
          .map((service) => ServiceModel.fromJson(service))
          .toList(),
      hasDomesticPackage: json['has_domestic_package'] == "true",
    );
  }
}

class CountryGroupModel {
  final String groupName;
  final String groupCode;

  CountryGroupModel({
    required this.groupName,
    required this.groupCode,
  });

  factory CountryGroupModel.fromJson(Map<String, dynamic> json) {
    return CountryGroupModel(
      groupName: json['group_name'],
      groupCode: json['group_code'],
    );
  }
}

class ServiceShiftModel {
  final String serviceShifts;
  final int id;

  ServiceShiftModel({
    required this.serviceShifts,
    required this.id,
  });

  factory ServiceShiftModel.fromJson(Map<String, dynamic> json) {
    return ServiceShiftModel(
      serviceShifts: json['service_shifts'],
      id: json['id'],
    );
  }
}