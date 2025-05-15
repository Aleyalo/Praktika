import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/profile_edit_service.dart';
import '../services/phone_edit_service.dart'; // Добавлен импорт PhoneEditService
import '../services/auth_service.dart';
import '../services/profile_service.dart' as ProfileServiceAlias; // Переименовываем импорт для избежания конфликта
import 'confirm_phone_screen.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>(); // Добавляем ключ для формы номера телефона
  final _emailController = TextEditingController();
  final _vkController = TextEditingController();
  final _telegramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _initialPhone;
  String? _photoBase64;
  final picker = ImagePicker();
  static const int _maxImageSizeInBytes = 2 * 1024 * 1024;
  String? _deviceId;
  String? _guid;
  String? _newPhone; // Добавляем переменную для хранения нового номера телефона
  int _phoneStep = 1; // Добавляем состояние для хранения текущего шага
  late Map<String, dynamic> _initialProfileData; // Добавляем переменную для хранения исходных данных профиля

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadDeviceIdAndGuid();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileService = ProfileServiceAlias.ProfileService(); // Используем переименованный импорт
      final profileData = await profileService.getProfile(context); // Передаем контекст
      setState(() {
        _emailController.text = profileData['email'] ?? '';
        _vkController.text = profileData['links']?['VK'] ?? '';
        _telegramController.text = profileData['links']?['Telegram'] ?? '';
        _whatsappController.text = profileData['links']?['WhatsApp'] ?? '';
        _phoneController.text = profileData['phone'] ?? '';
        _initialPhone = profileData['phone'] ?? '';
        if (profileData['photo'] != null && profileData['photo'].isNotEmpty) {
          _photoBase64 = profileData['photo'];
        }
        _initialProfileData = profileData; // Сохраняем исходные данные профиля
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
    }
  }

  Future<void> _loadDeviceIdAndGuid() async {
    try {
      final authService = AuthService();
      final deviceId = await authService.getDeviceId();
      final guid = await authService.getGUID();
      setState(() {
        _deviceId = deviceId;
        _guid = guid;
      });
    } catch (e) {
      print('Ошибка при загрузке deviceId и guid: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final size = await file.length();
      if (size > _maxImageSizeInBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Фото слишком большое. Максимум 2 МБ.')),
        );
        return;
      }
      setState(() {
        _photoBase64 = base64Encode(file.readAsBytesSync());
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Проверяем, были ли изменения в данных
      if (!_hasProfileChanged()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Данные не изменились')),
        );
        return;
      }

      bool confirmed = await _showConfirmDialog(context);
      if (confirmed) {
        try {
          final result = await ProfileEditService.editProfile(
            email: _emailController.text,
            links: {
              if (_vkController.text.isNotEmpty) 'VK': _vkController.text,
              if (_telegramController.text.isNotEmpty) 'Telegram': _telegramController.text,
              if (_whatsappController.text.isNotEmpty) 'WhatsApp': _whatsappController.text,
            },
            photoBase64: _photoBase64,
            context: context, // Передаем контекст
          );
          if (result['success'] == true) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Профиль успешно обновлён')));
            Navigator.pop(context);
          } else {
            final errorMessage = result['error'].toString().toLowerCase();
            if (errorMessage.contains('payload too large') || errorMessage.contains('413')) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Ошибка: Фото слишком большое или запрос превысил допустимый размер')));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Ошибка: ${result['error']}')));
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Произошла ошибка: $e')),
          );
        }
      }
    }
  }

  bool _hasProfileChanged() {
    return _emailController.text != _initialProfileData['email'] ||
        _vkController.text != (_initialProfileData['links']?['VK'] ?? '') ||
        _telegramController.text != (_initialProfileData['links']?['Telegram'] ?? '') ||
        _whatsappController.text != (_initialProfileData['links']?['WhatsApp'] ?? '') ||
        _photoBase64 != _initialProfileData['photo'];
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтвердите'),
        content: Text('Вы действительно хотите сохранить изменения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Да'),
          ),
        ],
      ),
    ) ??
        false;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  String? _validateLink(String? value, String platform) {
    if (value == null || value.isEmpty) return null;
    switch (platform) {
      case 'VK':
        final vkRegex = RegExp(r'^(https?:\/\/)?(www\.)?vk\.com\/[\w\.\-_%]+$', caseSensitive: false);
        if (!vkRegex.hasMatch(value)) {
          return 'Введите корректную ссылку на VK';
        }
        break;
      case 'Telegram':
        final tgRegex = RegExp(r'^(https?:\/\/)?(www\.)?t\.me\/[\w\.\-_%]+$', caseSensitive: false);
        if (!tgRegex.hasMatch(value)) {
          return 'Введите корректную ссылку на Telegram';
        }
        break;
      case 'WhatsApp':
        final waRegex = RegExp(r'^(https?:\/\/)?(www\.)?wa\.me\/[\d\.\-_%]+$', caseSensitive: false);
        if (!waRegex.hasMatch(value)) {
          return 'Введите корректную ссылку на WhatsApp';
        }
        break;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Убираем обязательное поле
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  String _formatPhoneNumber(String phone) {
    // Удаляем все символы, кроме цифр
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    // Если номер начинается с 8, заменяем на 7
    if (cleaned.startsWith('8')) {
      cleaned = '7' + cleaned.substring(1);
    }
    // Если номер состоит из 10 цифр, добавляем +7 в начало
    if (cleaned.length == 10) {
      cleaned = '+7$cleaned';
    } else if (cleaned.length == 11) {
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

  Future<void> _changePhoneNumber() async {
    if (_phoneFormKey.currentState?.validate() ?? false) {
      final currentPhone = _phoneController.text.trim();
      if (currentPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Введите новый номер телефона')),
        );
        return;
      }
      // Форматируем номер телефона
      final formattedPhone = _formatPhoneNumber(currentPhone);
      if (formattedPhone == _initialPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Новый номер не отличается от текущего.')),
        );
        return;
      }
      // Показываем диалог подтверждения
      bool confirmed = await _showPhoneChangeConfirmationDialog();
      if (confirmed) {
        // Шаг 1: Отправляем новый номер телефона
        if (_phoneStep == 1) {
          try {
            final step1Result = await PhoneEditService.editPhoneNumber(
              newPhone: formattedPhone,
              step: 1,
              context: context, // Передаем контекст
            );
            if (step1Result['success'] == true) {
              print('Номер телефона успешно отправлен, перенаправляем на ConfirmPhoneScreen');
              setState(() {
                _newPhone = formattedPhone; // Сохраняем новый номер телефона
              });
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfirmPhoneScreen(
                      newPhone: formattedPhone,
                      guid: _guid ?? '', // Используем значение по умолчанию, если guid null
                      deviceId: _deviceId ?? '', // Добавляем deviceId
                      onConfirm: _confirmPhoneNumber, // Добавляем функцию подтверждения
                    ),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: ${step1Result['error']}')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Произошла ошибка: $e')),
              );
            }
          }
        }
      }
    }
  }

  Future<bool> _showPhoneChangeConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтверждение смены номера телефона'),
        content: Text('Вы действительно хотите изменить номер телефона на ${_phoneController.text}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Да'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _confirmPhoneNumber(String code) async {
    if (_newPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Новый номер телефона не задан')),
      );
      return;
    }
    // Шаг 2: Подтверждаем код
    try {
      final step2Result = await PhoneEditService.editPhoneNumber(
        newPhone: _newPhone!,
        step: 2,
        context: context, // Передаем контекст
      );
      if (step2Result['success'] == true) {
        print('Номер телефона успешно подтвержден');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Номер телефона успешно подтвержден')),
        );
        setState(() {
          _phoneController.text = _newPhone!;
          _initialPhone = _newPhone!;
          _newPhone = null; // Сбрасываем новый номер после успешного подтверждения
          _phoneStep = 1; // Сбрасываем шаг после успешного подтверждения
        });
        // Возвращаемся на страницу редактирования профиля
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${step2Result['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Редактировать профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _vkController,
                decoration: InputDecoration(labelText: 'Ссылка на VK'),
                validator: (value) => _validateLink(value, 'VK'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _telegramController,
                decoration: InputDecoration(labelText: 'Ссылка на Telegram'),
                validator: (value) => _validateLink(value, 'Telegram'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: InputDecoration(labelText: 'Ссылка на WhatsApp'),
                validator: (value) => _validateLink(value, 'WhatsApp'),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library),
                label: Text('Выбрать фото'),
              ),
              if (_photoBase64 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_photoBase64!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: Icon(Icons.save),
                label: Text('Сохранить'),
              ),
              SizedBox(height: 16),
              Form(
                key: _phoneFormKey, // Используем отдельный ключ для формы номера телефона
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Номер телефона'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11), // Ограничиваем до 11 цифр
                      ],
                      validator: _validatePhone,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _changePhoneNumber,
                      icon: Icon(Icons.phone),
                      label: Text('Изменить номер телефона'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _vkController.dispose();
    _telegramController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}