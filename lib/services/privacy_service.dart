import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../screens/login_screen.dart'; // Добавлен импорт
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';
class PrivacyService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<Map<String, bool>> getPrivacySettings() async {
    final guid = await AuthService().getGUID();
    final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
    if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) throw Exception('GUID или deviceId не найдены');
    final uri = Uri(scheme: 'https', host: _baseUrl, port: _port, path: '/hrm/hs/ewp/privacy');
    final response = await http.get(
      uri,
      headers: {
        ...AppConstants.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId, // Добавляем deviceId
      },
    ).timeout(Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Ошибка сети');
    final json = jsonDecode(response.body);
    if (json['success'] != true || json['data'] == null) throw Exception(json['error'] ?? 'Неизвестная ошибка');
    final data = json['data'] as Map<String, dynamic>;
    return {
      'number': data['number'] ?? false,
      'birthday': data['birthday'] ?? false,
      'mail': data['mail'] ?? false,
      'links': data['links'] ?? false,
    };
  }

  Future<bool> updatePrivacySettings({
    required Map<String, bool> settings,
    required BuildContext context, // Добавляем контекст
  }) async {
    final guid = await AuthService().getGUID();
    final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
    if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) throw Exception('GUID или deviceId не найдены');
    final body = base64Encode(utf8.encode(jsonEncode({
      'number': settings['number'] ?? false,
      'birthday': settings['birthday'] ?? false,
      'mail': settings['mail'] ?? false,
      'links': settings['links'] ?? false,
    })));
    final uri = Uri(scheme: 'https', host: _baseUrl, port: _port, path: '/hrm/hs/ewp/edit_privacy');
    final response = await http.post(
      uri,
      headers: {
        ...AppConstants.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId, // Добавляем deviceId
      },
      body: body,
    ).timeout(Duration(seconds: 10));
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      if (json['error'] == 'Выход на других устройствах.') {
        await AuthService().logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
        throw Exception('Вы вышли со всех устройств');
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body);
    return json['success'] == true && json['data'] == 'Успешно';
  }
}