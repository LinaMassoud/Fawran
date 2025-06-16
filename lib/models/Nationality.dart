class Nationality {
  final String name;
  final int id;

  Nationality({required this.name, required this.id});

  factory Nationality.fromJson(Map<String, dynamic> json) {
    final l = Nationality(
        name: json['nationality'],
        id: int.tryParse(json['country_code'].toString()) ?? 0);

    return l; // only get "nationality"
  }
}
