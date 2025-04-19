// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Для работы с AuthService
import './login_screen.dart'; // Для перехода на экран авторизации

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('Выйти из аккаунта'),
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () async {
                // Вызываем метод выхода из авторизации
                await _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Метод для выхода из авторизации
  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.logout(); // Очищаем данные пользователя и учетные данные
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false, // Удаляем все предыдущие маршруты
      );
    } catch (e) {
      print('Ошибка при выходе из аккаунта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }
}