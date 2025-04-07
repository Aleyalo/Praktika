import 'package:flutter/material.dart';
import '../services/moderation_service.dart'; // Импортируем ModerationService
import '../utils/error_handler.dart'; // Для обработки ошибок

class RegistrationScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _snilsController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Colors.yellow,
      ),
      body: SingleChildScrollView( // Добавляем SingleChildScrollView
        padding: EdgeInsets.all(16),
        child: FutureBuilder<bool>(
          future: _checkModerationStatus(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.data == true) {
              return Center(
                child: Text('Ваша заявка на регистрацию находится на модерации. Ожидайте в течение 2 дней.'),
              );
            } else {
              return _buildRegistrationForm(context);
            }
          },
        ),
      ),
    );
  }

  Future<bool> _checkModerationStatus(BuildContext context) async {
    final moderationService = ModerationService();
    final moderationGUID = await moderationService.getModerationGUID();

    if (moderationGUID != null) {
      final moderationStatus = await moderationService.checkModerationStatus(moderationGUID);

      if (moderationStatus['status'] == 'На модерации') {
        handleError(context, 'Ваша заявка на регистрацию находится на модерации. Ожидайте в течение 2 дней.');
        return true;
      } else {
        await moderationService.clearModerationGUID(); // Удаляем GUID
      }
    }
    return false;
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Имя'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _surnameController,
          decoration: InputDecoration(labelText: 'Фамилия'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _patronymicController,
          decoration: InputDecoration(labelText: 'Отчество'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _birthdateController,
          decoration: InputDecoration(labelText: 'Дата рождения (YYYYMMDD)'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _snilsController,
          decoration: InputDecoration(labelText: 'СНИЛС (XXX-XXX-XXX XX)'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _loginController,
          decoration: InputDecoration(labelText: 'Логин'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Пароль'),
          obscureText: true,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _registerUser(context),
          child: Text('Зарегистрироваться'),
        ),
      ],
    );
  }

  Future<void> _registerUser(BuildContext context) async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final patronymic = _patronymicController.text.trim();
    final birthdate = _birthdateController.text.trim();
    final snils = _snilsController.text.trim();
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || surname.isEmpty || birthdate.isEmpty || snils.isEmpty || login.isEmpty || password.isEmpty) {
      handleError(context, 'Пожалуйста, заполните все обязательные поля');
      return;
    }

    try {
      final moderationService = ModerationService();
      final response = await moderationService.registerUser(
        name: name,
        surname: surname,
        patronymic: patronymic,
        birthdate: birthdate,
        snils: snils,
        login: login,
        password: password,
      );

      if (response['success'] == true) {
        final guid = response['data']['GUID'];
        await moderationService.saveModerationGUID(guid); // Сохраняем GUID

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Заявка отправлена на модерацию. Ожидайте в течение 2 дней.')),
        );
      } else {
        handleError(context, 'Ошибка при регистрации: ${response['error']}');
      }
    } catch (e) {
      handleError(context, 'Произошла ошибка: $e');
    }
  }
}