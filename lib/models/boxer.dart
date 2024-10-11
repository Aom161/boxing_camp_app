class Boxer {
  final String id;
  final String fullname;

  Boxer({required this.id, required this.fullname});

  factory Boxer.fromJson(Map<String, dynamic> json) {
    return Boxer(
      id: json['_id'],
      fullname: json['fullname'],
    );
  }
}
