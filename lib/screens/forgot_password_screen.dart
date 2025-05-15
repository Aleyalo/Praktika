import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Импортируем библиотеку для HTTP-запросов
import 'dart:convert'; // Импортируем библиотеку для работы с JSON и Base64
import 'package:flutter/services.dart'; // Импортируем библиотеку для FilteringTextInputFormatter
import '../services/auth_service.dart'; // Импортируем AuthService
import './confirm_phone_screen.dart'; // Импортируем ConfirmPhoneScreen
import '../models/device_info.dart'; // Импортируем DeviceInfo
import '../services/device_info_service.dart'; // Импортируем DeviceInfoService

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  String _errorMessage = '';

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final formattedPhone = _formatPhoneNumber(value);
    if (formattedPhone == null) {
      return 'Неверный формат номера телефона';
    }
    return null;
  }

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
      return cleaned;
    }
    return null;
  }

  Future<void> _requestRecovery(BuildContext context) async {
    final phone = _phoneController.text.trim();
    final formattedPhone = _formatPhoneNumber(phone);
    if (formattedPhone == null) {
      setState(() {
        _errorMessage = 'Неверный формат номера телефона';
      });
      return;
    }

    try {
      // Получаем актуальную информацию об устройстве
      final deviceInfo = await DeviceInfoService.getDeviceInfo(context);
      final bodyMap = {
        "deviceInfo": deviceInfo.toJson(),
        "login": "", // Пустая строка для логина
        "password": "", // Пустая строка для пароля
        "recovery": true,
        "phone": formattedPhone,
      };

      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final uri = Uri(
        scheme: 'https',
        host: 'mw.azs-topline.ru',
        port: 44445,
        path: '/hrm/hs/ewp/authorization',
      );

      print('Запрос к URI: $uri');
      print('Тело запроса (JSON): ${jsonEncode(bodyMap)}'); // Добавляем лог JSON
      print('Тело запроса (Base64): $body');

      final response = await http.post(
        uri,
        headers: {
          ...AuthService.baseHeaders, // Используем основные заголовки
        },
        body: body,
      ).timeout(Duration(seconds: 10));

      print('Статус-код: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final guid = data['person']['guid'] as String?;
          final deviceId = deviceInfo.deviceId as String?;
          if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
            throw Exception('GUID или deviceId отсутствуют в ответе');
          }
          // Сохраняем GUID и deviceId
          await AuthService.saveCredentials('', '', guid, deviceId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPhoneScreen(
                newPhone: formattedPhone,
                guid: guid,
                deviceId: deviceId,
                isRecovery: true, // Устанавливаем флаг восстановления доступа
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = json['error'] ?? 'Неизвестная ошибка';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP-ошибка: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при восстановлении доступа: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Восстановление доступа'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Введите ваш номер телефона для восстановления доступа:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Номер телефона',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _requestRecovery(context),
              child: Text('Отправить код'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}