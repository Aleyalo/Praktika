import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../screens/login_screen.dart'; // Добавлен импорт
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';

class PhoneEditService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  static Future<Map<String, dynamic>> editPhoneNumber({
    required String newPhone,
    required int step,
    required BuildContext context, // Добавляем контекст
  }) async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      final deviceId = await authService.getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID пользователя или deviceId не найдены');
      }
      // Форматируем номер телефона
      String formattedPhone = newPhone.replaceAll(RegExp(r'\D'), ''); // Удаляем все символы, кроме цифр
      if (formattedPhone.startsWith('8')) {
        formattedPhone = '7' + formattedPhone.substring(1); // Заменяем 8 на 7
      }
      if (formattedPhone.length == 10) {
        formattedPhone = '+7$formattedPhone';
      } else if (formattedPhone.length == 11) {
        formattedPhone = '+$formattedPhone';
      }
      if (formattedPhone.length == 12) {
        formattedPhone = formattedPhone.replaceFirstMapped(RegExp(r'^(\+\d{1})(\d{3})(\d{3})(\d{2})(\d{2})$'), (match) {
          return '${match[1]} (${match[2]}) ${match[3]}-${match[4]}-${match[5]}';
        });
      }
      final bodyMap = {
        'newPhone': formattedPhone,
        'step': step,
      };
      final encodedBody = base64.encode(utf8.encode(json.encode(bodyMap)));
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/edit_number_profile',
      );
      final response = await http.post(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
        body: encodedBody,
      ).timeout(Duration(seconds: 10));
      print('Статус-код изменения номера телефона: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 409) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'],
            'error': '',
            'allowed': decodedResponse['allowed'] ?? false,
          };
        } else if (decodedResponse['error'] == 'Выход на других устройствах.') {
          await authService.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          return {
            'success': false,
            'data': decodedResponse['data'],
            'error': decodedResponse['error'] ?? '',
            'allowed': decodedResponse['allowed'] ?? false,
          };
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при изменении номера телефона: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}