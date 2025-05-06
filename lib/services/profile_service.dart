import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ProfileService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
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
          ...AuthService.baseHeaders,
          'ma-guid': guid,
        },
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        if (json['success'] == true && json['data'] != null) {
          return json['data']; // Изменено: извлекаем данные из поля 'data'
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
