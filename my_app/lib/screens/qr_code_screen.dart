// lib/screens/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QrCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR-код'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
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
                    'ФИО: ${userData['firstName']} ${userData['lastName']} ${userData['patronymic']}\n'
                        'Пол: ${userData['gender']}\n'
                        'Дата рождения: ${userData['birthday'].split('T')[0]}\n'
                        'СНИЛС: ${userData['snils'] ?? 'Не указан'}',
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

  // Метод для получения данных пользователя
  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final authService = AuthService();
      final guid = await authService.getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
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
        },
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Ответ сервера: $json');
        return json;
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      return {};
    }
  }

  // Метод для формирования данных для QR-кода
  String _generateQrData(Map<String, dynamic> userData) {
    return jsonEncode({
      'firstName': userData['firstName'],
      'lastName': userData['lastName'],
      'patronymic': userData['patronymic'],
      'gender': userData['gender'],
      'birthday': userData['birthday'],
      'snils': userData['snils'] ?? '',
    });
  }
}