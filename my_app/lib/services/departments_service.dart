import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class Department {
  final String guid;
  final String name;

  Department({required this.guid, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      guid: json['guid'] as String,
      name: json['name'] as String,
    );
  }
}

class DepartmentsService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<List<Department>> getDepartments({
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/departments',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      print('Запрос к URI: $uri');
      final response = await http.get(
        uri,
        headers: {
          ...AuthService.baseHeaders,
          'ma-guid': guid,
        },
      ).timeout(Duration(seconds: 10));
      print('Статус-код ответа: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        if (json['success'] == true && json['data'] != null) {
          final departments = List<Map<String, dynamic>>.from(json['data']['list'])
              .map((dep) => Department.fromJson(dep))
              .toList();
          print('Получен список подразделений: $departments');
          return departments;
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении списка подразделений: $e');
      rethrow;
    }
  }
}