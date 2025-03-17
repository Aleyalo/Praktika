import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart';
class ColleagueCardService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<Map<String, dynamic>> getColleagueCard(String colleagueGuid) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }

      final uri = Uri(
        scheme: 'https',
        host: 'mw.azs-topline.ru',
        port: 44445,
        path: '/hrm/hs/ewp/card_collegue',
        queryParameters: {'guid_collegue': colleagueGuid},
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

        // Проверяем, что ответ содержит необходимые поля
        if (json is Map<String, dynamic>) {
          return Map<String, dynamic>.from(json); // Возвращаем данные напрямую
        } else {
          throw Exception('Некорректная структура ответа: ожидался объект');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении карточки коллеги: $e');
      rethrow;
    }
  }
}