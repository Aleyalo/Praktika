import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;

  // Основные заголовки
  static const Map<String, String> baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };

  // Метод для авторизации пользователя
  Future<bool> login(String email, String password) async {
    try {
      print('Попытка авторизации...');
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
        headers: baseHeaders,
        body: body,
      );

      print('Статус-код авторизации: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Ошибка авторизации: ${response.body}');
        return false;
      }

      final json = jsonDecode(response.body);

      // Проверяем структуру JSON
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        final guid = data['guid'];

        if (guid != null && guid.isNotEmpty) {
          await _saveGUID(guid); // Сохраняем GUID
          print('GUID успешно сохранен: $guid');

          // Ищем запись с "type": "Основное место работы"
          final employment = data['employment'] as List<dynamic>;
          final mainJob = employment.firstWhereOrNull(
                (job) => job['type'] == 'Основное место работы',
          ) ?? {}; // Если не найдено, используем пустой объект

          // Сохраняем данные пользователя
          final userData = {
            'name': data['firstName'] ?? '',
            'surname': data['lastName'] ?? '',
            'patronymic': data['patronymic'] ?? '',
            'position': mainJob['post'] ?? '', // Берем должность основного места работы
            'organization': mainJob['organization_name'] ?? '', // Берем организацию основного места работы
            'department': mainJob['department_name'] ?? '', // Берем отдел основного места работы
            'phone': '', // Добавьте соответствующее поле, если оно есть
            'email': '', // Добавьте соответствующее поле, если оно есть
            'snils': '', // Добавьте соответствующее поле, если оно есть
          };

          await _saveUserData(userData); // Сохраняем данные пользователя
          print('Данные пользователя успешно сохранены.');
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

  // Метод для получения данных пользователя из локального хранилища
  Future<Map<String, dynamic>> getUserData() async {
    return await _getUserData();
  }

  // Сохранение данных пользователя
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_data', jsonEncode(userData));
    print('Данные пользователя сохранены: $userData');
  }

  // Получение данных пользователя из локального хранилища
  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return {};
  }

  // Сохранение GUID
  Future<void> _saveGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('guid', guid);
    print('GUID сохранен: $guid');
  }

  // Получение GUID
  Future<String?> getGUID() async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString('guid');
    print('Получен GUID: $guid');
    return guid;
  }
}

// Создание URI для API
Uri mwUri(String method) {
  return Uri(
    scheme: 'https',
    host: 'mw.azs-topline.ru',
    path: '/hrm/hs/ewp/$method', // Убедитесь, что путь корректен
    port: 44445,
  );
}

// Расширение для List, чтобы добавить метод firstWhereOrNull
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}