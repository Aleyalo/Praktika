import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import '../screens/login_screen.dart';
import 'package:flutter/material.dart';
class ColleagueCardService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<Map<String, dynamic>> getColleagueCard({required String guidCollegue, required BuildContext context}) async {
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
        path: '/hrm/hs/ewp/card_collegue',
        queryParameters: {
          'guid_collegue': guidCollegue,
        },
      );
      print('Запрос к URI: $uri');
      final response = await http.get(
        uri,
        headers: {
          ...AppConstants.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
      ).timeout(Duration(seconds: 10));
      print('Статус-код ответа: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          final employment = List<Map<String, dynamic>>.from(data['employment'] ?? []);
          final mainJob = employment.firstWhere(
                (job) => job['type'] == 'Основное место работы',
            orElse: () => {},
          );
          if (mainJob.isNotEmpty) {
            employment.remove(mainJob);
            employment.insert(0, mainJob);
          }
          data['employment'] = employment;
          return data; // Изменено: извлекаем данные из поля 'data'
        } else if (json['error'] == 'Выход на других устройствах.') {
          await AuthService().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении данных карточки коллеги: $e');
      rethrow;
    }
  }
}