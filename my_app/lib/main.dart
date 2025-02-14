import 'package:flutter/material.dart';
import './screens/login_screen.dart'; // Импорт экрана входа

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
      home: LoginScreen(), // Указываем начальный экран
    );
  }
}