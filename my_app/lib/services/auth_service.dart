// lib/http/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;

  static const Map<String, String> baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };

  Future<bool> login(String email, String password) async {
    try {
      final uri = mwUri('authorization');
      Codec stringToBase64 = utf8.fuse(base64);
      final body = stringToBase64.encode(jsonEncode({
        "login": email,
        "password": password,
      }));

      final response = await http.post(
        uri,
        headers: baseHeaders,
        body: body,
      );

      print('Статус-код: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Ответ сервера: ${response.body}');
        return false;
      }

      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        final guid = data['guid'];
        if (guid != null && guid.isNotEmpty) {
          await _saveGUID(guid);

          final employment = data['employment'] as List?;
          final mainJob = employment?.firstWhereOrNull(
                (job) => job['type'] == 'Основное место работы',
          ) ?? {};

          final userData = {
            'name': data['firstName'] ?? '',
            'surname': data['lastName'] ?? '',
            'patronymic': data['patronymic'] ?? '',
            'position': mainJob['post'] ?? '',
            'organization': mainJob['organization_name'] ?? '',
            'department': mainJob['department_name'] ?? '',
            'phone': data['phone'] ?? '',
            'email': data['email'] ?? '',
            'snils': data['snils'] ?? '',
          };

          await _saveUserData(userData);
          return true;
        } else {
          print('GUID отсутствует в ответе');
        }
      } else {
        print('Поле success в ответе: ${json['success']}');
      }
    } catch (e) {
      print('Ошибка при отправке запроса: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> getUserData() async {
    return await _getUserData();
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_data', jsonEncode(userData));
    print('Данные пользователя сохранены: $userData');
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return {};
  }

  Future<void> _saveGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('guid', guid);
    print('GUID сохранен: $guid');
  }

  Future<String?> getGUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('guid');
  }
}

Uri mwUri(String method) {
  return Uri(
    scheme: 'https',
    host: 'mw.azs-topline.ru',
    path: '/hrm/hs/ewp/$method',
    port: 44445,
  );
}
// Расширение AuthService для очистки данных пользователя
extension AuthServiceExtensions on AuthService {
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guid'); // Удаляем GUID
    await prefs.remove('user_data'); // Удаляем данные пользователя
    print('Данные пользователя очищены');
  }
}
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

}