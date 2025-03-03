import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ColleaguesService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;

  // Получаем заголовки с GUID
  static Map<String, String> _getHeaders(String guid) {
    print('Формирование заголовков с GUID: $guid');
    return {
      ...AuthService.baseHeaders,
      'ma-guid': guid,
    };
  }

  // Метод для получения списка коллег
  Future<List<Map<String, dynamic>>> getColleagues({
    String? guidOrg,
    String? guidSub,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        print('GUID не найден!');
        throw Exception('GUID не найден');
      }

      final uri = Uri(
        scheme: 'https',
        host: 'mw.azs-topline.ru',
        port: _port,
        path: '/hrm/hs/ewp/colleagues',
        queryParameters: {
          if (guidOrg != null) 'guidorg': guidOrg,
          if (guidSub != null) 'guidsub': guidSub,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      print('Запрос к URI: $uri');

      final response = await http.get(uri, headers: _getHeaders(guid));

      print('Статус-код ответа: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        if (json['success'] == true && json['data'] != null) {
          final colleagues = List<Map<String, dynamic>>.from(json['data']['list']);
          print('Получен список коллег: $colleagues');
          return colleagues;
        } else {
          print('Ошибка в структуре ответа: ${json['error']}');
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        print('HTTP-ошибка: ${response.statusCode}, Тело: ${response.body}');
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка коллег: $e');
      rethrow;
    }
  }
}