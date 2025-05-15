import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
class DeleteProfileService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<bool> deleteProfile(BuildContext context) async {
    try {
      final guid = await AuthService().getGUID();
      final email = await AuthService().getEmail();
      final password = await AuthService().getPassword();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || email == null || email.isEmpty || password == null || password.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID, логин, пароль или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/deleteProfile',
      );
      final bodyMap = {
        "login": email,
        "password": password,
      };
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final headers = {
        ...AppConstants.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId, // Добавляем deviceId
      } as Map<String, String>;
      print('URI: $uri');
      print('Headers: $headers');
      print('Body: $body');
      final response = await http.delete(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код удаления профиля: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return true;
        } else if (json['error'] == 'Выход на других устройствах.') {
          await AuthService().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении профиля: $e');
      rethrow;
    }
  }
}