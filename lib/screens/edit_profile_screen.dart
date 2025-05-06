import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/profile_edit_service.dart';
import '../services/phone_edit_service.dart';
import '../services/auth_service.dart';
import '../../utils/constants.dart';
import 'confirm_phone_screen.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _vkController = TextEditingController();
  final _telegramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _initialPhone;

  String? _photoBase64;
  final picker = ImagePicker();

  static const int _maxImageSizeInBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userData = await AuthService().getUserData();
      setState(() {
        _emailController.text = userData['email'] ?? '';
        _vkController.text = userData['links']?['VK'] ?? '';
        _telegramController.text = userData['links']?['Telegram'] ?? '';
        _whatsappController.text = userData['links']?['WhatsApp'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _initialPhone = userData['phone'] ?? '';
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
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
    if (value == null || value.isEmpty) return null;

    final phoneRegex = RegExp(r'^[0-9]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Введите корректный номер телефона (только цифры)';
    }
    return null;
  }

  Future<void> _changePhoneNumber() async {
    final currentPhone = _phoneController.text.trim();
    if (currentPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите новый номер телефона')),
      );
      return;
    }

    if (currentPhone == _initialPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Новый номер не отличается от текущего.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтвердите действие'),
          content: Text('Вы действительно хотите изменить номер телефона?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Да'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) return;

    try {
      final result = await PhoneEditService.editPhoneNumber(
        newPhone: currentPhone,
        step: 1,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPhoneScreen(newPhone: currentPhone),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${result['error']}')),
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

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Номер телефона'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      ),
    );
  }
}
