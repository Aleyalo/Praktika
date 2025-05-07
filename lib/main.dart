// lib/main.dart
import 'package:flutter/material.dart';
import './screens/login_screen.dart'; // Импорт экрана входа
import './screens/main_screen.dart'; // Импорт главного экрана
import './services/auth_service.dart'; // Импорт AuthService

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Company App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: FutureBuilder<bool>(
        future: _checkCredentials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data == true) {
            return MainScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }

  // Метод для проверки наличия сохраненных учетных данных
  Future<bool> _checkCredentials() async {
    final authService = AuthService();
    final guid = await authService.getGUID();
    final email = await authService.getEmail();
    final password = await authService.getPassword();
    print('Проверка учетных данных: GUID=$guid, Email=$email, Password=$password');
    return guid != null && guid.isNotEmpty && email != null && email.isNotEmpty && password != null && password.isNotEmpty;
  }
}