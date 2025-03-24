import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ColleaguesService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  static Map<String, String> _getHeaders(String guid) {
    return {
      ...AuthService.baseHeaders,
      'ma-guid': guid,
    };
  }

  Future<List<Map<String, dynamic>>> getColleagues({
    String? guidOrg,
    String? guidSub,
    int limit = 100,
    int page = 1,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/colleagues',
        queryParameters: {
          if (guidOrg != null) 'guidorg': guidOrg,
          if (guidSub != null) 'guidsub': guidSub,
          'limit': limit.toString(),
          'page': page.toString(),
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
          final uniqueColleagues = <String, Map<String, dynamic>>{};
          for (var colleague in colleagues) {
            final guid = colleague['guid'];
            if (guid != null && !uniqueColleagues.containsKey(guid)) {
              uniqueColleagues[guid] = colleague;
            }
          }
          return uniqueColleagues.values.toList();
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка коллег: $e');
      rethrow;
    }
  }
}