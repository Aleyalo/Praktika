// lib/models/department.dart
class Department {
  final String guid;
  final String name;
  final String organizationGuid; // Добавляем поле organizationGuid

  Department({required this.guid, required this.name, required this.organizationGuid});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      guid: json['guid'] ?? '',
      name: json['name'] ?? '',
      organizationGuid: json['organizationGuid'] ?? '', // Инициализируем поле organizationGuid
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
      'organizationGuid': organizationGuid, // Добавляем поле organizationGuid
    };
  }
}