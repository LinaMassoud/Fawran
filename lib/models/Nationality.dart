class Nationality {
  final String name;

  Nationality({required this.name});

  factory Nationality.fromJson(Map<String, dynamic> json) {
    return Nationality(name: json['nationality']); // only get "nationality"
  }
}