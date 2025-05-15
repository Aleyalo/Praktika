import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../models/colleague.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants

class ColleaguesService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<List<Colleague>> getColleagues({
    String? organizationGuid,
    String? departmentGuid,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final Map<String, String> queryParameters = {};
      if (organizationGuid != null && organizationGuid.isNotEmpty) {
        queryParameters['guidorg'] = organizationGuid;
      }
      if (departmentGuid != null && departmentGuid.isNotEmpty) {
        queryParameters['guidsub'] = departmentGuid;
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/colleagues',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
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
          final colleagues = List<Map<String, dynamic>>.from(json['data'])
              .map((colleague) => Colleague.fromJson(colleague))
              .toList();
          print('Получен список коллег: $colleagues');
          return colleagues;
        } else if (json['error'] == 'Выход на других устройствах.') {
          await AuthService().logout();
          throw Exception('Вы вышли со всех устройств');
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка коллег: $e');
      rethrow;
    }
  }
}