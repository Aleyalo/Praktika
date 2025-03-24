// lib/models/department.dart
class Department {
  final String guid;
  final String name;

  Department({required this.guid, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      guid: json['guid'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
    };
  }
}