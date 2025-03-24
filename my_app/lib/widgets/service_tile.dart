// lib/widgets/service_tile.dart
import 'package:flutter/material.dart';

class ServiceTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  ServiceTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      color: Colors.green,
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing: Icon(Icons.arrow_forward, color: Colors.white),
        onTap: onTap, // Добавляем обработчик нажатия
      ),
    );
  }
}