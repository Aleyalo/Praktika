import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department.dart';
import '../services/auth_service.dart';

class DepartmentsService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  Future<List<Department>> getDepartments({
    required String organizationGuid,
  }) async {
    try {
      print('Getting departments for organization: $organizationGuid');
      final userGuid = await AuthService().getGUID();
      if (userGuid == null || userGuid.isEmpty) {
        throw Exception('GUID пользователя не найден');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/departments',
      );
      final headers = {
        ...AuthService.baseHeaders,
        'ma-guid': userGuid,
        'guid-org': organizationGuid,
      };
      print('Request headers: $headers');
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: 10));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final departmentsJson = List<Map<String, dynamic>>.from(json['data']);
          print('Parsed departments: $departmentsJson');
          final departments = departmentsJson.map((json) {
            try {
              return Department.fromJson(json);
            } catch (e) {
              print('Error parsing department: $e');
              return Department(guid: '', name: 'Error');
            }
          }).toList();
          return departments.where((d) => d.guid.isNotEmpty).toList();
        } else {
          throw Exception(json['error'] ?? 'Неизвестная ошибка');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting departments: $e');
      rethrow;
    }
  }
}
