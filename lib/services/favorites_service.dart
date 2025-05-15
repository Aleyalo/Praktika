import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
class FavoritesService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  // Метод для добавления сотрудника в избранное
  Future<bool> addToFavorites({required String guidSelected, required BuildContext context}) async {
    try {
      final guid = await AuthService().getGUID();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/addSelected',
      );
      final bodyMap = {"guid_selected": guidSelected};
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final response = await http.post(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код добавления в избранное: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return true;
        } else if (json['error'] == 'Выход на других устройствах.') {
          await AuthService().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else if (response.statusCode == 409) {
        final json = jsonDecode(response.body);
        if (json['error'] == 'Пользователь уже в избранном') {
          print('Пользователь уже в избранном');
          return true; // Возвращаем true, чтобы состояние осталось без изменений
        } else {
          throw Exception('HTTP-ошибка: ${response.statusCode}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при добавлении в избранное: $e');
      rethrow;
    }
  }

  // Метод для удаления сотрудника из избранного
  Future<bool> removeFromFavorites({required String guidSelected, required BuildContext context}) async {
    try {
      final guid = await AuthService().getGUID();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/deleteSelected',
      );
      final bodyMap = {"guid_selected": guidSelected};
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final response = await http.post(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код удаления из избранного: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return true;
        } else if (json['error'] == 'Выход на других устройствах.') {
          await AuthService().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else if (response.statusCode == 404) {
        final json = jsonDecode(response.body);
        if (json['error'] == 'Пользователя нет в избранном') {
          print('Пользователя нет в избранном');
          return true; // Возвращаем true, чтобы состояние осталось без изменений
        } else {
          throw Exception('HTTP-ошибка: ${response.statusCode}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении из избранного: $e');
      rethrow;
    }
  }
}