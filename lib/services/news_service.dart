import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../screens/login_screen.dart'; // Добавлен импорт
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';
class NewsService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  static Map<String, String> _getHeaders(String guid, String deviceId) {
    return {
      ...AppConstants.baseHeaders,
      'ma-guid': guid,
      'deviceId': deviceId, // Добавляем deviceId
    };
  }

  Future<List<Map<String, dynamic>>> getNews({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    required BuildContext context, // Добавляем контекст
  }) async {
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
        path: '/hrm/hs/ewp/news',
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
          if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        },
      );
      print('Запрос к URI: $uri');
      final response = await http.get(uri, headers: _getHeaders(guid, deviceId));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          if (json['data'] is List) {
            return List<Map<String, dynamic>>.from(json['data']);
          } else {
            throw Exception('Некорректный формат данных: "data" не является списком');
          }
        } else if (json['error'] == 'Выход на других устройствах.') {
          await authService.logout();
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
      print('Ошибка при получении новостей: $e');
      rethrow;
    }
  }
}