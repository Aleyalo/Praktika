// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../models/device_info.dart';
import 'device_info_service.dart';
import '../../utils/constants.dart';

class AuthService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;
  static const Map<String, String> baseHeaders = {
    'Authorization': 'basic 0JDQtNC80LjQvdC60LA6MDk4NzY1NDMyMQ==',
    'ma-key': '0YHQtdC60YDQtdGC0L3Ri9C50LrQu9GO0Yc=',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> newLogin(String login, String password, BuildContext context) async {
    try {
      final deviceInfo = await DeviceInfoService.getDeviceInfo(context);
      print('Собранная информация об устройстве: ${deviceInfo.toJson()}');
      final uri = mwUri('new_authorization');
      final bodyMap = {
        "deviceInfo": deviceInfo.toJson(),
        "login": login,
        "password": password,
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
          };
          // Сохраняем данные здесь
          await _saveCredentials(login, password, guid, deviceId);
          if (askHim != null && oktell) {
            return {
              'success': true,
              'data': data,
              'guid': guid,
              'deviceId': deviceId,
              'askHim': askHim,
            };
          } else {
            // Если блока askHim нет, сразу сохраняем данные и переходим на главный экран
            await _saveUserData(userData);
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

  Future<bool> confirmDevice({required String code, required String login, required String password, required String deviceId, required BuildContext context}) async {
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
          };
          await _saveUserData(userData);
          await _saveCredentials(login, password, guid, deviceId);
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
    print('Данные пользователя удалены');
  }
}

Uri mwUri(String method) {
  return Uri(
    scheme: 'https',
    host: AppConstants.baseUrl,
    port: AppConstants.port,
    path: '/hrm/hs/ewp/$method',
  );
}