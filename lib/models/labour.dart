class Laborer {
  final int personId;
  final int employeeNumber;
  final String employeeName;
  final String arabicName;
  final String nationality;
  final String nationalityId;
  final String positionName;

  var imageUrl;

  Laborer({
    required this.personId,
    required this.employeeNumber,
    required this.employeeName,
    required this.arabicName,
    required this.nationality,
    required this.nationalityId,
    required this.positionName,
  });

factory Laborer.fromJson(Map<String, dynamic> json) {
  try{
  final m = Laborer(
    personId: int.parse(json['person_id'].toString()),
    employeeNumber: int.parse(json['employee_number'].toString()), // <-- FIXED
    employeeName: json['employee_name'],
    arabicName: json['arabic_name'],
    nationality: json['nationality'],
    nationalityId: json['nationality_id'].toString(),
    positionName: json['position_name'],
  );

  return m;
  }
  catch(e){
    print(e);
      final m = Laborer(
    personId: int.parse(json['person_id'].toString()),
    employeeNumber: int.parse(json['employee_number'].toString()), // <-- FIXED
    employeeName: json['employee_name'],
    arabicName: json['arabic_name'],
    nationality: json['nationality'],
    nationalityId: json['nationality_id'].toString(),
    positionName: json['position_name'],
  );

  return m;
  }
}
}
