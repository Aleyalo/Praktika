import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/delete_profile_service.dart';
import './login_screen.dart';
import './privacy_settings_screen.dart';
import './edit_profile_screen.dart';
import '../services/logout_service.dart';

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
              title: Text('Выйти со всех устройств'),
              leading: Icon(Icons.power_settings_new, color: Colors.red),
              onTap: () {
                _showExitOtherDevicesDialog(context);
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выход из аккаунта'),
          content: Text('Вы уверены, что хотите выйти из аккаунта?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              child: Text('Да'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удаление аккаунта'),
          content: Text('Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context);
              },
              child: Text('Да', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showExitOtherDevicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выйти со всех устройств'),
          content: Text('Вы уверены, что хотите выйти со всех устройств?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _exitOtherDevices(context);
              },
              child: Text('Да', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.logout();
      _navigateToLoginScreen(context);
    } catch (e) {
      _showErrorSnackbar(context, 'Ошибка при выходе из аккаунта: $e');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final deleteProfileService = DeleteProfileService();
      final success = await deleteProfileService.deleteProfile(context);
      if (success) {
        final authService = AuthService();
        await authService.logout();
        _navigateToLoginScreen(context);
        _showSuccessSnackbar(context, 'Аккаунт успешно удален');
      } else {
        _showErrorSnackbar(context, 'Ошибка при удалении аккаунта');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Ошибка при удалении аккаунта: $e');
    }
  }

  Future<void> _exitOtherDevices(BuildContext context) async {
    try {
      final result = await LogoutService.exitOtherDevices();

      if (result['error'] == 'Выход на других устройствах.') {
        // Если сервер вернул ошибку о выходе на других устройствах
        await AuthService().logout();
        _navigateToLoginScreen(context);
        return;
      }

      if (result['success'] == true) {
        _showSuccessSnackbar(context, 'Вы успешно вышли со всех устройств');
      } else {
        _showErrorSnackbar(context, 'Ошибка: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Ошибка: $e');
    }
  }

  void _navigateToLoginScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}