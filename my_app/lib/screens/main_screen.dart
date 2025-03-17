// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../screens/services_screen.dart';
import '../screens/colleagues_screen.dart';
import '../screens/news_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/profile_screen.dart';
import '../services//auth_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late Map<String, dynamic> _user;

  final List<Widget> _screens = [
    ServicesScreen(),
    ColleaguesScreen(),
    NewsScreen(),
    DocumentsScreen(),
    ProfileScreen(user: {}),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('Загрузка данных пользователя...');
      final user = await AuthService().getUserData();
      if (user.isEmpty) {
        print('Данные пользователя отсутствуют.');
      } else {
        print('Данные пользователя успешно загружены: $user');
      }
      setState(() {
        _user = user;
        _screens[4] = ProfileScreen(user: _user);
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.yellow,
        currentIndex: _currentIndex,
        onTap: (index) {
          print('Переключение экрана на индекс: $index');
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Коллеги'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Документы'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}