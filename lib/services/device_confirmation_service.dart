import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'package:flutter/material.dart'; // Для BuildContext
import '../../utils/constants.dart';

class DeviceConfirmationService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  static Future<Map<String, dynamic>> confirmDevice({
    required String code,
    required String deviceId, // deviceId уже передается как параметр
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final bodyMap = {'code': code};
      final encodedBody = base64.encode(utf8.encode(json.encode(bodyMap)));
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/device_confirmed',
      );
      final headers = {
        ...AppConstants.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId,
      };
      final response = await http.put(
        uri,
        headers: headers,
        body: encodedBody,
      );
      print('Статус-код подтверждения устройства: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
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
      print('Ошибка при подтверждении устройства: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}