import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class PhoneEditService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  static Future<Map<String, dynamic>> editPhoneNumber({
    required String newPhone,
    required int step,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID пользователя не найден');
      }

      final bodyMap = {'newPhone': newPhone, 'step': step};
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
          ...AuthService.baseHeaders,
          'ma-guid': guid,
        },
        body: encodedBody,
      );

      print('Статус-код изменения номера телефона: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 409) {
        final decodedResponse = json.decode(response.body);
        return {
          'success': decodedResponse['success'] ?? false,
          'data': decodedResponse['data'],
          'error': decodedResponse['error'] ?? '',
          'allowed': decodedResponse['allowed'] ?? false,
        };
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
