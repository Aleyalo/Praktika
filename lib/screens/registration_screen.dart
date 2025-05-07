// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/moderation_service.dart'; // Импортируем ModerationService
import '../utils/error_handler.dart'; // Для обработки ошибок
import 'package:url_launcher/url_launcher.dart'; // Для работы с ссылками
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Для форматирования даты

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
  final _formKey = GlobalKey<FormState>(); // Добавляем ключ для формы

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

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    if (value.contains(RegExp(r'[0-9]'))) {
      return 'ФИО не может содержать числа';
    }
    return null;
  }

  String? _validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final date = _parseDate(value);
    if (date == null) {
      return 'Неверный формат даты';
    }
    return null;
  }

  String? _validateSnils(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final formattedSnils = _formatSnils(value);
    if (formattedSnils == null) {
      return 'Неверный формат СНИЛС';
    }
    if (!_isValidSnils(formattedSnils)) {
      return 'Некорректный СНИЛС';
    }
    return null;
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }

  DateTime? _parseDate(String dateStr) {
    final formats = ['dd.MM.yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'];
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  String? _formatDate(String dateStr) {
    final date = _parseDate(dateStr);
    if (date != null) {
      return DateFormat('yyyyMMdd').format(date);
    }
    return null;
  }

  String? _formatSnils(String snils) {
    final digits = snils.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return null;
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 9)} ${digits.substring(9)}';
  }

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

  Future<void> _registerUser(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();
      final patronymic = _patronymicController.text.trim();
      final birthdate = _formatDate(_birthdateController.text.trim()) ?? '';
      final snils = _formatSnils(_snilsController.text.trim()) ?? '';
      final login = _loginController.text.trim();
      final password = _passwordController.text.trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Colors.yellow,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: _validateName,
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
                      controller: _surnameController,
                      decoration: InputDecoration(labelText: 'Фамилия'),
                      validator: _validateName,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(' ', style: TextStyle(color: Colors.transparent)), // Пустая звездочка для выравнивания
                  Expanded(
                    child: TextFormField(
                      controller: _patronymicController,
                      decoration: InputDecoration(labelText: 'Отчество'),
                      validator: _validateName,
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
                      controller: _birthdateController,
                      decoration: InputDecoration(labelText: 'Дата рождения (дд.мм.гггг)'),
                      keyboardType: TextInputType.datetime,
                      validator: _validateBirthdate,
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
                      controller: _snilsController,
                      decoration: InputDecoration(labelText: 'СНИЛС (XXX-XXX-XXX XX)'),
                      keyboardType: TextInputType.number,
                      validator: _validateSnils,
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
                      controller: _loginController,
                      decoration: InputDecoration(labelText: 'Login/СНИЛС/Телефон'),
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
                      decoration: InputDecoration(labelText: 'Пароль'),
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                ],
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
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _patronymicController.dispose();
    _birthdateController.dispose();
    _snilsController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}