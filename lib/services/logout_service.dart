import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart';

class LogoutService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  static Future<Map<String, dynamic>> exitOtherDevices() async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      final deviceId = await authService.getDeviceId();
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }

      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/exit_other_devices',
      );

      final headers = {
        ...AppConstants.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId,
      };

      final response = await http.put(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('Статус-код выхода со всех устройств: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': json['success'] == true,
          'data': json['data'],
          'error': json['error'] ?? '',
        };
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при выходе со всех устройств: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}