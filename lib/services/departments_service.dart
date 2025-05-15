import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department.dart';
import '../services/auth_service.dart';
import '../../utils/constants.dart'; // Добавлен импорт AppConstants
import '../screens/login_screen.dart';
import 'package:flutter/material.dart';
class DepartmentsService {
  static const String _baseUrl = AppConstants.baseUrl;
  static const int _port = AppConstants.port;

  Future<List<Department>> getDepartments({
    required String organizationGuid,
    required BuildContext context,
  }) async {
    try {
      print('Getting departments for organization: $organizationGuid');
      final userGuid = await AuthService().getGUID();
      final deviceId = await AuthService().getDeviceId(); // Получаем deviceId
      if (userGuid == null || userGuid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID пользователя или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/departments',
      );
      final headers = {
        ...AppConstants.baseHeaders,
        'ma-guid': userGuid,
        'guid-org': organizationGuid,
        'deviceId': deviceId, // Добавляем deviceId
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
      print('Error getting departments: $e');
      rethrow;
    }
  }
}