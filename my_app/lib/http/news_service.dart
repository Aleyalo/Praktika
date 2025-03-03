// lib/http/news_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../http/auth_service.dart';

class NewsService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;

  // Получаем заголовки с GUID
  static Map<String, String> _getHeaders(String guid) {
    return {
      ...AuthService.baseHeaders,
      'ma-guid': guid,
    };
  }

  // Метод для получения списка новостей
  Future<List<Map<String, dynamic>>> getNews({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }

      final uri = Uri(
        scheme: 'https',
        host: 'mw.azs-topline.ru',
        port: _port,
        path: '/hrm/hs/ewp/news',
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders(guid));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          if (json['data'] is List) {
            return List<Map<String, dynamic>>.from(json['data']);
          } else {
            throw Exception('Некорректный формат данных: "data" не является списком');
          }
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