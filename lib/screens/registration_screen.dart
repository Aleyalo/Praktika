import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/moderation_service.dart'; // Импортируем ModerationService
import '../utils/error_handler.dart'; // Для обработки ошибок
import 'package:url_launcher/url_launcher.dart'; // Для работы с ссылками
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _snilsController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isUserAgreementChecked = false; // Состояние чекбокса для пользовательского соглашения
  bool _isConsentPDChecked = false; // Состояние чекбокса для согласия на обработку ПД
  String _userAgreementUrl = ''; // URL пользовательского соглашения
  String _consentPDUrl = ''; // URL согласия на обработку ПД

  @override
  void initState() {
    super.initState();
    _fetchAgreements(); // Загружаем ссылки на соглашения
  }

  Future<void> _fetchAgreements() async {
    try {
      final response = await http.get(
        Uri(
          scheme: 'https',
          host: 'mw.azs-topline.ru',
          port: 44445,
          path: '/hrm/hs/ewp/agreements',
        ),
        headers: {
          'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
          'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _userAgreementUrl = json['UserAgreement'];
          _consentPDUrl = json['ConsentProcessingPD'];
        });
      } else {
        throw Exception('Ошибка при загрузке соглашений');
      }
    } catch (e) {
      print('Ошибка при получении ссылок на соглашения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Colors.yellow,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
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
            Row(
              children: [
                Checkbox(
                  value: _isUserAgreementChecked,
                  onChanged: (value) {
                    setState(() {
                      _isUserAgreementChecked = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: 'Я согласен с '),
                        TextSpan(
                          text: 'условиями использования приложения',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              if (_userAgreementUrl.isNotEmpty) {
                                await launchUrl(Uri.parse(_userAgreementUrl), mode: LaunchMode.externalApplication);
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _isConsentPDChecked,
                  onChanged: (value) {
                    setState(() {
                      _isConsentPDChecked = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: 'Я согласен на '),
                        TextSpan(
                          text: 'обработку персональных данных',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              if (_consentPDUrl.isNotEmpty) {
                                await launchUrl(Uri.parse(_consentPDUrl), mode: LaunchMode.externalApplication);
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUserAgreementChecked && _isConsentPDChecked ? Colors.green : Colors.grey,
              ),
              onPressed: _isUserAgreementChecked && _isConsentPDChecked
                  ? () => _registerUser(context)
                  : null,
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
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
    if (name.isEmpty ||
        surname.isEmpty ||
        birthdate.isEmpty ||
        snils.isEmpty ||
        login.isEmpty ||
        password.isEmpty) {
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
