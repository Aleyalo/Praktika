import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Для работы с AuthService
import '../services/delete_profile_service.dart'; // Импортируем новый сервис
import './login_screen.dart'; // Для перехода на экран авторизации
import './privacy_settings_screen.dart'; // Импортируем экран настроек приватности
// Добавь импорт нового экрана в начале файла
import '../screens/edit_profile_screen.dart';

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
              title: Text('Настройки приватности'),
              leading: Icon(Icons.lock, color: Colors.blue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Редактировать профиль'),
              leading: Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Выйти из аккаунта'),
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
            ListTile(
              title: Text('Удалить аккаунт'),
              leading: Icon(Icons.delete, color: Colors.red),
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Метод для показа диалогового окна подтверждения выхода
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выход из аккаунта'),
          content: Text('Вы уверены, что хотите выйти из аккаунта?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Закрываем диалог
                await _logout(context);
              },
              child: Text('Да'),
            ),
          ],
        );
      },
    );
  }

  // Метод для показа диалогового окна подтверждения удаления аккаунта
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удаление аккаунта'),
          content: Text('Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Закрываем диалог
                await _deleteAccount(context);
              },
              child: Text('Да', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

  // Метод для удаления аккаунта
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final deleteProfileService = DeleteProfileService();
      final success = await deleteProfileService.deleteProfile();
      if (success) {
        final authService = AuthService();
        await authService.logout(); // Очищаем данные пользователя и учетные данные
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false, // Удаляем все предыдущие маршруты
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Аккаунт успешно удален')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении аккаунта')),
        );
      }
    } catch (e) {
      print('Ошибка при удалении аккаунта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }
}
