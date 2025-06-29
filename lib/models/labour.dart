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
    try {
      final m = Laborer(
        personId: int.tryParse(json['person_id']?.toString() ?? '') ?? 0,
        employeeNumber: int.tryParse(json['employee_number']?.toString() ?? '') ?? 0,
        employeeName: json['employee_name']?.toString() ?? 'Unknown',
        arabicName: json['arabic_name']?.toString() ?? 'غير معروف',
        nationality: json['nationality']?.toString() ?? 'Unknown',
        nationalityId: json['nationality_id']?.toString() ?? 'N/A',
        positionName: json['position_name']?.toString() ?? 'N/A',
      );
      return m;
    } catch (e) {
      print('Error parsing Laborer: $e');
      // Return a default object to avoid breaking the app
      return Laborer(
        personId: 0,
        employeeNumber: 0,
        employeeName: 'Unknown',
        arabicName: 'غير معروف',
        nationality: 'Unknown',
        nationalityId: 'N/A',
        positionName: 'N/A',
      );
    }
  }
}
