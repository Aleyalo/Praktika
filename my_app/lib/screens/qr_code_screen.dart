// lib/screens/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import 'dart:convert';

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
                    'ФИО: ${userData['surname']} ${userData['name']} ${userData['patronymic']}\n'
                        'Организация: ${userData['organization']}\n'
                        'Подразделение: ${userData['department']}\n'
                        'Телефон: ${userData['phone'] ?? 'Не указан'}',
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
      final userData = await authService.getUserData();
      final guid = await authService.getGUID();
      userData['guid'] = guid; // Добавляем GUID к данным пользователя
      return userData;
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      return {};
    }
  }

  // Метод для формирования данных для QR-кода
  String _generateQrData(Map<String, dynamic> userData) {
    return jsonEncode({
      'fio': '${userData['surname']} ${userData['name']} ${userData['patronymic']}',
      'guid': userData['guid'],
      'organization': userData['organization'],
      'department': userData['department'],
      'phone': userData['phone'] ?? '',
    });
  }
}