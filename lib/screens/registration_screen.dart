import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Импортируем cupertino для CupertinoDatePicker
import 'package:intl/intl.dart'; // Для форматирования даты
import '../services/moderation_service.dart'; // Импортируем ModerationService
import '../utils/error_handler.dart'; // Для обработки ошибок
import 'package:url_launcher/url_launcher.dart'; // Для работы с ссылками
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart'; // Импортируем AuthService
import 'package:flutter/gestures.dart'; // Добавляем импорт для TapGestureRecognizer

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();
  final TextEditingController _snilsController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isUserAgreementChecked = false; // Состояние чекбокса для пользовательского соглашения
  bool _isConsentPDChecked = false; // Состояние чекбокса для согласия на обработку ПД
  String _userAgreementUrl = ''; // URL пользовательского соглашения
  String _consentPDUrl = ''; // URL согласия на обработку ПД
  final _formKey = GlobalKey<FormState>(); // Добавляем ключ для формы
  DateTime? _selectedDate; // Добавляем переменную для хранения выбранной даты
  String _errorMessage = ''; // Сообщение об ошибке

  @override
  void initState() {
    super.initState();
    _fetchAgreements(); // Загружаем ссылки на соглашения
    _checkModerationStatus();
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
              _errorMessage = 'Дождитесь завершения предыдущей модерации';
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

  String? _validatePatronymic(String? value) {
    if (value != null && value.isNotEmpty && value.contains(RegExp(r'[0-9]'))) {
      return 'ФИО не может содержать числа';
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

  String? _formatSnils(String snils) {
    final digits = snils.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return null;
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 9)} ${digits.substring(9)}';
  }

  Future<void> _registerUser(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
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
      final name = _capitalizeFirstLetter(_nameController.text.trim());
      final surname = _capitalizeFirstLetter(_surnameController.text.trim());
      final patronymic = _capitalizeFirstLetter(_patronymicController.text.trim());
      final birthdate = _formatDate(_selectedDate!, format: 'yyyyMMdd'); // Используем формат yyyyMMdd для отправки на сервер
      final snilsControllerValue = _snilsController.text.trim();
      final formattedSnils = _formatSnils(snilsControllerValue);
      if (formattedSnils == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неверный формат СНИЛС')),
        );
        return;
      }
      final login = _loginController.text.trim();
      final password = _passwordController.text.trim();
      try {
        final response = await moderationService.register(
          name: name,
          surname: surname,
          patronymic: patronymic,
          birthdate: birthdate, // Передаем выбранную дату в формате yyyyMMdd
          snils: formattedSnils,
          login: login,
          password: password,
        );
        if (response['success'] == true) {
          final guid = response['guid'];
          final status = response['status'];
          await moderationService.saveModerationGUID(guid); // Сохраняем GUID модерации
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

  String _formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    return DateFormat(format).format(date);
  }

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<void> _selectDate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext buildContext) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                'Выберите дату рождения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate ?? DateTime.now(),
                  minimumDate: DateTime(1900),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                  use24hFormat: true, // Используем 24-часовой формат
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TapGestureRecognizer userAgreementTapRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        if (_userAgreementUrl.isNotEmpty) {
          await launchUrl(Uri.parse(_userAgreementUrl), mode: LaunchMode.externalApplication);
        }
      };
    final TapGestureRecognizer consentPDTapRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        if (_consentPDUrl.isNotEmpty) {
          await launchUrl(Uri.parse(_consentPDUrl), mode: LaunchMode.externalApplication);
        }
      };
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
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: _validateName,
                      keyboardType: TextInputType.name,
                      onChanged: (value) {
                        _nameController.text = _capitalizeFirstLetter(value);
                        _nameController.selection = TextSelection.collapsed(offset: _nameController.text.length);
                      },
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
                      keyboardType: TextInputType.name,
                      onChanged: (value) {
                        _surnameController.text = _capitalizeFirstLetter(value);
                        _surnameController.selection = TextSelection.collapsed(offset: _surnameController.text.length);
                      },
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
                      validator: _validatePatronymic, // Используем новый валидатор для отчества
                      keyboardType: TextInputType.name,
                      onChanged: (value) {
                        _patronymicController.text = _capitalizeFirstLetter(value);
                        _patronymicController.selection = TextSelection.collapsed(offset: _patronymicController.text.length);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('* ', style: TextStyle(color: Colors.red)), // Обязательное поле
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
                          ),
                          decoration: InputDecoration(labelText: 'Дата рождения'),
                          validator: (value) {
                            if (_selectedDate == null) {
                              return 'Обязательное поле';
                            }
                            return null;
                          },
                        ),
                      ),
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
                      onChanged: (value) {
                        final formattedSnils = _formatSnils(value);
                        if (formattedSnils != null) {
                          _snilsController.value = TextEditingValue(
                            text: formattedSnils,
                            selection: TextSelection.collapsed(offset: formattedSnils.length),
                          );
                        }
                      },
                      // Убираем валидацию СНИЛСа
                      keyboardType: TextInputType.number,
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
                      decoration: InputDecoration(labelText: 'Login'),
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
                            recognizer: userAgreementTapRecognizer,
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
                            recognizer: consentPDTapRecognizer,
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
    _snilsController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}