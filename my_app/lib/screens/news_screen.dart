// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import '../services//news_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _fetchNewsFuture;
  List<Map<String, dynamic>>? _allNews; // Хранилище для всех новостей
  bool _isShowingAllNews = false; // Флаг для отображения всех новостей

  @override
  void initState() {
    super.initState();
    _fetchNewsFuture = _fetchNewsData();
  }

  // Метод для получения списка новостей
  Future<List<Map<String, dynamic>>> _fetchNewsData() async {
    try {
      final newsService = NewsService();
      final newsList = await newsService.getNews(limit: 50, offset: 0);
      if (newsList is! List) {
        throw Exception('Некорректный формат данных: новости не являются списком');
      }
      // Сортируем новости по дате в обратном порядке (самые свежие сверху)
      newsList.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      setState(() {
        _allNews = newsList; // Сохраняем все новости
      });
      return newsList;
    } catch (e) {
      print('Ошибка при загрузке новостей: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новости'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Нет новостей'));
          } else {
            final newsList = snapshot.data!;
            final visibleNews = _isShowingAllNews ? newsList : newsList.take(3).toList();
            return ListView.builder(
              itemCount: visibleNews.length + (_isShowingAllNews ? 0 : 1), // Добавляем кнопку "Показать все"
              itemBuilder: (context, index) {
                if (index < visibleNews.length) {
                  final news = visibleNews[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            news['title'] ?? 'Без заголовка',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (news['img'] != null && news['img'].isNotEmpty)
                          Image.network(
                            news['img'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            news['text']?.substring(0, news['text'].length > 100 ? 100 : news['text'].length) ??
                                'Без описания',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                          child: Text(
                            'Дата: ${news['date']?.split('T')[0] ?? 'Неизвестно'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewsDetailScreen(news: news),
                                  ),
                                );
                              },
                              child: Text('Читать далее', style: TextStyle(color: Colors.blue)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Кнопка "Показать все"
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isShowingAllNews = true; // Показываем все новости
                        });
                      },
                      child: Text('Показать все'),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}