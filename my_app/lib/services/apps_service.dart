// lib/http/apps_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart';
class AppsService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<List<Map<String, dynamic>>> getApps() async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }

      // Корректное формирование URI с портом
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
        },
      ).timeout(Duration(seconds: 10));

      print('Статус-код ответа: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');

        if (json['success'] == true && json['data'] != null) {
          final apps = List<Map<String, dynamic>>.from(json['data']['list']);
          print('Получен список приложений: $apps');
          return apps;
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
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