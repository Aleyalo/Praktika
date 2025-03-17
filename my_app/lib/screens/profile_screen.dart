// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Профиль'), backgroundColor: Colors.yellow),
        body: Center(child: Text('Данные пользователя недоступны')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Профиль'), backgroundColor: Colors.yellow),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 50, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ProfileField(label: 'Фамилия', value: user['surname']?.toString() ?? ''),
            ProfileField(label: 'Имя', value: user['name']?.toString() ?? ''),
            ProfileField(label: 'Отчество', value: user['patronymic']?.toString() ?? ''),
            ProfileField(label: 'Организация', value: user['organization']?.toString() ?? ''),
            ProfileField(label: 'Подразделение', value: user['department']?.toString() ?? ''),
            ProfileField(label: 'Должность', value: user['position']?.toString() ?? ''),
            ProfileField(label: 'Телефон', value: user['phone']?.toString() ?? ''),
            ProfileField(label: 'E-mail', value: user['email']?.toString() ?? ''),
            ProfileField(label: 'СНИЛС', value: user['snils']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({required this.label, required this.value});

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