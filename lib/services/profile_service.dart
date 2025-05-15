import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../screens/login_screen.dart'; // Добавлен импорт
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';
class ProfileService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      final deviceId = await authService.getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/getProfile',
      );
      final response = await http.get(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
      ).timeout(Duration(seconds: 10));
      print('Статус-код получения данных профиля: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return json['data']; // Изменено: извлекаем данные из поля 'data'
        } else if (json['error'] == 'Выход на других устройствах.') {
          await authService.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении данных профиля: $e');
      rethrow;
    }
  }
}