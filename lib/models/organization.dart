class Organization {
  final String guid;
  final String name;

  Organization({required this.guid, required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
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