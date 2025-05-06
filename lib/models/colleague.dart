class Colleague {
  final String guid;
  final String name;
  bool selected; // Убираем final, чтобы поле было изменяемым
  final bool auth; // новое поле

  Colleague({
    required this.guid,
    required this.name,
    required this.selected,
    required this.auth, // добавляем инициализацию
  });

  factory Colleague.fromJson(Map<String, dynamic> json) {
    return Colleague(
      guid: json['guid'] ?? '',
      name: json['name'] ?? '',
      selected: json['selected'] ?? false,
      auth: json['auth'] ?? false, // считываем из JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'name': name,
      'selected': selected,
      'auth': auth, // сохраняем в JSON
    };
  }
}