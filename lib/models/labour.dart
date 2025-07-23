class Laborer {
  final int personId;
  final int employeeNumber;
  final String employeeName;
  final String arabicName;
  final String nationality;
  final String nationalityId;
  final String positionName;

  final int? age;
  final int? experience;
  final String? socialStatus;

  var imageUrl;

  Laborer({
    required this.personId,
    required this.employeeNumber,
    required this.employeeName,
    required this.arabicName,
    required this.nationality,
    required this.nationalityId,
    required this.positionName,
    this.age,
    this.experience,
    this.socialStatus,
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
        age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
        experience: json['experience'] != null
            ? int.tryParse(json['experience'].toString())
            : null,
        socialStatus: json['social_status']?.toString(),
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
        age: null,
        experience: null,
        socialStatus: null,
      );
    }
  }
}
