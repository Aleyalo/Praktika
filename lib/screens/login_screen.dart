import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/main_screen.dart';
import '../screens/registration_screen.dart';
import 'forgot_password_screen.dart';
import 'confirm_phone_screen.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/moderation_service.dart'; // Импортируем ModerationService

class LoginScreen extends StatefulWidget {
  final bool isModerationPending; // Добавляем параметр для модерации
  final String moderationMessage; // Добавляем параметр для сообщения о модерации
  const LoginScreen({
    Key? key,
    this.isModerationPending = false, // По умолчанию false
    this.moderationMessage = '', // По умолчанию пустая строка
  }) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isModerationPending) {
      _checkModerationStatus();
    }
  }

  Future<void> _checkModerationStatus() async {
    final moderationService = ModerationService();
    final moderationGuid = await AuthService.getModerationGUID();
    if (moderationGuid != null) {
      try {
        final moderationStatus = await moderationService.checkModerationStatus(moderationGuid);
        if (moderationStatus['success'] == true) {
          final status = moderationStatus['status'];
          if (status == 'На модерации') {
            setState(() {
              _errorMessage = 'Ваша заявка на регистрацию находится на модерации. Ожидайте около 3 дней.';
            });
          } else {
            await AuthService.clearModerationGUID(); // Удаляем GUID модерации, если статус не "На модерации"
          }
        }
      } catch (e) {
        print('Ошибка при проверке статуса модерации: $e');
      }
    }
  }

  Future<void> _loginUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final moderationService = ModerationService();
      final moderationGuid = await AuthService.getModerationGUID();
      if (moderationGuid != null) {
        try {
          final moderationStatus = await moderationService.checkModerationStatus(moderationGuid);
          if (moderationStatus['success'] == true) {
            final status = moderationStatus['status'];
            if (status == 'На модерации') {
              setState(() {
                _errorMessage = 'Дождитесь завершения предыдущей модерации';
              });
              return;
            }
          }
        } catch (e) {
          print('Ошибка при проверке статуса модерации: $e');
        }
      }
      String login = _emailController.text.trim();
      String password = _passwordController.text.trim();
      if (login.isEmpty || password.isEmpty) {
        throw Exception('Пожалуйста, заполните все поля');
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
        // Обрабатываем ошибку авторизации
        final error = result['error']?.trim();
        if (error == 'Неверный логин или пароль') {
          setState(() {
            _errorMessage = 'Неверный логин или пароль';
          });
        } else {
          setState(() {
            _errorMessage = error ?? 'Произошла ошибка при авторизации';
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } catch (e) {
      // Обрабатываем другие ошибки
      setState(() {
        _errorMessage = 'Неверный логин или пароль';
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

  String _formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    return DateFormat(format).format(date);
  }

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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
            if (widget.isModerationPending)
              Text(
                widget.moderationMessage,
                style: TextStyle(color: Colors.red),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Login/СНИЛС/Телефон'),
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
                          decoration: InputDecoration(labelText: 'Пароль'),
                          obscureText: true,
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
                      onPressed: widget.isModerationPending ? null : () => _loginUser(context),
                      child: Text('Войти'),
                    ),
                  if (_errorMessage.isNotEmpty && !widget.isModerationPending)
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  TextButton(
                    onPressed: widget.isModerationPending ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    child: Text('Зарегистрироваться'),
                  ),
                  TextButton(
                    onPressed: widget.isModerationPending ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      'Забыли пароль?',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
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