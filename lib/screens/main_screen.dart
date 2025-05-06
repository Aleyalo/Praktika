import 'package:flutter/material.dart';
import '../screens/services_screen.dart';
import '../screens/colleagues_screen.dart';
import '../screens/news_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart'; // Импортируем LoginScreen
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late Map<String, dynamic> _user;
  late List<Widget> _screens; // Инициализируем _screens сразу

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Добавляем наблюдатель
    _initializeScreens(); // Инициализируем _screens сразу
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Удаляем наблюдатель
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Выполняем повторную авторизацию при возвращении в приложение
      _reauthorize();
    }
  }

  Future<void> _reauthorize() async {
    final authService = AuthService();
    final isLoggedIn = await authService.reauthorizeByGuid();
    if (!isLoggedIn) {
      // Если повторная авторизация не удалась, выходим из приложения
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    }
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
        _screens[4] = ProfileScreen(user: _user); // Обновляем профильный экран с новыми данными пользователя
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
    }
  }

  void _initializeScreens() {
    _screens = [
      ServicesScreen(),
      ColleaguesScreen(),
      NewsScreen(),
      DocumentsScreen(),
      ProfileScreen(user: {}), // Инициализируем с пустыми данными пользователя
    ];
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