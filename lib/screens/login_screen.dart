// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/main_screen.dart';
import '../screens/registration_screen.dart';
import 'forgot_password_screen.dart';
import 'confirm_phone_screen.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Метод для форматирования СНИЛС
  String? _formatSnils(String snils) {
    final digits = snils.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return null;
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 9)} ${digits.substring(9)}';
  }

  // Метод для проверки контрольной суммы СНИЛС
  bool _isValidSnils(String snils) {
    final digits = snils.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return false;
    }
    final controlNumber = int.parse(digits.substring(9));
    final sum = digits.substring(0, 9).split('').asMap().entries.fold<int>(0, (sum, entry) {
      final index = entry.key;
      final digit = int.parse(entry.value);
      return sum + digit * (9 - index);
    });
    int calculatedControlNumber;
    if (sum < 100) {
      calculatedControlNumber = sum;
    } else if (sum == 100 || sum == 101) {
      calculatedControlNumber = 0;
    } else {
      calculatedControlNumber = sum % 101;
      if (calculatedControlNumber == 100) {
        calculatedControlNumber = 0;
      }
    }
    return controlNumber == calculatedControlNumber;
  }

  // Метод для форматирования номера телефона
  String? _formatPhoneNumber(String phone) {
    // Удаляем все символы, кроме цифр
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Если номер начинается с 7 или 8, удаляем первую цифру и добавляем +7
    if (cleaned.startsWith('7') || cleaned.startsWith('8')) {
      cleaned = '+7' + cleaned.substring(1);
    } else {
      cleaned = '+$cleaned';
    }

    // Форматируем номер в формат +7 (XXX) XXX-XX-XX
    if (cleaned.length == 12) {
      cleaned = cleaned.replaceFirstMapped(RegExp(r'^(\+\d{1})(\d{3})(\d{3})(\d{2})(\d{2})$'), (match) {
        return '${match[1]} (${match[2]}) ${match[3]}-${match[4]}-${match[5]}';
      });
    }

    return cleaned;
  }

  // Метод для проверки логина
  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    // Проверка на СНИЛС
    final formattedSnils = _formatSnils(value);
    if (formattedSnils != null && _isValidSnils(formattedSnils)) {
      return null;
    }
    // Проверка на номер телефона
    final formattedPhone = _formatPhoneNumber(value);
    if (formattedPhone != null) {
      return null;
    }
    // Если не СНИЛС и не номер телефона, считаем, что это имя пользователя
    return null;
  }

  Future<void> _loginUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      String login = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (login.isEmpty || password.isEmpty) {
        throw Exception('Пожалуйста, заполните все поля');
      }

      // Проверка и форматирование СНИЛС
      final formattedSnils = _formatSnils(login);
      if (formattedSnils != null && _isValidSnils(formattedSnils)) {
        login = formattedSnils;
      }

      // Проверка и форматирование номера телефона
      final formattedPhone = _formatPhoneNumber(login);
      if (formattedPhone != null) {
        login = formattedPhone;
      }

      final authService = AuthService();
      final result = await authService.newLogin(login, password, context);
      if (result['success'] == true) {
        final guid = result['guid'];
        final deviceId = result['deviceId'];
        final askHim = result['askHim'];
        if (askHim != null && askHim['oktell'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPhoneScreen(
                newPhone: login,
                guid: guid,
                deviceId: deviceId, // Передаем deviceId
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Неверный логин или пароль');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Добро пожаловать!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Login/СНИЛС/Телефон',
                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                    ),
                    validator: _validateLogin,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                Expanded(
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _loginUser(context),
                child: Text('Войти'),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Зарегистрироваться'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              child: Text(
                'Забыли пароль?',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}