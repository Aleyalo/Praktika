import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class PrivacyService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<Map<String, bool>> getPrivacySettings() async {
    final guid = await AuthService().getGUID();
    if (guid == null || guid.isEmpty) throw Exception('GUID не найден');

    final uri = Uri(scheme: 'https', host: _baseUrl, port: _port, path: '/hrm/hs/ewp/privacy');
    final response = await http.get(
      uri,
      headers: {
        ...AuthService.baseHeaders,
        'ma-guid': guid,
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode != 200) throw Exception('Ошибка сети');

    final json = jsonDecode(response.body);
    if (json['success'] != true || json['data'] == null) throw Exception(json['error'] ?? 'Неизвестная ошибка');

    final data = json['data'] as Map<String, dynamic>;
    return {
      'number': data['number'] ?? false,
      'birthday': data['birthday'] ?? false,
      'mail': data['mail'] ?? false,
      'links': data['links'] ?? false,
    };
  }

  Future<bool> updatePrivacySettings(Map<String, bool> settings) async {
    final guid = await AuthService().getGUID();
    if (guid == null || guid.isEmpty) throw Exception('GUID не найден');

    final body = base64Encode(utf8.encode(jsonEncode({
      'number': settings['number'] ?? false,
      'birthday': settings['birthday'] ?? false,
      'mail': settings['mail'] ?? false,
      'links': settings['links'] ?? false,
    })));

    final uri = Uri(scheme: 'https', host: _baseUrl, port: _port, path: '/hrm/hs/ewp/edit_privacy');
    final response = await http.post(
      uri,
      headers: {
        ...AuthService.baseHeaders,
        'ma-guid': guid,
      },
      body: body,
    ).timeout(Duration(seconds: 10));

    if (response.statusCode != 200) throw Exception('Ошибка сети');

    final json = jsonDecode(response.body);
    return json['success'] == true && json['data'] == 'Успешно';
  }
}
