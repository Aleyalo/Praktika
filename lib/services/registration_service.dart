// lib/services/registration_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class RegistrationService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  // Вспомогательная функция для формирования URI
  Uri _buildUri(String method) {
    final uri = Uri(
      scheme: 'https',
      host: _baseUrl,
      port: _port,
      path: '/hrm/hs/ewp/$method',
    );
    print('Сформированный URI: $uri'); // Логирование URI
    return uri;
  }

  // Метод регистрации пользователя
  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String patronymic,
    required String birthdate,
    required String snils,
    required String login,
    required String password,
  }) async {
    try {
      final uri = _buildUri('registration');
      // Формируем тело запроса
      final formattedSnils = _formatSnils(snils);
      if (formattedSnils == null) {
        throw Exception('Неверный формат СНИЛС');
      }
      final bodyMap = {
        "name": name,
        "surname": surname,
        "patronymic": patronymic,
        "birthdate": birthdate.replaceAll('-', '').replaceAll(' ', ''),
        "snils": formattedSnils.replaceAll('-', '').replaceAll(' ', ''),
        "login": login,
        "password": password,
      };
      // Кодируем тело запроса в Base64
      Codec stringToBase64 = utf8.fuse(base64);
      final body = stringToBase64.encode(jsonEncode(bodyMap));
      print('Тело запроса (Base64): $body'); // Логирование тела запроса
      // Логирование заголовков
      print('Заголовки запроса: ${AppConstants.baseHeaders}');
      final response = await http.post(
        uri,
        headers: AppConstants.baseHeaders,
        body: body,
      );
      print('Статус-код регистрации: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final guid = json['data']['GUID'];
          final status = json['data']['status'];
          // Сохраняем GUID локально
          await _saveModerationGUID(guid);
          return {
            'success': true,
            'guid': guid,
            'status': status,
          };
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при регистрации: $e');
      rethrow;
    }
  }

  // Метод проверки статуса модерации
  Future<Map<String, dynamic>> checkModerationStatus(String guid) async {
    try {
      final uri = _buildUri('moderation');
      // Формируем тело запроса
      final bodyMap = {"GUID": guid};
      // Кодируем тело запроса в Base64
      Codec stringToBase64 = utf8.fuse(base64);
      final body = stringToBase64.encode(jsonEncode(bodyMap));
      print('Тело запроса (Base64): $body'); // Логирование тела запроса
      // Логирование заголовков
      print('Заголовки запроса: ${AppConstants.baseHeaders}');
      final response = await http.post(
        uri,
        headers: AppConstants.baseHeaders,
        body: body,
      );
      print('Статус-код модерации: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final status = json['data']['status'];
          // Если статус не "На модерации", удаляем GUID
          if (status != 'На модерации') {
            await _clearModerationGUID();
          }
          return {
            'success': true,
            'status': status,
          };
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при проверке статуса модерации: $e');
      rethrow;
    }
  }

  // Сохранение GUID модерации
  Future<void> _saveModerationGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('moderation_guid', guid);
    print('GUID модерации сохранен: $guid');
  }

  // Получение GUID модерации
  Future<String?> getModerationGUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('moderation_guid');
  }

  // Удаление GUID модерации
  Future<void> _clearModerationGUID() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moderation_guid');
    print('GUID модерации удален');
  }

  // Метод форматирования СНИЛСа
  String? _formatSnils(String snils) {
    final digits = snils.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) {
      return null;
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, 9)} ${digits.substring(9)}';
  }
}