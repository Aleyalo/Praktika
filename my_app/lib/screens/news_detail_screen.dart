// lib/screens/news_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({required this.news});

  // Функция для открытия ссылок
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новость'),
        backgroundColor: Colors.yellow,
      ),
      body: SingleChildScrollView(
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

            // Полный текст новости с поддержкой гиперссылок
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black), // Установите базовый цвет текста
                children: _parseHtml(news['text'] ?? ''),
              ),
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

  // Функция для парсинга HTML и создания TextSpan с гиперссылками
  List<TextSpan> _parseHtml(String html) {
    final spans = <TextSpan>[];
    final words = html.split(' ');

    for (final word in words) {
      if (word.startsWith('http://') || word.startsWith('https://')) {
        final tapGesture = TapGestureRecognizer()
          ..onTap = () => _launchUrl(word);

        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: tapGesture,
          ),
        );
      } else {
        spans.add(TextSpan(text: '$word ', style: TextStyle(color: Colors.black)));
      }
    }

    return spans;
  }
}