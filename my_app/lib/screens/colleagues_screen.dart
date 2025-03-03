import 'package:flutter/material.dart';
import '../http/colleagues_service.dart';

class ColleaguesScreen extends StatefulWidget {
  @override
  _ColleaguesScreenState createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  late Future<List<Map<String, dynamic>>> _colleaguesFuture;

  @override
  void initState() {
    super.initState();
    _colleaguesFuture = _fetchColleagues(); // Загружаем данные при старте
  }

  // Метод для получения списка коллег
  Future<List<Map<String, dynamic>>> _fetchColleagues() async {
    try {
      print('Начинаем загрузку списка коллег...');
      final colleaguesService = ColleaguesService();
      final colleagues = await colleaguesService.getColleagues(limit: 50, offset: 0);
      print('Список коллег успешно загружен.');
      return colleagues;
    } catch (e) {
      print('Ошибка при загрузке коллег: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Коллеги'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _colleaguesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Ожидание данных...');
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Произошла ошибка: ${snapshot.error}');
            return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('Нет данных о коллегах.');
            return Center(child: Text('Нет данных о коллегах'));
          } else {
            final colleagues = snapshot.data!;
            print('Выводим список коллег.');

            return ListView.builder(
              itemCount: colleagues.length,
              itemBuilder: (context, index) {
                final colleague = colleagues[index];
                return ListTile(
                  leading: Text('${index + 1}.'), // Добавляем нумерацию
                  title: Text(colleague['name'] ?? 'Без имени'), // Отображаем имя коллеги
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выбран коллега: ${colleague['name'] ?? 'Без имени'}')),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}