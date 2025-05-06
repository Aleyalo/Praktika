import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Для BuildContext и виджетов
import '../../utils/constants.dart';

class AuthService {
  static const String _baseUrl = 'https://mw.azs-topline.ru';
  static const int _port = 44445;
  static const Map<String, String> baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };

  // Метод авторизации пользователя
  Future<bool> login(String email, String password, BuildContext context) async {
    try {
      final uri = mwUri('authorization');
      Codec stringToBase64 = utf8.fuse(base64);
      final bodyMap = {
        "login": email,
        "password": password,
      };
      final body = stringToBase64.encode(jsonEncode(bodyMap));
      print('Запрос к URI: $uri');
      print('Заголовки: $baseHeaders');
      print('Тело запроса: $body');
      final response = await http.post(
        uri,
        headers: baseHeaders,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка авторизации')),
        );
        return false;
      }
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        final guid = data['guid'];
        if (guid != null && guid.isNotEmpty) {
          await _saveCredentials(email, password, guid);
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
            'mainOrganizationGuid': mainJob['organization_guid'] ?? '', // Добавляем GUID основной организации
            'employment': employment, // Сохраняем все места работы
            'guid': guid, // Добавляем GUID пользователя
          };
          await _saveUserData(userData);
          await _saveEmployment(userData['employment']); // Сохраняем места работы
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

  // Метод повторной авторизации по GUID
  Future<bool> reauthorizeByGuid() async {
    try {
      final guid = await getGUID();
      final email = await getEmail();
      final password = await getPassword();
      if (guid == null || guid.isEmpty || email == null || email.isEmpty || password == null || password.isEmpty) {
        throw Exception('GUID, логин или пароль не найдены');
      }
      final uri = mwUri('authorization');
      Codec stringToBase64 = utf8.fuse(base64);
      final bodyMap = {
        "login": email,
        "password": password,
      };
      final body = stringToBase64.encode(jsonEncode(bodyMap));
      final headers = {
        ...AuthService.baseHeaders,
        'ma-guid': guid, // ma-guid не шифруется в Base64
      } as Map<String, String>; // Явное преобразование в Map<String, String>
      print('URI: $uri');
      print('Headers: $headers');
      print('Body: $body');
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код повторной авторизации: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'] as Map<String, dynamic>;
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
            'mainOrganizationGuid': mainJob['organization_guid'] ?? '', // Добавляем GUID основной организации
            'employment': employment, // Сохраняем все места работы
            'guid': data['guid'], // Добавляем GUID пользователя
          };
          await _saveUserData(userData);
          await _saveEmployment(userData['employment']); // Сохраняем места работы
          return true;
        } else {
          print('Поле success в ответе: ${json['success']}');
        }
      } else {
        print('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при повторной авторизации: $e');
    }
    return false;
  }

  // Сохранение данных пользователя
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_data', jsonEncode(userData));
    print('Данные пользователя сохранены: $userData');
  }

  // Получение данных пользователя
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        print('Полученные данные пользователя из SharedPreferences:');
        print('Name: ${userData['name']}');
        print('Surname: ${userData['surname']}');
        print('Patronymic: ${userData['patronymic']}');
        print('Position: ${userData['position']}');
        print('Organization: ${userData['organization']}');
        print('Department: ${userData['department']}');
        print('Phone: ${userData['phone']}');
        print('Email: ${userData['email']}');
        print('Main Organization GUID: ${userData['mainOrganizationGuid']}');
        print('Employment: ${userData['employment']}');
        return userData;
      } catch (e) {
        print('Ошибка при декодировании user_data: $e');
      }
    }
    print('Данные пользователя не найдены в SharedPreferences');
    return {};
  }

  // Сохранение GUID, логина и пароля
  Future<void> _saveCredentials(String email, String password, String guid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('guid', guid);
    prefs.setString('email', email);
    prefs.setString('password', password);
    print('GUID, логин и пароль сохранены');
  }

  // Получение GUID
  Future<String?> getGUID() async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString('guid');
    print('Полученный GUID: $guid');
    return guid;
  }

  // Получение логина
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    print('Полученный логин: $email');
    return email;
  }

  // Получение пароля
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString('password');
    print('Полученный пароль: $password');
    return password;
  }

  // Удаление данных пользователя и учетных данных
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guid');
    await prefs.remove('user_data');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('employment'); // Удаляем места работы
    print('Данные пользователя и учетные данные очищены');
  }

  // Сохранение мест работы
  Future<void> _saveEmployment(List<dynamic>? employment) async {
    final prefs = await SharedPreferences.getInstance();
    if (employment != null) {
      prefs.setString('employment', jsonEncode(employment));
      print('Места работы сохранены: $employment');
    }
  }

  // Получение мест работы
  Future<List<dynamic>> getEmployment() async {
    final prefs = await SharedPreferences.getInstance();
    final employmentString = prefs.getString('employment');
    if (employmentString != null) {
      return jsonDecode(employmentString);
    }
    return [];
  }
}

// Вспомогательная функция для формирования URI
Uri mwUri(String method) {
  return Uri(
    scheme: 'https',
    host: 'mw.azs-topline.ru',
    port: 44445,
    path: '/hrm/hs/ewp/$method',
  );
}

// Расширение для List<T>
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
