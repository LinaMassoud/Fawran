// profession_model.dart

class ProfessionModel {
  final int positionId;
  final String positionName;
  final bool hasDomesticPackage;
  final List<Service> services;
    final String image;


  ProfessionModel({
    required this.positionId,
    required this.positionName,
    required this.hasDomesticPackage,
    required this.services,
        required this.image

  });

factory ProfessionModel.fromJson(Map<String, dynamic> json) {
  return ProfessionModel(
    positionId: json['position_id'],
    positionName: json['position_name'],
    hasDomesticPackage: json['has_domestic_package'] == 'true',
    services: (json['services'] as List<dynamic>?)
            ?.map((serviceJson) => Service.fromJson(serviceJson))
            .toList() ??
        [],
              image:json['image_path']

  );
}

}

class Service {
  final int id;
  final String name;

  Service({
    required this.id,
    required this.name,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
    );
  }
}
