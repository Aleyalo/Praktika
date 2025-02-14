import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;

  // Основные заголовки
  static const Map<String, String> _baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };

  // Метод для авторизации пользователя
  Future<bool> login(String email, String password) async {

    try {
      final uri = mwUri('authorization');

      // Кодируем данные в Base64
      Codec stringToBase64 = utf8.fuse(base64);
      final body = stringToBase64.encode(jsonEncode({
        "login": email,
        "password": password,
      }));

      // Отправляем POST-запрос
      final response = await http.post(
        uri,
        headers: _baseHeaders,
        body: body,
      );

      print('Статус-код: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Ответ сервера: ${response.body}');
        return false;
      }

      final json = jsonDecode(response.body);

      // Проверяем структуру JSON
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        final guid = data['guid'];

        if (guid != null && guid.isNotEmpty) {
          _saveGUID(guid); // Сохраняем GUID
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

  // Метод для получения данных пользователя
  Future<Map<String, String>> getUserData() async {
    try {
      final guid = await _getGUID();
      if (guid == null || guid.isEmpty) {
        print('GUID не найден');
        return {};
      }

      final uri = mwUri('userData'); // Используйте правильный эндпоинт

      final response = await http.get(
        uri,
        headers: {
          ..._baseHeaders,
          'ma-guid': guid, // Добавляем ma-guid в заголовки
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        return {
          'name': userData['firstName'] ?? '',
          'surname': userData['lastName'] ?? '',
          'patronymic': userData['patronymic'] ?? '',
          'position': userData['employment'][0]['post'] ?? '', // Берем первую должность
          'organization': userData['employment'][0]['organization_name'] ?? '', // Берем первую организацию
          'department': userData['employment'][0]['department_name'] ?? '', // Берем первый отдел
          'phone': '', // Добавьте соответствующее поле, если оно есть
          'email': '', // Добавьте соответствующее поле, если оно есть
          'snils': '', // Добавьте соответствующее поле, если оно есть
        };
      } else {
        print('Ошибка при получении данных пользователя: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          print('Сообщение ошибки: ${errorData['message']}');
        } catch (e) {
          print('Ошибка при декодировании ответа: $e');
        }
      }
    } catch (e) {
      print('Ошибка при получении данных пользователя: $e');
    }
    return {};
  }

  Future<void> _saveGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('guid', guid);
    print('GUID сохранен: $guid');
  }

  Future<String?> _getGUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('guid');
  }
}
Uri mwUri(String method) {
  return Uri(
    scheme: 'https',
    host: 'mw.azs-topline.ru',
    path: '/hrm/hs/ewp/$method', // Убедитесь, что путь корректен
    port: 44445,
  );
}