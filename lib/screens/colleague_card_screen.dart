import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/colleague_card_service.dart';
import 'dart:convert';

class ColleagueCardScreen extends StatelessWidget {
  final String colleagueGuid;
  const ColleagueCardScreen({Key? key, required this.colleagueGuid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Карточка коллеги'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchColleagueData(context), // Передаем контекст
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки данных'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Данные коллеги недоступны'));
          } else {
            final colleagueData = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: colleagueData['photo'] != null && colleagueData['photo'].isNotEmpty
                          ? MemoryImage(base64Decode(colleagueData['photo']))
                          : null,
                      child: colleagueData['photo'] == null || colleagueData['photo'].isEmpty
                          ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileField(label: 'ФИО', value: colleagueData['fullName']?.toString() ?? ''),
                  ProfileField(label: 'Пол', value: colleagueData['gender']?.toString() ?? ''),
                  ProfileField(label: 'Дата рождения', value: colleagueData['birthday']?.split('T')[0] ?? ''),
                  ProfileField(label: 'Email', value: colleagueData['email']?.toString() ?? ''),
                  ProfileField(label: 'Телефон', value: colleagueData['phone']?.toString() ?? ''),
                  const SizedBox(height: 20),
                  Text(
                    'Ссылки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (colleagueData['links'] != null && colleagueData['links'] is Map<String, dynamic>)
                    ...colleagueData['links'].entries.map((entry) {
                      return LinkItem(label: entry.key, url: entry.value, launchUrl: _launchUrl);
                    }).toList(),
                  Text(
                    'Места работы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    colleagueData['employment'].length,
                        (index) {
                      final job = colleagueData['employment'][index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${job['organization_name']} - ${job['department_name']} (${job['type']})',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            job['post'],
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchColleagueData(BuildContext context) async {
    try {
      final service = ColleagueCardService();
      return await service.getColleagueCard(guidCollegue: colleagueGuid, context: context); // Передаем контекст
    } catch (e) {
      print('Ошибка при загрузке данных коллеги: $e');
      return {};
    }
  }

  void _launchUrl(BuildContext context, String label, String url) async {
    if (url.isEmpty || url == label || url == '1') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нет доступной ссылки для $label')),
      );
      return;
    }
    Uri? uri;
    // Автоматическое определение типа ссылки и её коррекция
    if (label.toLowerCase() == 'vk' && !url.startsWith('https://vk.com/ ')) {
      uri = Uri.parse('https://vk.com/ ${url.replaceAll('@', '')}');
    } else if (label.toLowerCase() == 'telegram' && !url.startsWith('tg://')) {
      uri = Uri.parse('tg://resolve?domain=${url.replaceAll('@', '')}');
    } else if (label.toLowerCase() == 'whatsapp' && !url.startsWith('https://')) {
      uri = Uri.parse('https://wa.me/ ${url.replaceAll('+', '')}');
    } else if (url.startsWith('www.') || url.contains('.com') || url.contains('.ru')) {
      uri = Uri.parse('https://$url');
    } else {
      uri = Uri.tryParse(url);
    }
    if (uri != null) {
      if (label.toLowerCase() == 'vk') {
        // Попытка открыть ссылку в приложении ВКонтакте
        final vkAppUri = Uri.parse('vk://vk.com/${url.replaceAll('@', '')}');
        if (await canLaunchUrl(vkAppUri)) {
          await launchUrl(vkAppUri, mode: LaunchMode.externalApplication);
        } else {
          // Если приложение ВКонтакте не установлено, открываем ссылку в браузере
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось открыть ссылку')),
            );
          }
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const ProfileField({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class LinkItem extends StatelessWidget {
  final String label;
  final String url;
  final void Function(BuildContext, String, String) launchUrl;
  const LinkItem({Key? key, required this.label, required this.url, required this.launchUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => launchUrl(context, label, url),
            child: Text(
              url,
              style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}