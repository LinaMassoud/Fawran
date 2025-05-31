class User {
  final String firstName;
  final String middleName;
  final String lastName;
  final String phoneNumber;
  final String email;

  User({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
  });

  // Factory constructor to convert JSON response into User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );
  }
}
