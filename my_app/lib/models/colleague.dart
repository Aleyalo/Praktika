// lib/models/colleague.dart
class Colleague {
  final String guid;
  final String name;
  final String position;
  final String department;

  Colleague({
    required this.guid,
    required this.name,
    required this.position,
    required this.department,
  });

  factory Colleague.fromJson(Map<String, dynamic> json) {
    return Colleague(
      guid: json['guid'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      department: json['department'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
      'position': position,
      'department': department,
    };
  }
}