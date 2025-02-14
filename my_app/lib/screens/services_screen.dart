import 'package:flutter/material.dart';
import '../widgets/service_button.dart'; // Импорт виджета ServiceButton
import '../widgets/service_tile.dart'; // Импорт виджета ServiceTile

class ServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Сервисы'), backgroundColor: Colors.yellow),
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
                ServiceButton(icon: Icons.qr_code, label: 'QR-код'), // Использование ServiceButton
                ServiceButton(icon: Icons.people, label: 'Коллеги'),
                ServiceButton(icon: Icons.article, label: 'Новости'),
                ServiceButton(icon: Icons.build, label: 'Настройки'),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ServiceTile(title: 'АЗС Топлайн'), // Использование ServiceTile
                  ServiceTile(title: 'Euromed Oasis'),
                  ServiceTile(title: 'Люцлер'),
                  ServiceTile(title: 'СервисДеск ИТ-бизнес'),
                  ServiceTile(title: 'Евромед Омск'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}