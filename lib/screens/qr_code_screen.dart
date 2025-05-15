import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
class QrCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR-код'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(context), // Передаем контекст
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки данных'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Данные пользователя недоступны'));
          } else {
            final userData = snapshot.data!;
            final qrData = _generateQrData(userData);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'ФИО: ${userData['fullName']}', // Используем fullName из данных пользователя
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Пол: ${userData['gender']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Дата рождения: ${userData['birthday'].split('T')[0]}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData(BuildContext context) async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      final deviceId = await authService.getDeviceId(); // Получаем deviceId
      if (guid == null || guid.isEmpty || deviceId == null || deviceId.isEmpty) {
        throw Exception('GUID или deviceId не найдены');
      }
      final uri = Uri(
        scheme: 'https',
        host: 'mw.azs-topline.ru',
        port: 44445,
        path: '/hrm/hs/ewp/getQR',
      );
      final response = await http.get(
        uri,
        headers: {
          ...AuthService.baseHeaders,
          'ma-guid': guid,
          'deviceId': deviceId, // Добавляем deviceId
        },
      ).timeout(Duration(seconds: 10));
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final userData = json['data'];
          userData['fullName'] = '${userData['lastName'] ?? ''} ${userData['firstName'] ?? ''} ${userData['patronymic'] ?? ''}'.trim();
          return userData;
        } else {
          if (json['error'] == 'Выход на других устройствах.') {
            await authService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
            );
            throw Exception('Вы вышли со всех устройств');
          } else {
            throw Exception(json['error'] ?? 'Неизвестная ошибка');
          }
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      return {};
    }
  }

  String _generateQrData(Map<String, dynamic> userData) {
    return jsonEncode({
      'firstName': userData['firstName'] ?? '',
      'lastName': userData['lastName'] ?? '',
      'patronymic': userData['patronymic'] ?? '',
      'gender': userData['gender'] ?? '',
      'birthday': userData['birthday'] ?? '',
      'snils': userData['snils'] ?? '',
    });
  }
}