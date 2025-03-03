// lib/screens/news_detail_screen.dart

import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новость'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок новости
            Text(
              news['title'] ?? 'Без заголовка',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Изображение новости (если есть)
            if (news['img'] != null && news['img'].isNotEmpty)
              Image.network(
                news['img'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 10),

            // Полный текст новости
            Text(
              news['text'] ?? 'Без описания',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),

            // Дата публикации
            Text(
              'Дата: ${news['date']?.split('T')[0] ?? 'Неизвестно'}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}