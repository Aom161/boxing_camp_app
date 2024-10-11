// lib/models/user.dart
class User {
  final String id;
  final String fullname;
  final String email;
  final String username;
  final String address;
  final String telephone;
  final String role;

  User({
    required this.id,
    required this.fullname,
    required this.email,
    required this.username,
    required this.address,
    required this.telephone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      fullname: json['fullname'],
      email: json['email'],
      username: json['username'],
      address: json['address'],
      telephone: json['telephone'],
      role: json['role'],
    );
  }
}
