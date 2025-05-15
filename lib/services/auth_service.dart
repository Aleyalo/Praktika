import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../models/device_info.dart';
import 'device_info_service.dart';
import '../../utils/constants.dart';
import '../screens/confirm_phone_screen.dart'; // Импорт ConfirmPhoneScreen

class AuthService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;
  static const Map<String, String> baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static NavigatorState? get navigator => navigatorKey.currentState;

  Future<Map<String, dynamic>> newLogin(String login, String password, BuildContext context) async {
    try {
      final deviceInfo = await DeviceInfoService.getDeviceInfo(context);
      print('Собранная информация об устройстве: ${deviceInfo.toJson()}');
      final uri = mwUri('authorization');
      final bodyMap = {
        "deviceInfo": deviceInfo.toJson(),
        "login": login,
        "password": password,
        "recovery": false,
        "phone": ""
      };
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      print('Запрос к URI: $uri');
      print('Тело запроса (Base64): $body');
      final response = await http.post(
        uri,
        headers: baseHeaders,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final askHim = data['askHim'];
          final oktell = askHim?['oktell'] ?? false;
          final guid = data['person']['guid'] as String?;
          final deviceId = deviceInfo.deviceId; // Используем deviceId из данных устройства
          if (guid == null || guid.isEmpty || deviceId.isEmpty) {
            throw Exception('GUID или deviceId отсутствуют в ответе');
          }
          final personData = data['person'];
          final employment = List<Map<String, dynamic>>.from(personData['employment'] ?? []);
          final mainJob = employment.firstWhere(
                (job) => job['type'] == 'Основное место работы',
            orElse: () => {},
          );
          final userData = {
            'guid': personData['guid'],
            'firstName': personData['firstName'] ?? '',
            'lastName': personData['lastName'] ?? '',
            'patronymic': personData['patronymic'] ?? '',
            'employment': employment,
            'position': mainJob['post'] ?? '',
            'organization': mainJob['organization_name'] ?? '',
            'department': mainJob['department_name'] ?? '',
            'mainOrganizationGuid': mainJob['organization_guid'] ?? '',
            'askHim': askHim, // Сохраняем askHim в userData
            'deviceId': deviceId, // Сохраняем deviceId в userData
          };
          // Сохраняем данные здесь
          await _saveCredentials(login, password, guid, deviceId);
          await _saveUserData(userData);
          if (askHim != null && oktell) {
            return {
              'success': true,
              'data': data,
              'guid': guid,
              'deviceId': deviceId,
              'askHim': askHim,
            };
          } else {
            // Если блока askHim нет, сразу переходим на главный экран
            return {
              'success': true,
              'data': data,
              'guid': guid,
              'deviceId': deviceId,
              'askHim': null,
            };
          }
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка авторизации');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при авторизации: $e');
      rethrow;
    }
  }

  Future<bool> confirmDevice({
    required String code,
    required String login,
    required String password,
    required String deviceId,
    required BuildContext context,
  }) async {
    try {
      final guid = await getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }
      final uri = mwUri('device_confirmed');
      final bodyMap = {
        "code": code,
      };
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final headers = {
        ...AuthService.baseHeaders,
        'ma-guid': guid,
        'deviceId': deviceId,
      };
      print('Подтверждение устройства: $uri');
      print('Headers: $headers');
      print('Body: $body');
      final response = await http.put(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код подтверждения: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        // Проверяем, пустое ли тело ответа
        if (response.body.isEmpty) {
          print('Тело ответа пустое, считаем подтверждение успешным');
          return true;
        }
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final person = data['person'];
          final employment = List<Map<String, dynamic>>.from(person['employment'] ?? []);
          final mainJob = employment.firstWhere(
                (job) => job['type'] == 'Основное место работы',
            orElse: () => {},
          );
          final userData = {
            'guid': person['guid'],
            'firstName': person['firstName'] ?? '',
            'lastName': person['lastName'] ?? '',
            'patronymic': person['patronymic'] ?? '',
            'phone': person['phone'] ?? '',
            'email': person['email'] ?? '',
            'snils': person['snils'] ?? '',
            'position': mainJob['post'] ?? '',
            'organization': mainJob['organization_name'] ?? '',
            'department': mainJob['department_name'] ?? '',
            'mainOrganizationGuid': mainJob['organization_guid'] ?? '',
            'employment': employment,
            'askHim': null, // Убираем askHim после подтверждения
            'deviceId': deviceId, // Сохраняем deviceId в userData
          };
          await _saveUserData(userData);
          return true;
        } else {
          throw Exception(json['error'] ?? 'Ошибка подтверждения устройства');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка подтверждения устройства: $e');
      rethrow;
    }
  }

  Future<bool> backgroundLogin() async {
    try {
      final email = await getEmail();
      final password = await getPassword();
      final guid = await getGUID();
      final deviceId = await getDeviceId();
      if (email == null || email.isEmpty || password == null || password.isEmpty || guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        return false;
      }
      final deviceInfo = await DeviceInfoService.getDeviceInfo(null); // Получаем актуальную информацию об устройстве без контекста
      final uri = mwUri('authorization');
      final bodyMap = {
        "deviceInfo": deviceInfo.toJson(),
        "login": email,
        "password": password,
        "recovery": false,
        "phone": ""
      };
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final headers = {
        ...AuthService.baseHeaders,
        'ma-guid': guid,
      };
      print('Фоновая авторизация: $uri');
      print('Headers: $headers');
      print('Body: $body');
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код фоновой авторизации: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final askHim = data['askHim'];
          final oktell = askHim?['oktell'] ?? false;
          final person = data['person'];
          final employment = List<Map<String, dynamic>>.from(person['employment'] ?? []);
          final mainJob = employment.firstWhere(
                (job) => job['type'] == 'Основное место работы',
            orElse: () => {},
          );
          final userData = {
            'guid': person['guid'],
            'firstName': person['firstName'] ?? '',
            'lastName': person['lastName'] ?? '',
            'patronymic': person['patronymic'] ?? '',
            'phone': person['phone'] ?? '',
            'email': person['email'] ?? '',
            'snils': person['snils'] ?? '',
            'position': mainJob['post'] ?? '',
            'organization': mainJob['organization_name'] ?? '',
            'department': mainJob['department_name'] ?? '',
            'mainOrganizationGuid': mainJob['organization_guid'] ?? '',
            'employment': employment,
            'askHim': askHim, // Сохраняем askHim в userData
            'deviceId': deviceInfo.deviceId, // Сохраняем deviceId в userData
          };
          if (askHim != null && oktell) {
            // Сохраняем временные данные пользователя
            await _saveCredentials(email, password, guid, deviceId);
            await _saveUserData(userData);
            // Перенаправляем на ConfirmPhoneScreen без BuildContext
            // Это нужно сделать через навигацию из основного потока, так как мы не можем использовать BuildContext в фоновом режиме
            WidgetsFlutterBinding.ensureInitialized();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AuthService.navigator?.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ConfirmPhoneScreen(
                    newPhone: email,
                    guid: guid,
                    deviceId: deviceId,
                  ),
                ),
              );
            });
            return false; // Возвращаем false, так как пользователь перенаправлен на другой экран
          } else {
            await _saveCredentials(email, password, guid, deviceId);
            await _saveUserData(userData);
            return true;
          }
        } else if (json['error'] == 'Выход на других устройствах.') {
          await logout();
          return false;
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка авторизации');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при фоновой авторизации: $e');
      return false;
    }
  }

  Future<void> _saveCredentials(String email, String password, String guid, String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setString('guid', guid);
    await prefs.setString('deviceId', deviceId);
    print('Учетные данные сохранены');
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    print('Данные пользователя сохранены');
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return {};
  }

  Future<String?> getGUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('guid');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password');
  }

  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deviceId');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guid');
    await prefs.remove('user_data');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('deviceId');
    await prefs.remove('moderation_guid'); // Удаляем GUID модерации при выходе
    print('Данные пользователя удалены');
  }

  Future<DeviceInfo> getDeviceInfo(BuildContext? context) async {
    return await DeviceInfoService.getDeviceInfo(context);
  }

  static Future<void> saveCredentials(String email, String password, String guid, String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setString('guid', guid);
    await prefs.setString('deviceId', deviceId);
    print('Учетные данные сохранены');
  }

  static Uri mwUri(String method) {
    return Uri(
      scheme: 'https',
      host: _baseUrl,
      port: _port,
      path: '/hrm/hs/ewp/$method',
    );
  }

  // Новые методы для работы с GUID модерации
  static Future<String?> getModerationGUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('moderation_guid');
  }

  Future<void> saveModerationGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('moderation_guid', guid);
    print('GUID модерации сохранен: $guid');
  }

  static Future<void> clearModerationGUID() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moderation_guid');
    print('GUID модерации удален');
  }
}