import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ColleaguesRepository {
  static const String _baseUrl = 'https://mw.azs-topline.ru ';
  static const int _port = 44445;

  Future<List<Map<String, dynamic>>> fetchColleagues({
    String? guidOrg,
    String? guidSub,
    int limit = 50,
    int offset = 0, // Изменили page на offset
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
          'offset': offset.toString(), // Изменили page на offset
        },
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
        if (json['success'] == true && json['data'] != null) {
          final colleagues = List<Map<String, dynamic>>.from(json['data']['list']);
          return colleagues;
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