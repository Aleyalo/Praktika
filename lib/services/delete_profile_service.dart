import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class DeleteProfileService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<bool> deleteProfile() async {
    try {
      final guid = await AuthService().getGUID();
      final email = await AuthService().getEmail();
      final password = await AuthService().getPassword();
      if (guid == null || guid.isEmpty || email == null || email.isEmpty || password == null || password.isEmpty) {
        throw Exception('GUID, логин или пароль не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/deleteProfile',
      );
      final bodyMap = {
        "login": email,
        "password": password,
      };
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final headers = {
        ...AuthService.baseHeaders,
        'ma-guid': guid, // ma-guid не шифруется в Base64
      } as Map<String, String>; // Явное преобразование в Map<String, String>
      print('URI: $uri');
      print('Headers: $headers');
      print('Body: $body');
      final response = await http.delete(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код удаления профиля: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return true;
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении профиля: $e');
      rethrow;
    }
  }
}
