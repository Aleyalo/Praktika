import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class ModerationService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  // Вспомогательная функция для формирования URI
  Uri _buildUri(String method) {
    return Uri(
      scheme: 'https',
      host: _baseUrl,
      port: _port,
      path: '/hrm/hs/ewp/$method',
    );
  }

  // Метод регистрации пользователя
  Future<Map<String, dynamic>> registerUser({
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
      final bodyMap = {
        "name": name,
        "surname": surname,
        "patronymic": patronymic,
        "birthdate": birthdate,
        "snils": snils,
        "login": login,
        "password": password,
      };

      // Кодируем тело запроса в Base64
      Codec stringToBase64 = utf8.fuse(base64);
      final body = stringToBase64.encode(jsonEncode(bodyMap));

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
          return {
            'success': true,
            'data': json['data'],
            'error': '',
          };
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при регистрации пользователя: $e');
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
          final status = json['data'];

          // Если статус отличается от "На модерации", удаляем GUID
          if (status != 'На модерации') {
            await clearModerationGUID();
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
  Future<void> saveModerationGUID(String guid) async {
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
  Future<void> clearModerationGUID() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moderation_guid');
    print('GUID модерации удален');
  }
}
