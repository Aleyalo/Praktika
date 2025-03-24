// lib/screens/services_screen.dart
import 'package:flutter/material.dart';
import '../widgets/service_button.dart'; // Импорт виджета ServiceButton
import '../widgets/service_tile.dart'; // Импорт виджета ServiceTile
import '../screens/qr_code_screen.dart'; // Импорт экрана QR-кода
import '../screens/settings_screen.dart'; // Импорт экрана настроек
import '../services/apps_service.dart'; // Исправленный импорт сервиса для получения приложений
import 'package:flutter/foundation.dart'; // Для defaultTargetPlatform
import 'package:url_launcher/url_launcher.dart'; // Для работы с ссылками

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<Map<String, dynamic>>> _appsFuture;

  @override
  void initState() {
    super.initState();
    _appsFuture = _fetchApps(); // Загружаем данные при старте
  }

  Future<List<Map<String, dynamic>>> _fetchApps() async {
    try {
      final service = AppsService();
      return await service.getApps();
    } catch (e) {
      print('Ошибка при загрузке приложений: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сервисы'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                ServiceButton(
                  icon: Icons.qr_code,
                  label: 'QR-код',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QrCodeScreen()),
                    );
                  },
                ), // Кнопка QR-код
                ServiceButton(
                  icon: Icons.build,
                  label: 'Настройки',
                  onTap: () {
                    // Переход на экран настроек
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ), // Кнопка Настройки
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Ошибка загрузки данных'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Нет данных о сервисах'));
                  } else {
                    final apps = snapshot.data!;
                    return ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return ServiceTile(
                          title: app['name'] ?? 'Без имени',
                          onTap: () => _openAppLink(app), // Открываем ссылку
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для открытия ссылки на приложение
  void _openAppLink(Map<String, dynamic> app) async {
    final platform = defaultTargetPlatform;
    String? url;

    if (platform == TargetPlatform.android) {
      url = app['pathGoogle'];
    } else if (platform == TargetPlatform.iOS) {
      url = app['pathApple'];
    } else if (platform == TargetPlatform.linux || platform == TargetPlatform.windows) {
      url = app['pathWeb'];
    } else if (platform == TargetPlatform.fuchsia) {
      url = app['pathHuawei'];
    }

    // Если ссылка для платформы отсутствует, используем веб-ссылку
    url ??= app['pathWeb'];

    if (url?.isNotEmpty == true) {
      try {
        // Преобразуем nullable String в non-nullable String с помощью проверки
        final uri = Uri.parse(url!); // Используем оператор !, так как проверили url?.isNotEmpty

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку')),
          );
        }
      } catch (e) {
        print('Ошибка при открытии ссылки: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при открытии ссылки')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ссылка недоступна')),
      );
    }
  }
}