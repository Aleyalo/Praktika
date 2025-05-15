import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants

class AppsService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<List<Map<String, dynamic>>> getApps() async {
    try {
      final guid = await AuthService().getGUID();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/apps',
      );
      print('Запрос к URI: $uri');
      final response = await http.get(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
      ).timeout(Duration(seconds: 10));
      print('Статус-код ответа: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final apps = List<Map<String, dynamic>>.from(json['data']['list']);
          return apps;
        } else {
          if (json['error'] == 'Выход на других устройствах.') {
            final authService = AuthService();
            await authService.logout();
            throw Exception('Вы вышли со всех устройств');
          } else {
            throw Exception('Ошибка в структуре ответа: ${json['error']}');
          }
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении приложений: $e');
      rethrow;
    }
  }
}