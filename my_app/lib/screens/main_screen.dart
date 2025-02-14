import 'package:flutter/material.dart';
import '../screens/services_screen.dart';
import '../screens/colleagues_screen.dart';
import '../screens/news_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/profile_screen.dart';
import '../auth_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late Map<String, String> _user; // Хранилище для данных пользователя

  // Список экранов для навигации
  final List _screens = [
    ServicesScreen(),
    ColleaguesScreen(),
    NewsScreen(),
    DocumentsScreen(),
    ProfileScreen(user: {}), // Заглушка для профиля (пустой Map)
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Загрузка данных пользователя при старте
  }

  // Метод для загрузки данных пользователя
  Future<void> _loadUserData() async {
    try {
      final user = await AuthService().getUserData(); // Получаем данные пользователя
      setState(() {
        _user = user; // Сохраняем данные пользователя
        _screens[4] = ProfileScreen(user: _user); // Обновляем экран профиля
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Отображение текущего экрана
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.yellow,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Обновление индекса выбранного экрана
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