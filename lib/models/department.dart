class Department {
  final String guid;
  final String name;

  Department({
    required this.guid,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    try {
      return Department(
        guid: json['guid'] as String? ?? '', // Явное приведение к String и обработка null
        name: json['name'] as String? ?? '', // Явное приведение к String и обработка null
      );
    } catch (e) {
      print('Error parsing Department from JSON: $e');
      print('JSON data: $json');
      return Department(guid: '', name: '');
    }
  }

  @override
  String toString() {
    return 'Department{guid: $guid, name: $name}';
  }
}