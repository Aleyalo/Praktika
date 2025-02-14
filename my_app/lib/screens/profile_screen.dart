import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, String> user;

  ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профиль'), backgroundColor: Colors.yellow),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 50, color: Colors.grey.shade700),
            ),
            SizedBox(height: 20),
            ProfileField(label: 'Фамилия', value: user['surname'] ?? ''),
            ProfileField(label: 'Имя', value: user['name'] ?? ''),
            ProfileField(label: 'Отчество', value: user['patronymic'] ?? ''),
            ProfileField(label: 'Должность', value: user['position'] ?? ''),
            ProfileField(label: 'Организация', value: user['organization'] ?? ''),
            ProfileField(label: 'Подразделение', value: user['department'] ?? ''),
            ProfileField(label: 'Телефон', value: user['phone'] ?? ''),
            ProfileField(label: 'E-mail', value: user['email'] ?? ''),
            ProfileField(label: 'СНИЛС', value: user['snils'] ?? ''),
          ],
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text('$label:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}