class Laborer {
  final int personId;
  final int employeeNumber;
  final String employeeName;
  final String arabicName;
  final String nationality;
  final String nationalityId;
  final String positionName;

  final int age;            // made required int
  final int experience;     // made required int
  final String socialStatus; // made required String

  var imageUrl;

  Laborer({
    required this.personId,
    required this.employeeNumber,
    required this.employeeName,
    required this.arabicName,
    required this.nationality,
    required this.nationalityId,
    required this.positionName,
    required this.age,
    required this.experience,
    required this.socialStatus,
  });

  factory Laborer.fromJson(Map<String, dynamic> json) {
    try {
      return Laborer(
        personId: int.tryParse(json['person_id']?.toString() ?? '') ?? 0,
        employeeNumber:
            int.tryParse(json['employee_number']?.toString() ?? '') ?? 0,
        employeeName: json['employee_name']?.toString() ?? 'Unknown',
        arabicName: json['arabic_name']?.toString() ?? 'غير معروف',
        nationality: json['nationality']?.toString() ?? 'Unknown',
        nationalityId: json['nationality_id']?.toString() ?? 'N/A',
        positionName: json['position_name']?.toString() ?? 'N/A',
        age: int.tryParse(json['age']?.toString() ?? '') ?? 0,
        experience: int.tryParse(json['experience_years']?.toString() ?? '') ?? 0,
        socialStatus: json['marital_status']?.toString() ?? 'Unknown',
      );
    } catch (e) {
      print('Error parsing Laborer: $e');
      return Laborer(
        personId: 0,
        employeeNumber: 0,
        employeeName: 'Unknown',
        arabicName: 'غير معروف',
        nationality: 'Unknown',
        nationalityId: 'N/A',
        positionName: 'N/A',
        age: 0,
        experience: 0,
        socialStatus: 'Unknown',
      );
    }
  }
}
